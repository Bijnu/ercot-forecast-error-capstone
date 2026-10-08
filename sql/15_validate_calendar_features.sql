SELECT
  COUNT(*) AS total_hours,
  COUNT(DISTINCT operating_hour) AS unique_hours,

  COUNTIF(
    hour_of_day IS NULL OR hour_of_day NOT BETWEEN 0 AND 23
    OR day_of_week IS NULL OR day_of_week NOT BETWEEN 1 AND 7
    OR month_of_year IS NULL OR month_of_year NOT BETWEEN 1 AND 12
    OR is_weekend IS NULL OR is_weekend NOT IN (0, 1)
  ) AS invalid_calendar_rows,

  COUNTIF(
    is_weekend IS DISTINCT FROM
      CASE WHEN day_of_week IN (1, 7) THEN 1 ELSE 0 END
  ) AS incorrect_weekend_flags,

  COUNTIF(forecast_demand IS NULL) AS missing_forecasts,
  COUNTIF(high_error IS NULL) AS unlabeled_hours

FROM `ercot-508403.ercot_capstone.ercot_calendar_features`;