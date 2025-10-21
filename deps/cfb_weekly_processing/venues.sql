USE cfb_load;

SET IDENTITY_INSERT cfb.dbo.venues ON;

MERGE INTO cfb.dbo.venues as t
USING cfb_load.dbo.venues as s
	on t.id = s.id
WHEN NOT MATCHED THEN
INSERT (id, name, city, state, zip, country_code, timezone, latitude, longitude, elevation, capacity, construction_year, grass, dome)
VALUES (s.id, s.name, s.city, s.state, s.zip, s.country_code, s.timezone, s.latitude, s.longitude, s.elevation, s.capacity, s.construction_year, s.grass, s.dome);

TRUNCATE TABLE cfb_load.dbo.venues;