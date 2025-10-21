USE cfb_load;

MERGE cfb.dbo.game_team_stats AS target
USING cfb_load.dbo.v_game_team_stats AS source
ON target.game_id = source.game_id AND target.team = source.team
WHEN MATCHED THEN
    UPDATE SET
        total_yards = source.total_yards,
        rushing_attempts = source.rushing_attempts,
        yards_per_rush_attempt = source.yards_per_rush_attempt,
        rushing_yards = source.rushing_yards,
        rushing_tds = source.rushing_tds,
        completions = source.completions,
        pass_attempts = source.pass_attempts,
        yards_per_pass = source.yards_per_pass,
        net_passing_yards = source.net_passing_yards,
        passing_tds = source.passing_tds,
        interceptions = source.interceptions,
        first_downs = source.first_downs,
        third_down_conversions = source.third_down_conversions,
        third_down_attempts = source.third_down_attempts,
        fourth_down_conversions = source.fourth_down_conversions,
        fourth_down_attempts = source.fourth_down_attempts,
        time_of_possession = source.time_of_possession,
        turnovers = source.turnovers,
        qb_hurries = source.qb_hurries,
        sacks = source.sacks,
        passes_deflected = source.passes_deflected,
        passes_intercepted = source.passes_intercepted,
        tackles_for_loss = source.tackles_for_loss,
        total_penalties = source.total_penalties,
        total_penalties_yards = source.total_penalties_yards
WHEN NOT MATCHED THEN
    INSERT (
        season,
        week,
        season_type,
        game_id,
        team,
        home_away,
        total_yards,
        rushing_attempts,
        yards_per_rush_attempt,
        rushing_yards,
        rushing_tds,
        completions,
        pass_attempts,
        yards_per_pass,
        net_passing_yards,
        passing_tds,
        interceptions,
        first_downs,
        third_down_conversions,
        third_down_attempts,
        fourth_down_conversions,
        fourth_down_attempts,
        time_of_possession,
        turnovers,
        qb_hurries,
        sacks,
        passes_deflected,
        passes_intercepted,
        tackles_for_loss,
        total_penalties,
        total_penalties_yards
    )
    VALUES (
        source.season,
        source.week,
        source.season_type,
        source.game_id,
        source.team,
        source.home_away,
        source.total_yards,
        source.rushing_attempts,
        source.yards_per_rush_attempt,
        source.rushing_yards,
        source.rushing_tds,
        source.completions,
        source.pass_attempts,
        source.yards_per_pass,
        source.net_passing_yards,
        source.passing_tds,
        source.interceptions,
        source.first_downs,
        source.third_down_conversions,
        source.third_down_attempts,
        source.fourth_down_conversions,
        source.fourth_down_attempts,
        source.time_of_possession,
        source.turnovers,
        source.qb_hurries,
        source.sacks,
        source.passes_deflected,
        source.passes_intercepted,
        source.tackles_for_loss,
        source.total_penalties,
        source.total_penalties_yards
    );

MERGE INTO cfb.dbo.game_team_stats_extra target
USING (
    SELECT DISTINCT gts.* 
    FROM cfb_load.dbo.game_team_stats gts
    LEFT JOIN cfb.dbo.team_stats_tracked tst on gts.category = tst.category
    WHERE tst.category IS NULL
) source ON
    target.game_id = source.game_id
    AND target.team_id = source.team_id
    AND target.category = source.category
WHEN MATCHED THEN UPDATE SET
    target.stat = source.stat,
    target.points = source.points
WHEN NOT MATCHED THEN
INSERT (game_id, team_id, team, conference, home_away, points, category, stat)
VALUES (source.game_id, source.team_id, source.team, source.conference, source.home_away, source.points, source.category, source.stat);


TRUNCATE TABLE cfb_load.dbo.game_team_stats;