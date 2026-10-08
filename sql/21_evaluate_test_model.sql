SELECT *
FROM ML.EVALUATE(
  MODEL `ercot-508403.ercot_capstone.ercot_high_error_bt`,
  (
    SELECT
      forecast_demand,
      hour_of_day,
      day_of_week,
      month_of_year,
      is_weekend,
      ape_lag_48h,
      ape_lag_168h,
      ape_mean_7d_lag_48h,
      high_error
    FROM `ercot-508403.ercot_capstone.ercot_modeling`
    WHERE data_period = 'TEST'
  ),
  STRUCT(0.5 AS threshold)
);