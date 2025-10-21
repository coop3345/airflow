USE cfb_load;

MERGE INTO cfb.dbo.plays as t
USING cfb_load.dbo.plays as s
	on t.id = s.id
WHEN NOT MATCHED THEN
INSERT (id, Drive_Id, Game_Id, Drive_Number, Play_Number, Offense, Offense_Conference, Offense_Score, Defense, Home, Away, Defense_Conference, Defense_Score, Period, Clock_Minutes, Clock_Seconds, Offense_Timeouts, Defense_Timeouts, Yardline, Yards_To_Goal, Down, Distance, Yards_Gained, Scoring, Play_Type, Play_Text, Ppa)
VALUES (s.id, s.Drive_Id, s.Game_Id, s.Drive_Number, s.Play_Number, s.Offense, s.Offense_Conference, s.Offense_Score, s.Defense, s.Home, s.Away, s.Defense_Conference, s.Defense_Score, s.Period, s.Clock_Minutes, s.Clock_Seconds, s.Offense_Timeouts, s.Defense_Timeouts, s.Yardline, s.Yards_To_Goal, s.Down, s.Distance, s.Yards_Gained, s.Scoring, s.Play_Type, s.Play_Text, s.Ppa);

TRUNCATE TABLE cfb_load.dbo.plays;

