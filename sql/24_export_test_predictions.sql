SELECT
  operating_hour,
  high_error AS actual_high_error,
  predicted_high_error,
  (
    SELECT prob
    FROM UNNEST(predicted_high_error_probs)
    WHERE label = 1
  ) AS high_error_score
FROM ML.PREDICT(
  MODEL `ercot-508403.ercot_capstone.ercot_high_error_bt`,
  (
    SELECT *
    FROM `ercot-508403.ercot_capstone.ercot_modeling`
    WHERE data_period = 'TEST'
  ),
  STRUCT(0.5 AS threshold)
)
ORDER BY operating_hour;