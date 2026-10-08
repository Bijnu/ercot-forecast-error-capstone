"""Exploratory paired circular day-block bootstrap; Python standard library only."""
import argparse
import csv
import hashlib
import json
import random
from datetime import datetime, date, timedelta
from pathlib import Path


def metrics(c):
    tn, fp, fn, tp = c
    n = sum(c)
    return {'accuracy': (tn+tp)/n, 'balanced_accuracy': (tp/(tp+fn)+tn/(tn+fp))/2,
            'precision': tp/(tp+fp) if tp+fp else None,
            'recall': tp/(tp+fn), 'f1': 2*tp/(2*tp+fp+fn)}


def percentile(values, p):
    a = sorted(values)
    x = (len(a)-1)*p
    i = int(x)
    return a[i] + (a[min(i+1,len(a)-1)]-a[i])*(x-i)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument('--output-dir', type=Path, default=Path('results'))
    parser.add_argument('--replicates', type=int, default=10000)
    parser.add_argument('--seed', type=int, default=20261007)
    args = parser.parse_args()
    if args.replicates < 1000:
        raise ValueError('Use at least 1000 replicates.')
    start, end = date(2025,1,1), date(2025,12,31)
    days = [[0,0,0,0] for _ in range((end-start).days+1)]
    seen = set()
    with args.input.open(newline='', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            t = datetime.fromisoformat(row['operating_hour'].replace(' UTC','+00:00'))
            if t.utcoffset() != timedelta(0) or t.minute or t.second or t.microsecond:
                raise ValueError('Expected UTC hourly timestamps.')
            if t in seen or not start <= t.date() <= end:
                raise ValueError('Duplicate timestamp or date outside 2025.')
            seen.add(t)
            y, pred = int(row['actual_high_error']), int(row['predicted_high_error'])
            score = float(row['high_error_score'])
            if y not in (0,1) or pred not in (0,1) or not 0 <= score <= 1:
                raise ValueError('Invalid labels or score.')
            if score != 0.5 and pred != int(score > 0.5):
                raise ValueError('Predicted label inconsistent with 0.5 cutoff.')
            days[(t.date()-start).days][2*y+pred] += 1
    total = [sum(d[k] for d in days) for k in range(4)]
    if not total[0]+total[1] or not total[2]+total[3]:
        raise ValueError('Both classes are required.')
    baseline = [total[0]+total[1],0,total[2]+total[3],0]
    model_metrics, baseline_metrics = metrics(total), metrics(baseline)
    intervals = []
    for length in (7,14,28):
        rng = random.Random(args.seed+length)
        blocks, remainder = divmod(len(days),length)
        def windows(size):
            return [[sum(days[(i+j)%len(days)][k] for j in range(size))
                     for k in range(4)] for i in range(len(days))]
        full, partial = windows(length), windows(remainder)
        differences = {'accuracy': [], 'balanced_accuracy': []}
        for _ in range(args.replicates):
            c = [0,0,0,0]
            for b in range(blocks + bool(remainder)):
                chosen = (full if b < blocks else partial)[rng.randrange(len(days))]
                c = [x+y for x,y in zip(c,chosen)]
            if not c[0]+c[1] or not c[2]+c[3]:
                continue
            m = metrics(c)
            base_accuracy = (c[0]+c[1])/sum(c)
            differences['accuracy'].append(m['accuracy']-base_accuracy)
            differences['balanced_accuracy'].append(m['balanced_accuracy']-.5)
        for name, values in differences.items():
            intervals.append(dict(block_days=length, metric=name,
                difference=model_metrics[name]-baseline_metrics[name],
                ci95_lower=percentile(values,.025), ci95_upper=percentile(values,.975),
                valid_replicates=len(values)))
    args.output_dir.mkdir(parents=True,exist_ok=True)
    with (args.output_dir/'model_baseline_comparison.csv').open('w',newline='') as f:
        writer=csv.writer(f)
        writer.writerow(['metric','model','majority_baseline','difference'])
        for name, value in model_metrics.items():
            b=baseline_metrics[name]
            writer.writerow([name,value,b,value-b if b is not None else None])
    with (args.output_dir/'block_bootstrap_intervals.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(intervals[0]))
        writer.writeheader(); writer.writerows(intervals)
    lines = [
        'EXPLORATORY MODEL VERSUS MAJORITY-CLASS BASELINE COMPARISON',
        f'Input SHA256: {hashlib.sha256(args.input.read_bytes()).hexdigest()}',
        f'Test observations: {len(seen)}; UTC calendar days: {len(days)}',
        f'Days with no retained observations: {sum(sum(d)==0 for d in days)}',
        f'Absent test hours: {365*24-len(seen)} (not imputed)',
        f'TN={total[0]}, FP={total[1]}, FN={total[2]}, TP={total[3]}',
        f'Replicates per block length: {args.replicates}; base seed: {args.seed}',
        'Baseline always predicts 0, selected from the development-set majority.',
        'Classification cutoff: 0.5. No retraining or cutoff optimization.', '',
        'POINT ESTIMATES (proportions):', json.dumps({'model':model_metrics,'baseline':baseline_metrics},indent=2), '',
        'PAIRED DIFFERENCES: MODEL MINUS BASELINE (percentage points)',
    ]
    for r in intervals:
        lines.append(f"{r['block_days']}-day blocks, {r['metric']}: {100*r['difference']:.3f}; "
                     f"95% CI [{100*r['ci95_lower']:.3f}, {100*r['ci95_upper']:.3f}]")
    lines.extend(['', 'METHOD AND LIMITATIONS:',
        'Post hoc exploratory analysis: metric and inference method were selected after observing test results.',
        'Primary block length: 7 days; 14 and 28 days are sensitivity checks, not opportunities to select a favorable result.',
        'Each bootstrap draw resamples 365 days in consecutive circular blocks, using identical days for both methods.',
        'Daily confusion counts preserve gaps; zero-observation days remain on the calendar. The final block is truncated.',
        'Intervals are percentile intervals. Balanced accuracy averages sensitivity and specificity.',
        'No p-values or prespecified confirmatory hypothesis-test conclusions are reported.',
        'Model accuracy is lower than baseline accuracy. Balanced accuracy addresses a different objective.',
        'The intervals assume blocks adequately represent dependence. Seasonal change and one test year limit inference.',
        'Circular blocks join year-end to year-start. Block lengths may not capture longer dependence.',
        'Inference is conditional on the fitted model and retained test hours; it excludes training uncertainty and missing hours.',
        'Baseline precision is undefined because it predicts no positives; F1 is zero.', '',
        'METHOD REFERENCES:',
        'https://bashtage.github.io/arch/devel/bootstrap/timeseries-bootstraps.html',
        'https://scikit-learn.org/stable/modules/generated/sklearn.metrics.balanced_accuracy_score.html'])
    summary='\n'.join(lines)+'\n'
    (args.output_dir/'model_baseline_comparison.txt').write_text(summary,encoding='utf-8')
    print(summary)


if __name__ == '__main__':
    main()
