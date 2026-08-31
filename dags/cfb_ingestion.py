"""CFB ingestion DAGs backed by the AIP-108 Go Task Bundle.

Each dag_id and stub task name must match the bundle registration in
cfb_api/cmd/airflow-bundle/main.go. Stub tasks run on queue "golang";
downstream SQL merges load tables into cfb.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.sdk import dag, task

default_args = {
    "owner": "airflow",
    "retries": 0,
    "retry_delay": timedelta(seconds=30),
}

SQL_DIR = "/opt/airflow/deps/cfb_weekly_processing"

WEEKLY_SQL_FILES = [
    "adv_game_stats.sql",
    "drives.sql",
    "fpi_ratings.sql",
    "game_player_stats.sql",
    "game_team_stats.sql",
    "game_weather.sql",
    "games.sql",
    "play_stats.sql",
    "plays.sql",
    "rankings.sql",
    "sp_ratings.sql",
    "srs_ratings.sql",
]

OFFSEASON_SQL_FILES = [
    "draft_picks.sql",
    "recruits.sql",
    "recruiting_teams.sql",
]

SEASON_SQL_FILES = [
    "calendar.sql",
    "coaches.sql",
    "player_usage.sql",
    "portal.sql",
    "rosters.sql",
    "talent.sql",
    "teams.sql",
]

ONE_OFFS_SQL_FILES = [
    "play_stat_types.sql",
    "play_types.sql",
    "venues.sql",
]

def _sql_tasks(sql_files: list[str], upstream):
    if not os.path.exists(SQL_DIR):
        return

    for sql_file in sql_files:
        sql_file_path = os.path.join(SQL_DIR, sql_file)
        if not os.path.isfile(sql_file_path):
            continue
        with open(sql_file_path, "r") as f:
            sql_content = f.read()

        sql_task = SQLExecuteQueryOperator(
            task_id=f"cfb_load_{sql_file.replace('.sql', '')}",
            sql=sql_content,
            conn_id="mssql_default",
        )
        upstream >> sql_task

## -----------------Weekly Data DAG-------------------------
@dag(
    dag_id="cfb_weekly_ingestion",
    description="Weekly college football ingestion via AIP-108 Go Task Bundle",
    start_date=datetime(2025, 10, 11),
    schedule="0 12 * * 1",
    catchup=False,
    default_args=default_args,
    tags=["cfb", "aip-108", "golang", "ingestion", "weekly"],
)
def cfb_weekly_ingestion():
    @task.stub(queue="golang")
    def FetchWeeklyTask():
        """Ingests weekly games, drives, player/team stats, weather, rankings, ratings, plays."""
        ...
    
    @task.stub(queue="golang")
    def FetchOffseasonTask():
        """Ingests draft picks and recruiting data. Pulled weekly for fresh recruiting data."""
        ...

    weekly_task = FetchWeeklyTask()
    _sql_tasks(WEEKLY_SQL_FILES, weekly_task)

    offseason_task = FetchOffseasonTask()
    _sql_tasks(OFFSEASON_SQL_FILES, offseason_task)

cfb_weekly_ingestion()

## -----------------Season Data DAG-------------------------
@dag(
    dag_id="cfb_season_ingestion",
    description="Seasonal CFB ingestion via AIP-108 Go Task Bundle. Run monthly",
    start_date=datetime(2026, 8, 1),
    schedule='0 12 1 2-9 *',
    catchup=False,
    default_args=default_args,
    tags=["cfb", "aip-108", "golang", "ingestion", "season"],
)
def cfb_season_ingestion():
    @task.stub(queue="golang")
    def FetchSeasonTask():
        """Ingests seasonal CFB data (calendar, coaches, portal, rosters, talent, teams, usage)."""
        ...

    season_task = FetchSeasonTask()
    _sql_tasks(SEASON_SQL_FILES, season_task)

cfb_season_ingestion()

## -----------------One-offs Data DAG-------------------------
@dag(
    dag_id="cfb_one_offs_ingestion",
    description="One-off CFB ingestion via AIP-108 Go Task Bundle. Run once before each season",
    start_date=datetime(2026, 8, 1),
    schedule='0 12 1 8 *',
    catchup=False,
    default_args=default_args,
    tags=["cfb", "aip-108", "golang", "ingestion", "one-offs"],
)
def cfb_one_offs_ingestion():
    @task.stub(queue="golang")
    def FetchOneOffsTask():
        """Ingests static metadata (play stat types, play types, venues)."""
        ...

    one_offs_task = FetchOneOffsTask()
    _sql_tasks(ONE_OFFS_SQL_FILES, one_offs_task)

cfb_one_offs_ingestion()