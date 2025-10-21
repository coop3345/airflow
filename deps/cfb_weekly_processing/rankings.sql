USE cfb_load;

MERGE INTO cfb.dbo.rankings as t
USING cfb_load.dbo.rankings as s
	on t.season = s.season and t.season_type = s.season_type and t.week = s.week and t.poll = s.poll and t.rank = s.rank
WHEN MATCHED THEN UPDATE SET
	t.team_id = s.team_id, 
	t.school = s.school, 
	t.conference = s.conference, 
	t.first_place_votes = s.first_place_votes, 
	t.points = s.points
WHEN NOT MATCHED THEN
INSERT (season, season_type, week, poll, rank, team_id, school, conference, first_place_votes, points)
VALUES (s.season, s.season_type, s.week, s.poll, s.rank, s.team_id, s.school, s.conference, s.first_place_votes, s.points);

TRUNCATE TABLE cfb_load.dbo.rankings;