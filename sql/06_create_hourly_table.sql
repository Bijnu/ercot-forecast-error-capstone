CREATE TABLE `ercot-508403.ercot_capstone.ercot_hourly`
AS
WITH expected_hours AS (
  SELECT operating_hour
  FROM UNNEST(GENERATE_TIMESTAMP_ARRAY(
    TIMESTAMP('2021-01-01 00:00:00 UTC'),
    TIMESTAMP('2025-12-31 23:00:00 UTC'),
    INTERVAL 1 HOUR
  )) AS operating_hour
),
paired AS (
  SELECT
    PARSE_TIMESTAMP('%Y-%m-%dT%H', period, 'UTC')
      AS operating_hour,
    MAX(IF(type = 'D', value, NULL)) AS actual_demand,
    MAX(IF(type = 'DF', value, NULL)) AS forecast_demand
  FROM `ercot-508403.ercot_capstone.ercot_raw`
  WHERE respondent = 'ERCO'
  GROUP BY operating_hour
)
SELECT
  operating_hour,
  'ERCO' AS respondent,
  'megawatthours' AS units,
  actual_demand,
  forecast_demand,
  actual_demand IS NOT NULL
    AND forecast_demand IS NOT NULL AS is_complete_pair
FROM expected_hours
LEFT JOIN paired USING (operating_hour);