CREATE TABLE `ercot-508403.ercot_capstone.ercot_errors`
AS
SELECT
  operating_hour,
  respondent,
  units,
  actual_demand,
  forecast_demand,
  is_complete_pair,
  actual_demand - forecast_demand AS signed_error,
  ABS(actual_demand - forecast_demand) AS absolute_error,
  100.0 * SAFE_DIVIDE(
    ABS(actual_demand - forecast_demand),
    actual_demand
  ) AS absolute_percentage_error
FROM `ercot-508403.ercot_capstone.ercot_hourly`;