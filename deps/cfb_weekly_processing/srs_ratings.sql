USE cfb_load;

MERGE INTO cfb.dbo.srs_ratings as t
USING cfb_load.dbo.srs_ratings as s
	on t.year = s.year and t.week = s.week and t.team = s.team
WHEN NOT MATCHED THEN
INSERT (year, week, team, conference, division, rating, ranking)
VALUES (s.year, s.week, s.team, s.conference, s.division, s.rating, s.ranking);

TRUNCATE TABLE cfb_load.dbo.srs_ratings;