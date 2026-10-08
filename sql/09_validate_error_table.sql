SELECT
  COUNT(*) AS total_hours,
  COUNT(signed_error) AS calculated_errors,
  COUNTIF(signed_error IS NULL) AS missing_errors,
  COUNTIF(
    absolute_error < 0
    OR absolute_percentage_error < 0
  ) AS negative_absolute_errors,
  COUNTIF(
    is_complete_pair
    AND (
      signed_error IS NULL
      OR absolute_error IS NULL
      OR absolute_percentage_error IS NULL
    )
  ) AS complete_pairs_without_errors
FROM `ercot-508403.ercot_capstone.ercot_errors`;