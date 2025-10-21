USE cfb_load;

MERGE INTO cfb.dbo.coaches as t
USING cfb_load.dbo.coaches as s
	on t.first_name = s.first_name and t.last_name = s.last_name and t.year = s.year and t.school = s.school
WHEN MATCHED THEN UPDATE SET
	t.hire_date = s.hire_date, 
	t.games = s.games, 
	t.wins = s.wins, 
	t.losses = s.losses, 
	t.ties = s.ties, 
	t.preseason_rank = s.preseason_rank, 
	t.postseason_rank = s.postseason_rank, 
	t.srs = s.srs, 
	t.sp_overall = s.sp_overall, 
	t.sp_offense = s.sp_offense, 
	t.sp_defense = s.sp_defense
WHEN NOT MATCHED THEN
INSERT (first_name, last_name, hire_date, school, year, games, wins, losses, ties, preseason_rank, postseason_rank, srs, sp_overall, sp_offense, sp_defense)
VALUES (s.first_name, s.last_name, s.hire_date, s.school, s.year, s.games, s.wins, s.losses, s.ties, s.preseason_rank, s.postseason_rank, s.srs, s.sp_overall, s.sp_offense, s.sp_defense);

TRUNCATE TABLE cfb_load.dbo.coaches;