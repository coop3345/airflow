USE cfb_load;

MERGE INTO cfb.dbo.recruits as t
USING cfb_load.dbo.recruits as s
	on t.year = s.year and t.Recruit_ID = s.Recruit_ID
WHEN MATCHED THEN UPDATE SET
	Athlete_ID = s.Athlete_ID, 
	Recruit_Type = s.Recruit_Type, 
	Year = s.Year, 
	Ranking = s.Ranking, 
	Name = s.Name, 
	School = s.School, 
	Committed_To = s.Committed_To, 
	Position = s.Position, 
	Height = s.Height, 
	Weight = s.Weight, 
	Stars = s.Stars, 
	Rating = s.Rating, 
	City = s.City, 
	State_Province = s.State_Province, 
	Country = s.Country
WHEN NOT MATCHED THEN
INSERT (Recruit_ID, Athlete_ID, Recruit_Type, Year, Ranking, Name, School, Committed_To, Position, Height, Weight, Stars, Rating, City, State_Province, Country)
VALUES (s.Recruit_ID, s.Athlete_ID, s.Recruit_Type, s.Year, s.Ranking, s.Name, s.School, s.Committed_To, s.Position, s.Height, s.Weight, s.Stars, s.Rating, s.City, s.State_Province, s.Country);

TRUNCATE TABLE cfb_load.dbo.recruits;