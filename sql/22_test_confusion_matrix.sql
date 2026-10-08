SELECT *
FROM ML.CONFUSION_MATRIX(
  MODEL `ercot-508403.ercot_capstone.ercot_high_error_bt`,
  (
    SELECT *
    FROM `ercot-508403.ercot_capstone.ercot_modeling`
    WHERE data_period = 'TEST'
  ),
  STRUCT(0.5 AS threshold)
)
ORDER BY expected_label;