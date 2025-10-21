USE cfb_load;

MERGE INTO cfb.dbo.talents as t
USING cfb_load.dbo.talents as s
	on t.year = s.year and t.team = s.team
WHEN MATCHED THEN UPDATE
SET t.talent = s.talent
WHEN NOT MATCHED THEN
INSERT (year, team, talent)
VALUES (s.year, s.team, s.talent);

TRUNCATE TABLE cfb_load.dbo.talents;