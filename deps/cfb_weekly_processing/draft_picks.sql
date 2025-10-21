USE cfb;

MERGE cfb.dbo.draft_picks AS target
USING cfb_load.dbo.draft_picks AS source
ON target.college_athlete_id = source.college_athlete_id AND target.nfl_athlete_id = source.nfl_athlete_id
WHEN MATCHED THEN
    UPDATE SET
        nfl_athlete_id = source.nfl_athlete_id,
        college_id = source.college_id,
        college_team = source.college_team,
        college_conference = source.college_conference,
        nfl_team_id = source.nfl_team_id,
        nfl_team = source.nfl_team,
        year = source.year,
        overall = source.overall,
        round = source.round,
        pick = source.pick,
        name = source.name,
        position = source.position,
        height = source.height,
        weight = source.weight,
        pre_draft_ranking = source.pre_draft_ranking,
        pre_draft_position_ranking = source.pre_draft_position_ranking,
        pre_draft_grade = source.pre_draft_grade
WHEN NOT MATCHED THEN
    INSERT (
        college_athlete_id,
        nfl_athlete_id,
        college_id,
        college_team,
        college_conference,
        nfl_team_id,
        nfl_team,
        year,
        overall,
        round,
        pick,
        name,
        position,
        height,
        weight,
        pre_draft_ranking,
        pre_draft_position_ranking,
        pre_draft_grade
    )
  VALUES (
        source.college_athlete_id,
        source.nfl_athlete_id,
        source.college_id,
        source.college_team,
        source.college_conference,
        source.nfl_team_id,
        source.nfl_team,
        source.year,
        source.overall,
        source.round,
        source.pick,
        source.name,
        source.position,
        source.height,
        source.weight,
        source.pre_draft_ranking,
        source.pre_draft_position_ranking,
        source.pre_draft_grade
    );


TRUNCATE TABLE cfb_load.dbo.draft_picks;