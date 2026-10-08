CREATE MODEL `ercot-508403.ercot_capstone.ercot_high_error_bt`
OPTIONS (
  MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER',
  INPUT_LABEL_COLS = ['high_error'],
  DATA_SPLIT_METHOD = 'NO_SPLIT',
  MAX_ITERATIONS = 50,
  MAX_TREE_DEPTH = 4,
  LEARN_RATE = 0.1,
  AUTO_CLASS_WEIGHTS = TRUE,
  EARLY_STOP = FALSE
) AS
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
WHERE data_period = 'DEVELOPMENT';