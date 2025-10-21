USE cfb_load;

SET IDENTITY_INSERT cfb.dbo.game_weather ON;

MERGE INTO cfb.dbo.game_weather AS target
USING cfb_load.dbo.game_weather AS source
ON target.game_id = source.game_id
WHEN MATCHED THEN
    UPDATE SET
        season = source.season,
        week = source.week,
        season_type = source.season_type,
        start_time = source.start_time,
        game_indoors = source.game_indoors,
        home_team = source.home_team,
        home_conference = source.home_conference,
        away_team = source.away_team,
        away_conference = source.away_conference,
        venue_id = source.venue_id,
        venue = source.venue,
        temperature = source.temperature,
        dew_point = source.dew_point,
        humidity = source.humidity,
        precipitation = source.precipitation,
        snowfall = source.snowfall,
        wind_direction = source.wind_direction,
        wind_speed = source.wind_speed,
        pressure = source.pressure,
        weather_condition_code = source.weather_condition_code,
        weather_condition = source.weather_condition
WHEN NOT MATCHED THEN
    INSERT (
        game_id,
        season,
        week,
        season_type,
        start_time,
        game_indoors,
        home_team,
        home_conference,
        away_team,
        away_conference,
        venue_id,
        venue,
        temperature,
        dew_point,
        humidity,
        precipitation,
        snowfall,
        wind_direction,
        wind_speed,
        pressure,
        weather_condition_code,
        weather_condition
    )
    VALUES (
        source.game_id,
        source.season,
        source.week,
        source.season_type,
        source.start_time,
        source.game_indoors,
        source.home_team,
        source.home_conference,
        source.away_team,
        source.away_conference,
        source.venue_id,
        source.venue,
        source.temperature,
        source.dew_point,
        source.humidity,
        source.precipitation,
        source.snowfall,
        source.wind_direction,
        source.wind_speed,
        source.pressure,
        source.weather_condition_code,
        source.weather_condition
    );


TRUNCATE TABLE cfb_load.dbo.game_weather;