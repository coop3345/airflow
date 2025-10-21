--  Merge Offense stats
MERGE INTO cfb.dbo.game_player_offense target
USING cfb_load.dbo.v_load_game_offense_player source on
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.pass_yards = source.pass_yards, 
	target.pass_ypa = source.pass_ypa, 
	target.pass_tds = source.pass_tds, 
	target.ints = source.ints, 
	target.qbr = source.qbr,
	target.carries = source.carries,
	target.rush_yards = source.rush_yards,
	target.rush_ypc = source.rush_ypc,
	target.rush_tds = source.rush_tds,
	target.rush_long = source.rush_long,
	target.receptions = source.receptions,
	target.rec_yards = source.rec_yards,
	target.rec_ypc = source.rec_ypc,
	target.rec_tds = source.rec_tds,
	target.rec_long = source.rec_long
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, pass_completions, pass_attempts, pass_yards, pass_ypa, pass_tds, ints, qbr, carries, rush_yards, rush_ypc, rush_tds, rush_long, receptions, targets, rec_yards, rec_ypc, rec_tds, rec_long)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.pass_completions, source.pass_attempts, source.pass_yards, source.pass_ypa, source.pass_tds, source.ints, source.qbr, source.carries, source.rush_yards, source.rush_ypc, source.rush_tds, source.rush_long, source.receptions, source.targets, source.rec_yards, source.rec_ypc, source.rec_tds, source.rec_long);


-- Merge Offense string split stats
MERGE INTO cfb.dbo.game_player_offense target
USING cfb_load.dbo.v_load_game_offense_player_string_stats source on
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.pass_completions = source.pass_completions,
	target.pass_attempts = source.pass_attempts
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, pass_completions, pass_attempts)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.pass_completions, source.pass_attempts);


-- Merge Return Stats
MERGE INTO cfb.dbo.game_player_returns target
USING cfb_load.dbo.v_load_game_returns_player source on 
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.kick_return_avg = source.kick_return_avg,
	target.kick_return_long = source.kick_return_long,
	target.kick_returns = source.kick_returns,
	target.kick_return_td = source.kick_return_td,
	target.kick_return_yds = source.kick_return_yds,
	target.punt_return_avg = source.punt_return_avg,
	target.punt_return_long = source.punt_return_long,
	target.punt_returns = source.punt_returns,
	target.punt_return_td = source.punt_return_td,
	target.punt_return_yards = source.punt_return_yards
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, kick_return_avg, kick_return_long, kick_returns, kick_return_td, kick_return_yds, punt_return_avg, punt_return_long, punt_returns, punt_return_td, punt_return_yards)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.kick_return_avg, source.kick_return_long, source.kick_returns, source.kick_return_td, source.kick_return_yds, source.punt_return_avg, source.punt_return_long, source.punt_returns, source.punt_return_td, source.punt_return_yards);

 -- Merge Kick Stats
MERGE INTO cfb.dbo.game_player_kick target
USING cfb_load.dbo.v_load_game_kick_player source on 
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.fgs_good = source.fgs_good,
	target.fg_attempts = source.fg_attempts,
	target.fg_pct = source.fg_pct,
	target.fg_long = source.fg_long,
	target.xps_good = source.xps_good,
	target.xp_attempts = source.xp_attempts,
	target.xp_pct = source.xp_pct,
	target.kick_pts = source.kick_pts
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, fgs_good, fg_attempts, fg_pct, fg_long, xps_good, xp_attempts, xp_pct, kick_pts)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.fgs_good, source.fg_attempts, source.fg_pct, source.fg_long, source.xps_good, source.xp_attempts, source.xp_pct, source.kick_pts);

 -- Merge Punt Stats
MERGE INTO cfb.dbo.game_player_punts target
USING cfb_load.dbo.v_load_game_punt_player source on 
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.punts = source.punts,
	target.punt_yards = source.punt_yards,
	target.punt_avg = source.punt_avg,
	target.punts_in_20 = source.punts_in_20,
	target.punt_touchbacks = source.punt_touchbacks,
	target.punt_long = source.punt_long
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, punts, punt_yards, punt_avg, punts_in_20, punt_touchbacks, punt_long)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.punts, source.punt_yards, source.punt_avg, source.punts_in_20, source.punt_touchbacks, source.punt_long);

 -- Merge Defensive Stats
MERGE INTO cfb.dbo.game_player_defense target
USING cfb_load.dbo.v_load_game_defense_player source on 
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.solo_tackles = source.solo_tackles,
	target.total_tackles = source.total_tackles,
	target.tackles_for_loss = source.tackles_for_loss,
	target.sacks = source.sacks,
	target.qb_hurries = source.qb_hurries,
	target.pass_breakups = source.pass_breakups,
	target.ints = source.ints,
	target.int_yards = source.int_yards,
	target.int_tds = source.int_tds,
	target.tds = source.tds
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, solo_tackles, total_tackles, tackles_for_loss, sacks, qb_hurries, pass_breakups, ints, int_yards, int_tds, tds)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.solo_tackles, source.total_tackles, source.tackles_for_loss, source.sacks, source.qb_hurries, source.pass_breakups, source.ints, source.int_yards, source.int_tds, source.tds);

-- Merge fumbles stats
MERGE INTO cfb.dbo.game_player_fumbles target
USING cfb_load.dbo.v_load_game_fumbles_player source on
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN MATCHED THEN UPDATE SET
	target.fumbles = source.fumbles,
	target.lost = source.lost,
	target.recovered = source.recovered
WHEN NOT MATCHED THEN
INSERT (game_id, team, athlete_id, athlete_name, fumbles,lost,recovered)
VALUES (source.game_id, source.team, source.athlete_id, source.athlete_name, source.fumbles, source.lost, source.recovered);

-- Merge extra categories and stat types not yet accounted for
MERGE INTO cfb.dbo.game_player_stats_extra  target
USING cfb_load.dbo.v_game_player_stats_extra source on
	target.game_id = source.game_id and
	target.team = source.team and
	target.athlete_id = source.athlete_id 
WHEN NOT MATCHED THEN
INSERT (game_id, team, conference, home_away, points, category, stat_type, athlete_id, athlete_name, stat)
VALUES (source.game_id,  source.team,  source.conference,  source.home_away,  source.points,  source.category,  source.stat_type,  source.athlete_id,  source.athlete_name,  source.stat);

TRUNCATE TABLE cfb_load.dbo.game_player_stats;