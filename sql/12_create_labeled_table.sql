CREATE TABLE `ercot-508403.ercot_capstone.ercot_labeled` AS
WITH development_threshold AS (
  SELECT
    PERCENTILE_CONT(
      absolute_percentage_error, 0.90
    ) OVER () AS high_error_threshold_pct
  FROM `ercot-508403.ercot_capstone.ercot_errors`
  WHERE operating_hour >= TIMESTAMP('2021-01-01 00:00:00+00')
    AND operating_hour < TIMESTAMP('2025-01-01 00:00:00+00')
    AND is_complete_pair = TRUE
    AND absolute_percentage_error IS NOT NULL
),
threshold AS (
  SELECT MAX(high_error_threshold_pct) AS high_error_threshold_pct
  FROM development_threshold
)
SELECT
  e.*,
  t.high_error_threshold_pct,
  CASE
    WHEN e.is_complete_pair = FALSE
      OR e.absolute_percentage_error IS NULL THEN NULL
    WHEN e.absolute_percentage_error > t.high_error_threshold_pct THEN 1
    ELSE 0
  END AS high_error
FROM `ercot-508403.ercot_capstone.ercot_errors` AS e
CROSS JOIN threshold AS t;