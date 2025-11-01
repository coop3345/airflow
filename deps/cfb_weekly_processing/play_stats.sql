USE cfb;

GO

MERGE INTO cfb.dbo.play_stats_raw target
USING (SELECT DISTINCT * FROM cfb_load.dbo.play_stats) source
on target.game_id = source.game_id and target.play_id = source.play_id
	and target.athlete_id = source.athlete_id and target.stat_type = source.stat_type
WHEN NOT MATCHED THEN
INSERT (game_id, season, week, team, conference, opponent, team_score, opponent_score, drive_id, play_id, period, clock_minutes, clock_seconds, yards_to_goal, down, distance, athlete_id, athlete_name, stat_type, stat)
VALUES (source.game_id, source.season, source.week, source.team, source.conference, source.opponent, source.team_score, source.opponent_score, source.drive_id, source.play_id, source.period, source.clock_minutes, source.clock_seconds, source.yards_to_goal, source.down, source.distance, source.athlete_id, source.athlete_name, source.stat_type, source.stat);

GO

DECLARE @s int, @w int;
SELECT @s = season , @w = week FROM cfb.dbo.calendar
WHERE DATEADD(DAY, -7, CURRENT_TIMESTAMP) BETWEEN start_date AND end_date;

MERGE INTO cfb.dbo.play_stats target
USING cfb.dbo.tf_play_stats(@s, @w) source
 on
 target.season = source.season and
 target.week = source.week and
 target.game_id = source.game_id and
 target.play_id = source.play_id and
 target.team = source.team and
 target.athlete_id = source.athlete_id
WHEN MATCHED THEN UPDATE SET
	target.opponent = source.opponent,
	target.team_score = source.team_score,
	target.opponent_score = source.opponent_score,
	target.drive_id = source.drive_id,
	target.period = source.period,
	target.clock_minutes = source.clock_minutes,
	target.clock_seconds = source.clock_seconds,
	target.down = source.down,
	target.distance = source.distance,
	target.yards_to_goal = source.yards_to_goal,
	target.athlete_name = source.athlete_name,
	target.critical_play = source.critical_play,
	target.Targets = source.Targets,
	target.Receptions = source.Receptions,
	target.Rushes = source.Rushes,
	target.RushYards = source.RushYards,
	target.SackYards = source.SackYards,
	target.SacksTaken = source.SacksTaken,
	target.RecYards = source.RecYards,
	target.Touchdowns = source.Touchdowns,
	target.PassYards = source.PassYards,
	target.Passes = source.Passes,
	target.Completions = source.Completions,
	target.Fumbles = source.Fumbles,
	target.IntThrown = source.IntThrown,
	target.ForcedFumbles = source.ForcedFumbles,
	target.FumblesRecovered = source.FumblesRecovered,
	target.Interceptions = source.Interceptions,
	target.PassBreakups = source.PassBreakups,
	target.QBHurries = source.QBHurries,
	target.Sacks = source.Sacks,
	target.BlockedFieldGoal = source.BlockedFieldGoal,
	target.FieldGoalBlocked = source.FieldGoalBlocked,
	target.FieldGoalAttemptDistance = source.FieldGoalAttemptDistance,
	target.FieldGoalMadeDistance = source.FieldGoalMadeDistance,
	target.FieldGoalMissed = source.FieldGoalMissed,
	target.FieldGoalAttempts = source.FieldGoalAttempts,
	target.FieldGoalMade = source.FieldGoalMade
WHEN NOT MATCHED THEN 
INSERT (game_id, season, week, team, opponent, team_score, opponent_score, drive_id, play_id, period, clock_minutes, clock_seconds, down, distance, yards_to_goal, athlete_id, athlete_name, critical_play, Targets, Receptions, Rushes, RushYards, SackYards, SacksTaken, RecYards, Touchdowns, PassYards, Passes, Completions, Fumbles, IntThrown, ForcedFumbles, FumblesRecovered, Interceptions, PassBreakups, QBHurries, Sacks, BlockedFieldGoal, FieldGoalBlocked, FieldGoalAttemptDistance, FieldGoalMadeDistance, FieldGoalMissed, FieldGoalAttempts, FieldGoalMade)
VALUES (source.game_id, source.season, source.week, source.team, source.opponent, source.team_score, source.opponent_score, source.drive_id, source.play_id, source.period, source.clock_minutes, source.clock_seconds, source.down, source.distance, source.yards_to_goal, source.athlete_id, source.athlete_name, source.critical_play, source.Targets, source.Receptions, source.Rushes, source.RushYards, source.SackYards, source.SacksTaken, source.RecYards, source.Touchdowns, source.PassYards, source.Passes, source.Completions, source.Fumbles, source.IntThrown, source.ForcedFumbles, source.FumblesRecovered, source.Interceptions, source.PassBreakups, source.QBHurries, source.Sacks, source.BlockedFieldGoal, source.FieldGoalBlocked, source.FieldGoalAttemptDistance, source.FieldGoalMadeDistance, source.FieldGoalMissed, source.FieldGoalAttempts, source.FieldGoalMade);

GO

TRUNCATE cfb_load.dbo.play_stats;