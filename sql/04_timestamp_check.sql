WITH parsed AS (
  SELECT
    SAFE.PARSE_TIMESTAMP(
      '%Y-%m-%dT%H', period, 'UTC'
    ) AS operating_hour
  FROM `ercot-508403.ercot_capstone.ercot_raw`
)
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(operating_hour IS NULL) AS invalid_timestamps,
  MIN(operating_hour) AS first_hour,
  MAX(operating_hour) AS last_hour
FROM parsed;