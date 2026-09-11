USE cfb_load;

WITH base as (
	SELECT *
		, ROW_NUMBER() OVER (PARTITION BY season, first_name, last_name, origin ORDER BY transfer_date DESC) as rn
	FROM cfb_load.dbo.portal
)

MERGE INTO cfb.dbo.portal as t
USING (
	SELECT * FROM base
	WHERE rn = 1
) as s
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