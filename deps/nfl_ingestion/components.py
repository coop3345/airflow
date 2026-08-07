"""Registry of NFL data components ingested into the `staging` schema.

Each `ComponentSpec` mirrors one entry of the `data` dict in `full_refresh.py`,
but its `loader` is parameterized by `seasons` instead of hardcoding `True`
(full history). The incremental Airflow DAG calls `loader(current_season)`;
`full_refresh.py` calls `loader(True)` for a full historical backfill.

`season_scoped=True` means the underlying `nflreadpy`/`nfl_data_py` function
accepts a `seasons`/`years` argument, so the ingestion service can merge just
that season's slice into an existing full-history staging table.
`season_scoped=False` means the source has no season parameter (it's a
reference/dimension snapshot), so the whole staging table is truncated and
reloaded every run.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

import nfl_data_py as nfl
import nflreadpy as nflpy
import pandas as pd


def _pl_to_pd(df) -> pd.DataFrame:
    """Convert a polars DataFrame (nflreadpy) to pandas; pass pandas through."""
    return df.to_pandas() if hasattr(df, "to_pandas") else df


@dataclass(frozen=True)
class ComponentSpec:
    name: str
    table_name: str
    loader: Callable[[int | bool], pd.DataFrame]
    season_scoped: bool


COMPONENTS: list[ComponentSpec] = [
    # --- play-by-play -------------------------------------------------
    ComponentSpec("pbp", "pbp", lambda seasons: _pl_to_pd(nflpy.load_pbp(seasons)), True),
    # --- player stats ---------------------------------------------------
    ComponentSpec(
        "weekly_data", "weekly_data",
        lambda seasons: _pl_to_pd(nflpy.load_player_stats(seasons, "week")), True,
    ),
    ComponentSpec(
        "seasonal_data", "seasonal_data",
        lambda seasons: _pl_to_pd(nflpy.load_player_stats(seasons, "reg")), True,
    ),
    ComponentSpec(
        "playoff_data", "playoff_data",
        lambda seasons: _pl_to_pd(nflpy.load_player_stats(seasons, "post")), True,
    ),
    # --- rosters / personnel --------------------------------------------
    ComponentSpec("season_rosters", "season_rosters", lambda seasons: _pl_to_pd(nflpy.load_rosters(seasons)), True),
    ComponentSpec(
        "weekly_rosters", "weekly_rosters",
        lambda seasons: _pl_to_pd(nflpy.load_rosters_weekly(seasons)), True,
    ),
    ComponentSpec("players", "players", lambda seasons: _pl_to_pd(nflpy.load_players()), False),
    ComponentSpec("depth_charts", "depth_charts", lambda seasons: _pl_to_pd(nflpy.load_depth_charts(seasons)), True),
    ComponentSpec("ids", "ids", lambda seasons: nfl.import_ids(), False),
    # --- schedules / officials ------------------------------------------
    ComponentSpec("schedules", "schedules", lambda seasons: _pl_to_pd(nflpy.load_schedules(seasons)), True),
    ComponentSpec("officials", "officials", lambda seasons: _pl_to_pd(nflpy.load_officials(seasons)), True),
    # --- draft ------------------------------------------------------------
    ComponentSpec("draft_picks", "draft_picks", lambda seasons: _pl_to_pd(nflpy.load_draft_picks(seasons)), True),
    ComponentSpec("draft_values", "draft_values", lambda seasons: nfl.import_draft_values(), False),
    ComponentSpec("combine", "combine", lambda seasons: _pl_to_pd(nflpy.load_combine(seasons)), True),
    # --- injuries / participation ----------------------------------------
    ComponentSpec("injuries", "injuries", lambda seasons: _pl_to_pd(nflpy.load_injuries(seasons)), True),
    ComponentSpec(
        "participation", "participation",
        lambda seasons: _pl_to_pd(nflpy.load_participation(seasons)), True,
    ),
    # --- next gen stats -----------------------------------------------------
    ComponentSpec(
        "ngs_receiving", "ngs_receiving",
        lambda seasons: _pl_to_pd(nflpy.load_nextgen_stats(seasons, "receiving")), True,
    ),
    ComponentSpec(
        "ngs_rushing", "ngs_rushing",
        lambda seasons: _pl_to_pd(nflpy.load_nextgen_stats(seasons, "rushing")), True,
    ),
    ComponentSpec(
        "ngs_passing", "ngs_passing",
        lambda seasons: _pl_to_pd(nflpy.load_nextgen_stats(seasons, "passing")), True,
    ),
    # --- QBR (nfl_data_py, years must be a list) ----------------------------
    ComponentSpec(
        "qbr", "qbr",
        lambda seasons: nfl.import_qbr(_as_years(seasons), "nfl", "season"), True,
    ),
    ComponentSpec(
        "qbr_weekly", "qbr_weekly",
        lambda seasons: nfl.import_qbr(_as_years(seasons), "nfl", "weekly"), True,
    ),
    # --- PFR advanced stats --------------------------------------------------
    ComponentSpec(
        "pfr_advstats_pass", "pfr_advstats_pass",
        lambda seasons: _pl_to_pd(nflpy.load_pfr_advstats(seasons, "pass", "week")), True,
    ),
    ComponentSpec(
        "pfr_advstats_rush", "pfr_advstats_rush",
        lambda seasons: _pl_to_pd(nflpy.load_pfr_advstats(seasons, "rush", "week")), True,
    ),
    ComponentSpec(
        "pfr_advstats_rec", "pfr_advstats_rec",
        lambda seasons: _pl_to_pd(nflpy.load_pfr_advstats(seasons, "rec", "week")), True,
    ),
    ComponentSpec(
        "pfr_advstats_pass_season", "pfr_advstats_pass_season",
        lambda seasons: _pl_to_pd(nflpy.load_pfr_advstats(seasons, "pass", "season")), True,
    ),
    ComponentSpec(
        "pfr_advstats_rush_season", "pfr_advstats_rush_season",
        lambda seasons: _pl_to_pd(nflpy.load_pfr_advstats(seasons, "rush", "season")), True,
    ),
    ComponentSpec(
        "pfr_advstats_rec_season", "pfr_advstats_rec_season",
        lambda seasons: _pl_to_pd(nflpy.load_pfr_advstats(seasons, "rec", "season")), True,
    ),
    # --- snap counts / charting ------------------------------------------------
    ComponentSpec("snap_counts", "snap_counts", lambda seasons: _pl_to_pd(nflpy.load_snap_counts(seasons)), True),
    ComponentSpec(
        "ftn_charting", "ftn_charting",
        lambda seasons: _pl_to_pd(nflpy.load_ftn_charting(seasons)), True,
    ),
    # --- team reference -----------------------------------------------------
    ComponentSpec("team_desc", "team_desc", lambda seasons: nfl.import_team_desc(), False),
    # --- contracts / trades ---------------------------------------------------
    ComponentSpec("contracts", "contracts", lambda seasons: _pl_to_pd(nflpy.load_contracts()), False),
    ComponentSpec("trades", "trades", lambda seasons: _pl_to_pd(nflpy.load_trades()), False),
    # --- fantasy -------------------------------------------------------------
    ComponentSpec("ff_playerids", "ff_playerids", lambda seasons: _pl_to_pd(nflpy.load_ff_playerids()), False),
    ComponentSpec("ff_rankings", "ff_rankings", lambda seasons: _pl_to_pd(nflpy.load_ff_rankings("all")), False),
    ComponentSpec(
        "ff_opportunity_weekly", "ff_opportunity_weekly",
        lambda seasons: _pl_to_pd(nflpy.load_ff_opportunity(seasons, "weekly")), True,
    ),
    ComponentSpec(
        "ff_opportunity_pbp_pass", "ff_opportunity_pbp_pass",
        lambda seasons: _pl_to_pd(nflpy.load_ff_opportunity(seasons, "pbp_pass")), True,
    ),
    ComponentSpec(
        "ff_opportunity_pbp_rush", "ff_opportunity_pbp_rush",
        lambda seasons: _pl_to_pd(nflpy.load_ff_opportunity(seasons, "pbp_rush")), True,
    ),
]

COMPONENTS_BY_NAME: dict[str, ComponentSpec] = {c.name: c for c in COMPONENTS}


def _as_years(seasons: int | bool) -> list[int]:
    """Adapt the pbp/nflreadpy-style `seasons` arg to nfl_data_py's `years` list.

    `import_qbr` (nfl_data_py) only accepts a list of years, not the
    True/int/list union that nflreadpy loaders accept.
    """
    if seasons is True:
        current_season = nflpy.get_current_season()
        return list(range(2006, current_season + 1))  # ESPN QBR starts 2006
    if isinstance(seasons, int):
        return [seasons]
    return list(seasons)


# Domain groupings used to organize Airflow TaskGroups.
DOMAIN_GROUPS: dict[str, list[str]] = {
    "play_by_play": ["pbp"],
    "player_stats": ["weekly_data", "seasonal_data", "playoff_data"],
    "rosters_personnel": ["season_rosters", "weekly_rosters", "players", "depth_charts", "ids"],
    "schedule_officials": ["schedules", "officials"],
    "draft": ["draft_picks", "draft_values", "combine"],
    "injuries_participation": ["injuries", "participation"],
    "advanced_stats": [
        "ngs_receiving", "ngs_rushing", "ngs_passing",
        "pfr_advstats_pass", "pfr_advstats_rush", "pfr_advstats_rec",
        "pfr_advstats_pass_season", "pfr_advstats_rush_season", "pfr_advstats_rec_season",
        "snap_counts", "ftn_charting",
    ],
    "qbr": ["qbr", "qbr_weekly"],
    "team_reference": ["team_desc"],
    "contracts_trades": ["contracts", "trades"],
    "fantasy": [
        "ff_playerids", "ff_rankings",
        "ff_opportunity_weekly", "ff_opportunity_pbp_pass", "ff_opportunity_pbp_rush",
    ],
}
