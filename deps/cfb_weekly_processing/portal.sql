USE cfb_load;

MERGE INTO cfb.dbo.portal as t
USING cfb_load.dbo.portal as s
	on t.season = s.season and t.first_name = s.first_name and t.last_name = s.last_name and t.origin = s.origin
WHEN MATCHED THEN UPDATE SET
	t.position = s.position,
	t.destination = s.destination,
	t.transfer_date = s.transfer_date,
	t.rating = s.rating,
	t.stars = s.stars,
	t.eligibility = s.eligibility
WHEN NOT MATCHED THEN
INSERT (season, first_name, last_name, position, origin, destination, transfer_date, rating, stars, eligibility)
VALUES (s.season, s.first_name, s.last_name, s.position, s.origin, s.destination, s.transfer_date, s.rating, s.stars, s.eligibility);

TRUNCATE TABLE cfb_load.dbo.portal;