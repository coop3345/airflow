USE cfb_load;

SET IDENTITY_INSERT cfb.dbo.play_types ON;

MERGE INTO cfb.dbo.play_types as t
USING cfb_load.dbo.play_types as s
	on t.id = s.id
WHEN NOT MATCHED THEN
INSERT (id, text, abbreviation)
VALUES (s.id, s.text, s.abbreviation);

TRUNCATE TABLE cfb_load.dbo.play_types;