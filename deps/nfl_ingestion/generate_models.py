"""Dev-only codegen: (re)generates `ingestion/models.py` from live schemas.

nflverse source schemas drift over time (columns get added/removed upstream),
so rather than hand-maintaining ~37 wide declarative models, this script
fetches one real season of each `ComponentSpec` in the registry, inspects the
resulting DataFrame's dtypes, and emits a concrete, fully typed SQLAlchemy
declarative model per staging table into `ingestion/models.py`.

Run manually whenever a source schema changes:

    uv run python -m ingestion.generate_models

The output is committed as normal source code - it is NOT regenerated at
runtime by the ingestion service or the Airflow DAG.
"""

from __future__ import annotations

import datetime as dt
import keyword
import re

import nflreadpy as nflpy
import pandas as pd

from deps.nfl_ingestion.components import COMPONENTS

OUTPUT_PATH = "ingestion/models.py"

HEADER = '''"""SQLAlchemy declarative ORM models for the `staging` and `meta` schemas.

GENERATED FILE - do not hand-edit column definitions.
Regenerate with: uv run python -m ingestion.generate_models
"""

from __future__ import annotations

import datetime as dt
from typing import Optional

from sqlalchemy import BigInteger, Boolean, Date, DateTime, Float, Sequence, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


# DuckDB has no SERIAL/AUTO_INCREMENT type, so autoincrementing primary keys
# need an explicit Sequence (https://github.com/Mause/duckdb_engine#auto-incrementing-id-columns).
ingestion_run_id_seq = Sequence("ingestion_run_id_seq", schema="meta")


class IngestionRun(Base):
    """Audit log of every component load attempt (one row per Airflow task run)."""

    __tablename__ = "ingestion_runs"
    __table_args__ = {"schema": "meta"}

    id: Mapped[int] = mapped_column(
        BigInteger, ingestion_run_id_seq, server_default=ingestion_run_id_seq.next_value(), primary_key=True
    )
    component: Mapped[str] = mapped_column(String)
    table_name: Mapped[str] = mapped_column(String)
    season: Mapped[int] = mapped_column(BigInteger)
    week: Mapped[int] = mapped_column(BigInteger)
    status: Mapped[str] = mapped_column(String)
    row_count: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    started_at: Mapped[dt.datetime] = mapped_column(DateTime)
    finished_at: Mapped[Optional[dt.datetime]] = mapped_column(DateTime, nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(String, nullable=True)


# Every staging model below shares two synthetic columns so the ORM always has
# a working primary key regardless of whether the source data has a natural
# one: `_id` is a uuid4 assigned by the ingestion service at insert time, and
# `_loaded_at` records when that row was staged. Season-scoped models get a
# third synthetic column, `_season`, set to whatever season was requested for
# that load - some sources (e.g. depth_charts, participation) don't expose
# their own `season` column, so the delete-then-insert merge always filters on
# this synthetic column instead of guessing at a natural one.
'''


def _sanitize_attr(col: str) -> str:
    """Turn an arbitrary source column name into a safe Python attribute name."""
    attr = re.sub(r"\W", "_", col)
    if attr and attr[0].isdigit():
        attr = f"c_{attr}"
    if keyword.iskeyword(attr):
        attr = f"{attr}_"
    return attr or "_unnamed"


def _class_name(component_name: str) -> str:
    return "".join(part.capitalize() for part in component_name.split("_"))


def _sa_type_for(series: pd.Series) -> str:
    dtype = series.dtype
    kind = dtype.kind
    if kind in "iu":
        return "BigInteger"
    if kind == "f":
        return "Float"
    if kind == "b":
        return "Boolean"
    if kind == "M":
        return "DateTime"
    if kind == "O":
        sample = series.dropna()
        if not sample.empty:
            first = sample.iloc[0]
            if isinstance(first, dt.datetime):
                return "DateTime"
            if isinstance(first, dt.date):
                return "Date"
        return "String"
    return "String"


def _py_type_for(sa_type: str) -> str:
    return {
        "BigInteger": "int",
        "Float": "float",
        "Boolean": "bool",
        "DateTime": "dt.datetime",
        "Date": "dt.date",
        "String": "str",
    }[sa_type]


def _generate_model(component_name: str, table_name: str, df: pd.DataFrame, season_scoped: bool) -> str:
    class_name = _class_name(component_name)
    lines = [
        f'class {class_name}(Base):',
        f'    __tablename__ = "{table_name}"',
        f'    __table_args__ = {{"schema": "staging"}}',
        "",
        "    _id: Mapped[str] = mapped_column(String, primary_key=True)",
        "    _loaded_at: Mapped[dt.datetime] = mapped_column(DateTime)",
    ]
    if season_scoped:
        lines.append("    _season: Mapped[int] = mapped_column(BigInteger, index=True)")
    reserved = {"_id", "_loaded_at", "_season"} if season_scoped else {"_id", "_loaded_at"}
    seen_attrs = set()
    for col in df.columns:
        attr = _sanitize_attr(col)
        # avoid collisions between sanitized names and disambiguate duplicates
        base_attr = attr
        suffix = 1
        while attr in seen_attrs or attr in reserved:
            attr = f"{base_attr}_{suffix}"
            suffix += 1
        seen_attrs.add(attr)

        sa_type = _sa_type_for(df[col])
        py_type = _py_type_for(sa_type)
        col_arg = f'"{col}", ' if attr != col else ""
        lines.append(
            f"    {attr}: Mapped[Optional[{py_type}]] = mapped_column({col_arg}{sa_type}, nullable=True)"
        )
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    sample_season = nflpy.get_current_season()
    print(f"Sampling schemas using season={sample_season}")

    blocks = [HEADER]
    for spec in COMPONENTS:
        print(f"  fetching {spec.name} ...")
        df = None
        # Some sources (e.g. QBR) lag behind the current season - fall back to
        # a couple of prior seasons so schema sampling still succeeds.
        for season in (sample_season, sample_season - 1, sample_season - 2):
            try:
                candidate = spec.loader(season)
            except Exception as exc:  # noqa: BLE001
                print(f"    WARNING: failed to fetch {spec.name} for season={season} ({exc})")
                continue
            if candidate is not None and len(candidate) > 0 and len(candidate.columns) > 0:
                df = candidate
                break
            print(f"    {spec.name} returned no rows/columns for season={season}, trying earlier season")
        if df is None:
            print(f"    WARNING: giving up on {spec.name}; skipping")
            continue
        blocks.append(_generate_model(spec.name, spec.table_name, df, spec.season_scoped))

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n\n".join(blocks) + "\n")

    print(f"Wrote {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
