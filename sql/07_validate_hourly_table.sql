SELECT
  COUNT(*) AS total_hours,
  COUNT(DISTINCT operating_hour) AS unique_hours,
  COUNTIF(is_complete_pair) AS complete_pairs,
  COUNTIF(actual_demand IS NULL) AS missing_actual,
  COUNTIF(forecast_demand IS NULL) AS missing_forecast
FROM `ercot-508403.ercot_capstone.ercot_hourly`;