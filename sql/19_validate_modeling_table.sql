SELECT
  data_period,
  COUNT(*) AS total_hours,
  COUNT(DISTINCT operating_hour) AS unique_hours,
  MIN(operating_hour) AS first_hour,
  MAX(operating_hour) AS last_hour,
  COUNTIF(high_error = 0) AS normal_hours,
  COUNTIF(high_error = 1) AS high_error_hours,

  COUNTIF(
    high_error IS NULL OR high_error NOT IN (0, 1)
    OR forecast_demand IS NULL
    OR hour_of_day IS NULL
    OR day_of_week IS NULL
    OR month_of_year IS NULL
    OR is_weekend IS NULL
    OR ape_lag_48h IS NULL
    OR ape_lag_168h IS NULL
    OR ape_mean_7d_lag_48h IS NULL
  ) AS invalid_rows

FROM `ercot-508403.ercot_capstone.ercot_modeling`
GROUP BY data_period
ORDER BY data_period;