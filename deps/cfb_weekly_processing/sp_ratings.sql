USE cfb_load;

MERGE INTO cfb.dbo.sp_ratings as t
USING cfb_load.dbo.sp_ratings as s
	on t.year = s.year and t.week = s.week and t.team = s.team
WHEN NOT MATCHED THEN
INSERT (year, week, team, conference, rating, ranking, Second_Order_Wins, Sos, Offense_Pace, Offense_Run_Rate, Offense_Passing_Downs, Offense_Standard_Downs, Offense_Passing, Offense_Rushing, Offense_Explosiveness, Offense_Success, Offense_Rating, Offense_Ranking, Defense_Havoc_DB, Defense_Havoc_Front_Seven, Defense_Havoc_Total, Defense_Passing_Downs, Defense_Standard_Downs, Defense_Passing, Defense_Rushing, Defense_Explosiveness, Defense_Success, Defense_Rating, Defense_Ranking, Special_Teams_Rating)
VALUES (s.year, s.week, s.team, s.conference, s.rating, s.ranking, s.Second_Order_Wins, s.Sos, s.Offense_Pace, s.Offense_Run_Rate, s.Offense_Passing_Downs, s.Offense_Standard_Downs, s.Offense_Passing, s.Offense_Rushing, s.Offense_Explosiveness, s.Offense_Success, s.Offense_Rating, s.Offense_Ranking, s.Defense_Havoc_DB, s.Defense_Havoc_Front_Seven, s.Defense_Havoc_Total, s.Defense_Passing_Downs, s.Defense_Standard_Downs, s.Defense_Passing, s.Defense_Rushing, s.Defense_Explosiveness, s.Defense_Success, s.Defense_Rating, s.Defense_Ranking, s.Special_Teams_Rating);

TRUNCATE TABLE cfb_load.dbo.sp_ratings;