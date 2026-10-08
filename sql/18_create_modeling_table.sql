CREATE TABLE
  `ercot-508403.ercot_capstone.ercot_modeling` AS
SELECT
  operating_hour,
  forecast_demand,
  hour_of_day,
  day_of_week,
  month_of_year,
  is_weekend,
  ape_lag_48h,
  ape_lag_168h,
  ape_mean_7d_lag_48h,
  high_error,

  CASE
    WHEN operating_hour < TIMESTAMP('2025-01-01 00:00:00+00')
      THEN 'DEVELOPMENT'
    ELSE 'TEST'
  END AS data_period

FROM `ercot-508403.ercot_capstone.ercot_features`

WHERE operating_hour >= TIMESTAMP('2021-01-01 00:00:00+00')
  AND operating_hour < TIMESTAMP('2026-01-01 00:00:00+00')
  AND high_error IS NOT NULL
  AND forecast_demand IS NOT NULL
  AND hour_of_day IS NOT NULL
  AND day_of_week IS NOT NULL
  AND month_of_year IS NOT NULL
  AND is_weekend IS NOT NULL
  AND ape_lag_48h IS NOT NULL
  AND ape_lag_168h IS NOT NULL
  AND ape_mean_7d_lag_48h IS NOT NULL;