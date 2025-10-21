USE cfb_load;

MERGE INTO cfb.dbo.recruiting_teams as t
USING cfb_load.dbo.recruiting_teams as s
	on t.year = s.year and t.team = s.team
WHEN MATCHED THEN UPDATE SET
	rank = s.rank,
	points = s.points
WHEN NOT MATCHED THEN
INSERT (year, rank, team, points)
VALUES (s.year, s.rank, s.team, s.points);

TRUNCATE TABLE cfb_load.dbo.recruiting_teams;