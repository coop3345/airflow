USE cfb_load;

SET IDENTITY_INSERT cfb.dbo.play_stat_types ON;

MERGE INTO cfb.dbo.play_stat_types as t
USING cfb_load.dbo.play_stat_types as s
	on t.id = s.id
WHEN NOT MATCHED THEN
INSERT (id, name)
VALUES (s.id, s.name);

TRUNCATE TABLE cfb_load.dbo.play_stat_types;