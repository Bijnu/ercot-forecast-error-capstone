SELECT
  operating_hour,
  actual_demand,
  forecast_demand,
  signed_error,
  absolute_error,
  absolute_percentage_error
FROM `ercot-508403.ercot_capstone.ercot_errors`
WHERE is_complete_pair = TRUE
ORDER BY operating_hour
LIMIT 10;