"""Incremental current-season/week NFL data refresh into the DuckDB `staging` schema.

Resolves the current season/week once (via `nflreadpy`), then runs one task
per dataset - grouped into `TaskGroup`s by domain - that fetches that
season's data and merges it into `staging.<table>` via
`ingestion.service.load_component`. See `full_refresh.py` for the separate,
manually-run full-history backfill.

All load tasks share the `motherduck_writer` pool (1 slot), because DuckDB/
MotherDuck only allow a single writer connection at a time. Create the pool
once before enabling this DAG:

    airflow pools set motherduck_writer 1 "serialize DuckDB/MotherDuck writes"

This file assumes the repo root (containing the `ingestion` and `util`
packages) is importable - either because Airflow's DAG folder *is* the repo
root, or because the repo root is already on `PYTHONPATH`. The `sys.path`
shim below makes it importable either way.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import nflreadpy as nflpy
from airflow.providers.standard.operators.python import PythonOperator
from airflow.sdk import DAG, task
from airflow.utils.task_group import TaskGroup

from deps.nfl_ingestion.components import COMPONENTS_BY_NAME, DOMAIN_GROUPS
from deps.nfl_ingestion.service import ensure_tables, load_component

POOL_NAME = "motherduck_writer"

default_args = {
    "owner": "nfl-data",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


def _run_component(name: str, **context) -> None:
    run_context = context["ti"].xcom_pull(task_ids="prepare")
    run = load_component(COMPONENTS_BY_NAME[name], run_context["season"], run_context["week"])
    print(f"{name}: {run.status} ({run.row_count} rows)")


with DAG(
    dag_id="nfl_staging_refresh",
    description="Incremental current-season/week NFL data refresh into DuckDB staging schema",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["nfl", "staging", "ingestion"],
) as dag:

    @task(task_id="prepare")
    def prepare() -> dict:
        """Resolve season/week once per run and make sure staging tables exist."""
        ensure_tables()
        return {"season": nflpy.get_current_season(), "week": nflpy.get_current_week()}

    run_context = prepare()

    for group_name, component_names in DOMAIN_GROUPS.items():
        with TaskGroup(group_id=group_name):
            for name in component_names:
                component_task = PythonOperator(
                    task_id=name,
                    python_callable=_run_component,
                    op_kwargs={"name": name},
                    pool=POOL_NAME,
                )
                run_context >> component_task
