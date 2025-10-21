USE cfb_load;

MERGE INTO cfb.dbo.fpi_ratings as t
USING cfb_load.dbo.fpi_ratings as s
	on t.year = s.year and t.week = s.week and t.team = s.team
WHEN NOT MATCHED THEN
INSERT (year, week, team, conference, Fpi, Resume_Game_Control, Resume_Remaining_SOS, Resume_Strength_Of_Schedule, Resume_Average_Win_Probability, Resume_Fpi, Resume_Strength_Of_Record, Efficiencies_Special_Teams, Efficiencies_Defense, Efficiencies_Offense, Efficiencies_Overall)
VALUES (s.year, s.week, s.team, s.conference, s.Fpi, s.Resume_Game_Control, s.Resume_Remaining_SOS, s.Resume_Strength_Of_Schedule, s.Resume_Average_Win_Probability, s.Resume_Fpi, s.Resume_Strength_Of_Record, s.Efficiencies_Special_Teams, s.Efficiencies_Defense, s.Efficiencies_Offense, s.Efficiencies_Overall);

TRUNCATE TABLE cfb_load.dbo.fpi_ratings;