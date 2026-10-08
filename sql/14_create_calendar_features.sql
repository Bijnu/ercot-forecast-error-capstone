CREATE TABLE
  `ercot-508403.ercot_capstone.ercot_calendar_features` AS
SELECT
  operating_hour,
  forecast_demand,
  high_error,

  EXTRACT(
    HOUR FROM operating_hour AT TIME ZONE 'America/Chicago'
  ) AS hour_of_day,

  EXTRACT(
    DAYOFWEEK FROM operating_hour AT TIME ZONE 'America/Chicago'
  ) AS day_of_week,

  EXTRACT(
    MONTH FROM operating_hour AT TIME ZONE 'America/Chicago'
  ) AS month_of_year,

  CASE
    WHEN EXTRACT(
      DAYOFWEEK FROM operating_hour AT TIME ZONE 'America/Chicago'
    ) IN (1, 7) THEN 1
    ELSE 0
  END AS is_weekend

FROM `ercot-508403.ercot_capstone.ercot_labeled`;