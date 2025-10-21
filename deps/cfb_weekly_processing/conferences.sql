USE cfb_load;

SET IDENTITY_INSERT cfb.dbo.conferences ON;

MERGE INTO cfb.dbo.conferences as t
USING cfb_load.dbo.conferences as s
	on t.id = s.id
WHEN MATCHED THEN UPDATE SET
	t.name = s.name,
	t.short_name = s.short_name,
	t.abbreviation = s.abbreviation,
	t.classification = s.classification
WHEN NOT MATCHED THEN
INSERT (id, name, short_name, abbreviation, classification)
VALUES (s.id, s.name, s.short_name, s.abbreviation, s.classification);

TRUNCATE TABLE cfb_load.dbo.conferences;