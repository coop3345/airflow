USE cfb_load;

MERGE INTO cfb.dbo.calendar as t
USING cfb_load.dbo.calendar as s
	on t.season = s.season AND t.week = s.week AND t.season_type = s.season_type
WHEN MATCHED THEN UPDATE SET
	t.start_date = s.start_date, t.end_date = s.end_date
WHEN NOT MATCHED THEN
INSERT (season, week, season_type, start_date, end_date)
VALUES (s.season, s.week, s.season_type, s.start_date, s.end_date);

TRUNCATE TABLE cfb_load.dbo.calendar;