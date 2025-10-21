USE cfb_load;

MERGE INTO cfb.dbo.rosters as t
USING cfb_load.dbo.rosters as s
	on t.season = s.season and t.team = s.team and t.player_id = s.player_id
WHEN NOT MATCHED THEN
INSERT (Player_Id, First_Name, Last_Name, Team, Season, Height, Weight, Jersey, Position, Home_City, Home_State, Home_Country, Home_Latitude, Home_Longitude, Home_County_FIPS, Recruit_Ids)
VALUES (s.Player_Id, s.First_Name, s.Last_Name, s.Team, s.Season, s.Height, s.Weight, s.Jersey, s.Position, s.Home_City, s.Home_State, s.Home_Country, s.Home_Latitude, s.Home_Longitude, s.Home_County_FIPS, s.Recruit_Ids);

TRUNCATE TABLE cfb_load.dbo.rosters;