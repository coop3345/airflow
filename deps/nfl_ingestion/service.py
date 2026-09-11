"""Core load logic shared by the Airflow DAG and manual/CLI runs.

`load_component` fetches one dataset's current-season data, merges it into
its `staging` table (delete-then-insert on the `_season` slice for
season-scoped datasets, full truncate+reload otherwise), and records the
outcome as a row in `meta.ingestion_runs`.
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime
from uuid import uuid4

import nflreadpy as nflpy
import pandas as pd
from sqlalchemy import delete

import deps.nfl_ingestion.models as models
from deps.nfl_ingestion.components import COMPONENTS, COMPONENTS_BY_NAME, ComponentSpec
from deps.nfl_ingestion.models import Base, IngestionRun
from util.connect import ensure_schemas, get_engine, get_session

MODEL_BY_TABLE = {
    obj.__tablename__: obj
    for obj in vars(models).values()
    if isinstance(obj, type) and hasattr(obj, "__tablename__") and obj is not IngestionRun
}


def ensure_tables() -> None:
    """Create the staging/meta schemas and all ORM-mapped tables if missing."""
    ensure_schemas()
    Base.metadata.create_all(get_engine())


def _prepare_dataframe(df: pd.DataFrame, model, season: int, season_scoped: bool) -> pd.DataFrame:
    """Align a fetched DataFrame with a staging table's real columns.

    Drops any source columns the current model doesn't know about (schema
    drift since the model was last generated) and stamps every row with the
    synthetic `_id`/`_loaded_at`/`_season` bookkeeping columns.
    """
    table_columns = {c.name for c in model.__table__.columns}
    dropped = [c for c in df.columns if c not in table_columns]
    if dropped:
        print(
            f"  WARNING: dropping {len(dropped)} column(s) not present in "
            f"staging.{model.__tablename__} (schema drift?): {sorted(dropped)}"
        )
    known_columns = [c for c in df.columns if c in table_columns]
    df = df[known_columns].astype(object).where(df[known_columns].notna(), None)

    now = datetime.utcnow()
    extra_columns = {"_id": [str(uuid4()) for _ in range(len(df))], "_loaded_at": now}
    if season_scoped:
        extra_columns["_season"] = season
    return pd.concat([df, pd.DataFrame(extra_columns, index=df.index)], axis=1)


def _bulk_replace(model, df: pd.DataFrame, season_scoped: bool, season: int) -> None:
    """Delete the season slice (or full table) and bulk-load `df` in one transaction.

    Uses DuckDB's native pandas-registration + `INSERT ... SELECT` path instead
    of row-by-row parameter binding: for wide tables like `pbp` (hundreds of
    columns, tens of thousands of rows) a naive executemany insert can take
    many minutes, while this columnar path takes well under a second.
    """
    table = model.__table__
    qualified_name = f"{table.schema}.{table.name}"
    view_name = f"_load_{table.name}"

    with get_engine().begin() as conn:
        if season_scoped:
            conn.execute(delete(model).where(model._season == season))
        else:
            conn.execute(delete(model))

        if df.empty:
            return

        native = conn.connection.driver_connection
        native.register(view_name, df)
        try:
            columns = ", ".join(f'"{c}"' for c in df.columns)
            native.execute(f"INSERT INTO {qualified_name} ({columns}) SELECT {columns} FROM {view_name}")
        finally:
            native.unregister(view_name)


def load_component(spec: ComponentSpec, season: int, week: int) -> IngestionRun:
    """Fetch, merge, and audit-log a single component for the given season/week."""
    model = MODEL_BY_TABLE[spec.table_name]

    with get_session() as session:
        run = IngestionRun(
            component=spec.name,
            table_name=spec.table_name,
            season=season,
            week=week,
            status="running",
            started_at=datetime.utcnow(),
        )
        session.add(run)
        session.commit()
        run_id = run.id

    try:
        df = spec.loader(season)
        df = _prepare_dataframe(df, model, season, spec.season_scoped)
        _bulk_replace(model, df, spec.season_scoped, season)
        row_count = len(df)
    except Exception as exc:  # noqa: BLE001
        with get_session() as session:
            run = session.get(IngestionRun, run_id)
            run.status = "failed"
            run.error_message = str(exc)[:2000]
            run.finished_at = datetime.utcnow()
            session.commit()
        raise

    with get_session() as session:
        run = session.get(IngestionRun, run_id)
        run.status = "success"
        run.row_count = row_count
        run.finished_at = datetime.utcnow()
        session.commit()
        session.refresh(run)
        return run


def load_all(season: int, week: int, component_names: list[str] | None = None) -> list[str]:
    """Load every component (or a subset by name), returning names that failed."""
    names = component_names or [c.name for c in COMPONENTS]
    failures: list[str] = []
    for name in names:
        spec = COMPONENTS_BY_NAME[name]
        print(f"[{name}] loading season={season} week={week} ...")
        try:
            run = load_component(spec, season, week)
            print(f"[{name}] OK - {run.row_count} rows")
        except Exception as exc:  # noqa: BLE001
            print(f"[{name}] FAILED - {exc}")
            failures.append(name)
    return failures


def _cli() -> None:
    parser = argparse.ArgumentParser(description="Run the NFL staging ingestion service locally (no Airflow).")
    parser.add_argument("--component", action="append", dest="components", help="Component name to load (repeatable). Defaults to all.")
    parser.add_argument("--season", type=int, default=None, help="Season to load. Defaults to nflreadpy.get_current_season().")
    parser.add_argument("--week", type=int, default=None, help="Week to record in the audit log. Defaults to nflreadpy.get_current_week().")
    args = parser.parse_args()

    ensure_tables()

    season = args.season if args.season is not None else nflpy.get_current_season()
    week = args.week if args.week is not None else nflpy.get_current_week()
    print(f"season={season} week={week}")

    failures = load_all(season, week, args.components)
    if failures:
        print(f"\n{len(failures)} component(s) failed: {failures}")
        sys.exit(1)


if __name__ == "__main__":
    _cli()
