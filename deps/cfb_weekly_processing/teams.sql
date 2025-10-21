USE cfb_load;

SET IDENTITY_INSERT cfb.dbo.teams ON;

MERGE INTO cfb.dbo.teams as t
USING cfb_load.dbo.teams as s
	on t.id = s.id
WHEN NOT MATCHED THEN
INSERT (ID, School, Mascot, Abbreviation, Alternate_Names, Conference, Division, Classification, Color, Alternate_Color, Logos, Twitter, Location_ID, Location_Name, City, State, Zip, Country_Code, Timezone, Latitude, Longitude, Elevation, Capacity, Construction_Year, Grass, Dome)
VALUES (s.ID, s.School, s.Mascot, s.Abbreviation, s.Alternate_Names, s.Conference, s.Division, s.Classification, s.Color, s.Alternate_Color, s.Logos, s.Twitter, s.Location_ID, s.Location_Name, s.City, s.State, s.Zip, s.Country_Code, s.Timezone, s.Latitude, s.Longitude, s.Elevation, s.Capacity, s.Construction_Year, s.Grass, s.Dome);

TRUNCATE TABLE cfb_load.dbo.teams;