import datetime as dt
import unittest
from standby_check import summary


class StandbyTests(unittest.TestCase):
    def test_retains_deadline_and_pending_without_modifying_state(self):
        state = dict(last_run='2026-11-04T12:56+08:00', blocked_until='2026-11-05T12:56+08:00')
        awards = {'scan_progress': {'daily': {'calendar_plan':['a','b'], 'calendar_done':['a'], 'details_left':4}}}
        before = repr((state, awards))
        row = summary(state, awards, dt.datetime.now(dt.timezone.utc), lambda s,n:False, lambda s:s['blocked_until'])
        self.assertEqual(row['airline_requests'], 0)
        self.assertFalse(row['can_start_normal_run'])
        self.assertEqual(row['retry_after'], state['blocked_until'])
        self.assertEqual(row['calendar_pending_across_modes'], 1)
        self.assertEqual(row['details_pending_across_modes'], 4)
        self.assertEqual(before, repr((state, awards)))

    def test_unknown_is_not_complete(self):
        row = summary({}, {'scan_progress': {'daily': {}}}, dt.datetime.now(dt.timezone.utc), lambda s,n:True, lambda s:None)
        self.assertTrue(row['some_counts_unknown'])
        self.assertEqual(row['mode'], 'diagnostic_only')
