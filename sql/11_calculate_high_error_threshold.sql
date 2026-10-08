WITH development_errors AS (
  SELECT absolute_percentage_error
  FROM `ercot-508403.ercot_capstone.ercot_errors`
  WHERE operating_hour >= TIMESTAMP('2021-01-01 00:00:00+00')
    AND operating_hour < TIMESTAMP('2025-01-01 00:00:00+00')
    AND is_complete_pair = TRUE
    AND absolute_percentage_error IS NOT NULL
),
threshold_calculation AS (
  SELECT
    absolute_percentage_error,
    PERCENTILE_CONT(
      absolute_percentage_error, 0.90
    ) OVER () AS high_error_threshold_pct
  FROM development_errors
)
SELECT
  COUNT(*) AS development_hours,
  MAX(high_error_threshold_pct) AS high_error_threshold_pct,
  COUNTIF(
    absolute_percentage_error > high_error_threshold_pct
  ) AS high_error_hours
FROM threshold_calculation;