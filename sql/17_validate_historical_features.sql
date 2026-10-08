WITH checks AS (
  SELECT
    f.*,
    e48.absolute_percentage_error AS expected_48h,
    e168.absolute_percentage_error AS expected_168h
  FROM `ercot-508403.ercot_capstone.ercot_features` AS f

  LEFT JOIN `ercot-508403.ercot_capstone.ercot_errors` AS e48
    ON e48.operating_hour =
       TIMESTAMP_SUB(f.operating_hour, INTERVAL 48 HOUR)

  LEFT JOIN `ercot-508403.ercot_capstone.ercot_errors` AS e168
    ON e168.operating_hour =
       TIMESTAMP_SUB(f.operating_hour, INTERVAL 168 HOUR)
),
summary AS (
  SELECT
    COUNT(*) AS total_hours,
    COUNT(DISTINCT operating_hour) AS unique_hours,

    COUNTIF(ape_lag_48h IS NULL) AS missing_lag_48h,
    COUNTIF(ape_lag_168h IS NULL) AS missing_lag_168h,
    COUNTIF(ape_mean_7d_lag_48h IS NULL) AS missing_rolling_mean,

    COUNTIF(
      ape_lag_48h IS DISTINCT FROM expected_48h
      OR ape_lag_168h IS DISTINCT FROM expected_168h
    ) AS incorrect_lag_rows,

    COUNTIF(
      historical_valid_hours IS NULL
      OR historical_valid_hours NOT BETWEEN 0 AND 168
      OR (
        historical_valid_hours = 168
        AND ape_mean_7d_lag_48h IS NULL
      )
      OR (
        historical_valid_hours < 168
        AND ape_mean_7d_lag_48h IS NOT NULL
      )
    ) AS invalid_rolling_rows

  FROM checks
)
SELECT metric, result
FROM summary
UNPIVOT (
  result FOR metric IN (
    total_hours,
    unique_hours,
    missing_lag_48h,
    missing_lag_168h,
    missing_rolling_mean,
    incorrect_lag_rows,
    invalid_rolling_rows
  )
);