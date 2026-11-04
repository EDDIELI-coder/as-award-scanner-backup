"""只讀診斷，不載入瀏覽器、不寫回資料、不派送查詢。"""
import argparse
import datetime as dt
import json
import os
from pathlib import Path
import sys


def summary(state, awards, now, allowed, recovery_deadline):
    calendars = details = 0
    unknown = False
    for batch in (awards.get('scan_progress') or {}).values():
        plan = batch.get('calendar_plan')
        if isinstance(plan, list):
            calendars += len(set(plan)-set(batch.get('calendar_done') or []))
        else:
            unknown = True
        left = batch.get('details_left')
        if type(left) is int and left >= 0:
            details += left
        else:
            unknown = True
    return dict(mode='diagnostic_only', airline_requests=0,
                can_start_normal_run=allowed(state, now),
                retry_after=recovery_deadline(state),
                last_run=state.get('last_run'), last_success=state.get('last_success'),
                calendar_pending_across_modes=calendars, details_pending_across_modes=details,
                counts_include_overlapping_modes=True, some_counts_unknown=unknown)


def main():
    parser = argparse.ArgumentParser()
    for name in ('source', 'state', 'awards'):
        parser.add_argument('--'+name, type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.source.resolve()))
    from scan_preflight import allowed, recovery_deadline
    paths = (args.state, args.awards)
    before = [p.read_bytes() for p in paths]
    state, awards = [json.loads(value) for value in before]
    if not isinstance(state, dict) or not isinstance(awards, dict) or not isinstance(state.get('last_run'), str):
        raise ValueError('missing shared state')
    report = summary(state, awards, dt.datetime.now(dt.timezone.utc), allowed, recovery_deadline)
    if before != [p.read_bytes() for p in paths]:
        raise RuntimeError('shared state changed during check')
    text = json.dumps(report, ensure_ascii=False, indent=2)
    print(text)
    note = '備用檢查完成；航空查詢 0 次，未驗證航空網站是否可查。待查數含模式重疊，不代表唯一任務數。'
    print(note)
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as output:
            output.write('## 備用檢查\n\n```json\n'+text+'\n```\n\n'+note+'\n')


if __name__ == '__main__':
    main()
