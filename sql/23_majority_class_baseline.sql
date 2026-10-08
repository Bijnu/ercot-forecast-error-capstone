WITH majority_class AS (
  SELECT high_error AS predicted_label
  FROM `ercot-508403.ercot_capstone.ercot_modeling`
  WHERE data_period = 'DEVELOPMENT'
  GROUP BY high_error
  ORDER BY COUNT(*) DESC, high_error
  LIMIT 1
),
counts AS (
  SELECT
    COUNT(*) AS test_rows,
    COUNTIF(high_error = 1 AND predicted_label = 1) AS tp,
    COUNTIF(high_error = 0 AND predicted_label = 1) AS fp,
    COUNTIF(high_error = 0 AND predicted_label = 0) AS tn,
    COUNTIF(high_error = 1 AND predicted_label = 0) AS fn
  FROM `ercot-508403.ercot_capstone.ercot_modeling`
  CROSS JOIN majority_class
  WHERE data_period = 'TEST'
)
SELECT
  *,
  SAFE_DIVIDE(tp + tn, test_rows) AS accuracy,
  SAFE_DIVIDE(tp, tp + fp) AS precision,
  SAFE_DIVIDE(tp, tp + fn) AS recall,
  SAFE_DIVIDE(2 * tp, 2 * tp + fp + fn) AS f1_score
FROM counts;