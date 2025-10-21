USE cfb_load;

MERGE INTO cfb.dbo.player_usage as t
USING cfb_load.dbo.player_usages as s
	on t.season = s.season and t.player_id = s.player_id and t.team = s.team
WHEN MATCHED THEN UPDATE SET
	t.passing_downs = s.passing_downs, 
	t.third_down = s.third_down, 
	t.second_down = s.second_down, 
	t.first_down = s.first_down, 
	t.rush = s.rush, 
	t.pass = s.pass, 
	t.overall = s.overall
WHEN NOT MATCHED THEN
INSERT (season, player_id, name, position, team, conference, passing_downs, third_down, second_down, first_down, rush, pass, overall)
VALUES (s.season, s.player_id, s.name, s.position, s.team, s.conference, s.passing_downs, s.third_down, s.second_down, s.first_down, s.rush, s.pass, s.overall);

TRUNCATE TABLE cfb_load.dbo.player_usages;