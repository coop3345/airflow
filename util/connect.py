import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

load_dotenv()

# duckdb:///md:NFL -> MotherDuck-hosted database named NFL, via the duckdb-engine
# SQLAlchemy dialect. Point DUCKDB_DATABASE at a local file path instead (e.g.
# "nfl.duckdb") to develop against a local DuckDB file with no MotherDuck token.
DUCKDB_DATABASE = os.getenv("DUCKDB_DATABASE", "md:NFL")
MOTHERDUCK_TOKEN = os.getenv("MOTHERDUCK_TOKEN")

STAGING_SCHEMA = "staging"
META_SCHEMA = "meta"

_engine: Engine | None = None
SessionLocal: sessionmaker | None = None


def get_engine() -> Engine:
    """Create (once) and return the SQLAlchemy engine for the DuckDB/MotherDuck database."""
    global _engine
    if _engine is None:
        connect_args = {}
        if MOTHERDUCK_TOKEN:
            connect_args["config"] = {"motherduck_token": MOTHERDUCK_TOKEN}
        _engine = create_engine(f"duckdb:///{DUCKDB_DATABASE}", connect_args=connect_args)
    return _engine


def get_session() -> Session:
    """Return a new SQLAlchemy ORM session bound to the DuckDB/MotherDuck engine."""
    global SessionLocal
    if SessionLocal is None:
        SessionLocal = sessionmaker(bind=get_engine(), expire_on_commit=False)
    return SessionLocal()


def ensure_schemas() -> None:
    """Create the staging/meta schemas if they don't already exist."""
    with get_engine().begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {STAGING_SCHEMA}"))
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {META_SCHEMA}"))


# Backwards-compatible module-level handle used by notebooks/scripts that just
# want a ready-to-query engine, e.g. `from util.connect import engine`.
engine = get_engine()
