# ERCOT Forecast-Error Capstone

WGU Data Engineering Capstone investigating whether published demand forecasts, calendar characteristics, and historical forecast errors can identify high-error hours in ERCOT day-ahead demand forecasts.

## Data and tools

- Source: Public U.S. Energy Information Administration (EIA) Form EIA-930 data.
- Coverage: January 2021 through December 2025.
- Balancing authority: ERCO.
- Measurements: Actual demand (D) and day-ahead demand forecast (DF).
- Tools: Python, BigQuery SQL, BigQuery ML, and Matplotlib.
- Source records: 87,599.
- Complete hourly forecast/actual pairs: 43,775.
- Hours missing a complete pair: 49.

## Repository contents

- data/: Downloaded EIA-930 dataset.
- scripts/: Data download, forecast-error chart, and model-baseline comparison scripts.
- sql/: Numbered preparation, validation, training, and evaluation queries.
- results/: Predictions, summary metrics, bootstrap intervals, and chart.
- screenshots/: Implementation and validation evidence.
- Root CSV files: BigQuery model evaluation, confusion matrix, and baseline outputs.

The written assessment report is submitted separately.

## Execution order

1. Use the supplied data CSV, or run scripts/download_ercot_eia930.py with your own EIA API key supplied through the EIA_API_KEY environment variable.
2. Create a BigQuery dataset and upload the CSV as ercot_raw.
3. Update project and dataset identifiers in the SQL files for your environment.
4. Run SQL files 01 through 19 in numerical order to validate and prepare the data. Files 01 through 03 have .sql.txt extensions but contain SQL.
5. Run SQL file 20 to train the boosted-tree classifier, followed by files 21 through 24 for evaluation and prediction export.
6. Save exported predictions as results/test_predictions.csv.
7. From the repository root, run the local comparison and chart scripts:

    python scripts/compare_model_baseline.py --input results/test_predictions.csv --output-dir results
    python scripts/plot_forecast_errors.py --input data/ercot_eia930_2021_2025.csv --output-dir results

The download and comparison scripts use the Python standard library. The chart script requires Matplotlib. BigQuery execution requires appropriate permissions and may incur charges.

## Method

High-error hours were defined as absolute percentage errors above approximately 5.4114%, calculated from the development-period 90th percentile.

The classifier used eight predictors: forecast demand, four calendar features, two historical error lags, and a rolling historical error average.

- Development period: 2021-2024, with 34,680 modeling observations.
- Test period: 2025, with 8,497 modeling observations.
- Classification cutoff: 0.5.
- Baseline: Always predict a normal-error hour.

## Test results

| Metric | Boosted-tree model | Majority-class baseline |
|---|---:|---:|
| Accuracy | 64.12% | 90.61% |
| Balanced accuracy | 61.67% | 50.00% |
| Precision | 14.68% | Undefined: no positive predictions |
| Recall | 58.65% | 0.00% |
| F1 score | 0.2349 | 0.0000 |

Model confusion counts: 4,980 true negatives, 2,719 false positives, 330 false negatives, and 468 true positives.

An exploratory paired circular block bootstrap used 10,000 repetitions with seven-day blocks and sensitivity checks using 14-day and 28-day blocks. The seven-day 95% interval for the balanced-accuracy difference was 5.98 to 16.71 percentage points; the accuracy-difference interval was -33.37 to -20.09 percentage points.

## Interpretation and limitations

The model detected more high-error hours than the baseline but produced substantial false alarms and lower overall accuracy. These results do not justify automated operational decisions.

The analysis used a historical data snapshot. A 48-hour buffer for historical features did not establish their original publication or revision times. Complete-case filtering also excluded hours with missing labels or predictors.

The bootstrap comparison was selected after reviewing test results and is exploratory, not a confirmatory test of the original hypothesis.

## Data source

U.S. Energy Information Administration:
https://www.eia.gov/opendata/browser/electricity/rto
