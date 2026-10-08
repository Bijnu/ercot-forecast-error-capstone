WITH label_check AS (
  SELECT
    *,
    CASE
      WHEN is_complete_pair IS NOT TRUE
        OR absolute_percentage_error IS NULL THEN NULL
      WHEN absolute_percentage_error > high_error_threshold_pct THEN 1
      ELSE 0
    END AS expected_label
  FROM `ercot-508403.ercot_capstone.ercot_labeled`
)
SELECT
  COUNT(*) AS total_hours,
  COUNT(DISTINCT operating_hour) AS unique_hours,
  COUNT(high_error) AS labeled_hours,
  COUNTIF(high_error IS NULL) AS unlabeled_hours,
  COUNT(DISTINCT high_error_threshold_pct) AS distinct_thresholds,
  COUNTIF(high_error_threshold_pct IS NULL) AS missing_thresholds,
  COUNTIF(
    high_error IS DISTINCT FROM expected_label
  ) AS incorrect_labels
FROM label_check;