CREATE TABLE
  `ercot-508403.ercot_capstone.ercot_features` AS
WITH historical_features AS (
  SELECT
    operating_hour,

    LAG(absolute_percentage_error, 48) OVER (
      ORDER BY operating_hour
    ) AS ape_lag_48h,

    LAG(absolute_percentage_error, 168) OVER (
      ORDER BY operating_hour
    ) AS ape_lag_168h,

    AVG(absolute_percentage_error) OVER (
      ORDER BY operating_hour
      ROWS BETWEEN 215 PRECEDING AND 48 PRECEDING
    ) AS historical_mean,

    COUNT(absolute_percentage_error) OVER (
      ORDER BY operating_hour
      ROWS BETWEEN 215 PRECEDING AND 48 PRECEDING
    ) AS historical_valid_hours

  FROM `ercot-508403.ercot_capstone.ercot_errors`
)
SELECT
  c.*,
  h.ape_lag_48h,
  h.ape_lag_168h,

  CASE
    WHEN h.historical_valid_hours = 168
      THEN h.historical_mean
    ELSE NULL
  END AS ape_mean_7d_lag_48h,

  h.historical_valid_hours

FROM
  `ercot-508403.ercot_capstone.ercot_calendar_features` AS c
LEFT JOIN historical_features AS h
  ON c.operating_hour = h.operating_hour;