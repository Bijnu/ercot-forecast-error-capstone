"""Plot monthly ERCOT forecast errors from complete raw hourly pairs.
Run from the capstone folder. Requires matplotlib; no cloud requests.
"""
import argparse
import calendar
import csv
import math
from collections import defaultdict
from datetime import datetime
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=Path('data/ercot_eia930_2021_2025.csv'))
    parser.add_argument('--output-dir', type=Path, default=Path('results'))
    args = parser.parse_args()
    pairs = defaultdict(dict)
    with args.input.open(newline='', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            if row['respondent'] != 'ERCO' or row['type'] not in ('D','DF'):
                raise ValueError('Expected ERCO demand and forecast records only.')
            hour = datetime.strptime(row['period'], '%Y-%m-%dT%H')
            if not 2021 <= hour.year <= 2025:
                raise ValueError('Expected dates in 2021 through 2025.')
            if row['value-units'] != 'megawatthours':
                raise ValueError('Unexpected measurement units.')
            if row['type'] in pairs[hour]:
                raise ValueError('Duplicate hourly measurement.')
            value = float(row['value'])
            if not math.isfinite(value) or value <= 0:
                raise ValueError('Demand and forecast must be finite and positive.')
            pairs[hour][row['type']] = value
    grouped = defaultdict(list)
    for hour, values in pairs.items():
        if 'D' in values and 'DF' in values:
            grouped[(hour.year,hour.month)].append(100*abs(values['D']-values['DF'])/values['D'])
    records=[]
    for year in range(2021,2026):
        for month in range(1,13):
            values=grouped[(year,month)]
            expected=24*calendar.monthrange(year,month)[1]
            records.append({'month_utc':f'{year}-{month:02d}',
                            'expected_hours':expected,'complete_pairs':len(values),
                            'excluded_hours':expected-len(values),
                            'mean_absolute_percentage_error':sum(values)/len(values) if values else None})
    args.output_dir.mkdir(parents=True,exist_ok=True)
    csv_path=args.output_dir/'monthly_forecast_errors.csv'
    with csv_path.open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=list(records[0]));writer.writeheader();writer.writerows(records)
    dates=[datetime.strptime(r['month_utc'],'%Y-%m') for r in records]
    values=[r['mean_absolute_percentage_error'] if r['mean_absolute_percentage_error'] is not None else float('nan') for r in records]
    fig,ax=plt.subplots(figsize=(11,5.5))
    ax.plot(dates,values,color='#176087',linewidth=1.8,marker='o',markersize=3)
    ax.axvline(datetime(2025,1,1),color='#666666',linestyle='--',linewidth=1)
    ax.text(datetime(2025,1,10),.97,'2025 test year',transform=ax.get_xaxis_transform(),va='top',fontsize=10)
    ax.set(title='ERCOT day-ahead demand forecast error by month',
           xlabel='Month (UTC)',ylabel='Mean hourly absolute percentage error (%)')
    ax.set_ylim(bottom=0)
    ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1,7]))
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %Y'))
    ax.tick_params(axis='x',rotation=35)
    ax.grid(axis='y',alpha=.25);ax.spines[['top','right']].set_visible(False)
    complete=sum(r['complete_pairs'] for r in records)
    missing=sum(r['excluded_hours'] for r in records)
    fig.text(.08,.025,f'Source: downloaded EIA-930 ERCO data. {complete:,} complete hourly pairs; {missing} hours excluded.\n'
             'Monthly mean of 100 × |actual − forecast| / actual. Includes all complete pairs before modeling filters.',fontsize=9)
    fig.tight_layout(rect=[0,.12,1,1])
    png_path=args.output_dir/'31_monthly_forecast_errors.png'
    fig.savefig(png_path,dpi=220,facecolor='white');plt.close(fig)
    print(f'Complete hourly pairs plotted: {complete:,}')
    print(f'Hours without a complete pair: {missing}')
    print(f'Months summarized: {len(records)}')
    print(f'Chart saved: {png_path.resolve()}')
    print(f'Chart data saved: {csv_path.resolve()}')
    print('Descriptive forecast-error chart; no model training or cloud usage.')


if __name__ == '__main__':
    main()
