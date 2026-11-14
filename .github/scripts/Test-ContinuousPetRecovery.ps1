$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Update-ContinuousPet.ps1') -TestOnly
$repo='EDDIELI-coder/as-award-scanner'
$old=[pscustomobject]@{state='scan_failed';run_id='10'}
$s=[pscustomobject]@{runner_repo=$repo;executor_kind='home';state='partial';github_run_id='11';github_run_attempt='1';blocked=$null;modes=[pscustomobject]@{daily=[pscustomobject]@{pages_ok=4;pages_cached=0;details_ok=0;errors=[pscustomobject]@{};retry_errors=[pscustomobject]@{}}}}
$r=[pscustomobject]@{id='11';run_attempt=1;status='completed';conclusion='success'}
if (!(Test-SavedControllerRecovery $old $s $r $repo 'home')) {throw 'A newer clean saved native batch should recover an old failure.'}
$r.conclusion='failure'
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'Failed workflows must stay stopped.'}
$r.conclusion='success';$s.blocked='captcha'
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'A challenge must stay stopped.'}
$s.blocked=$null;$old.state='dispatch_unconfirmed'
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'An ambiguous dispatch must stay stopped.'}
$old.state='scan_failed';$s.modes.daily.pages_cached=4
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'Cached-only results must not recover.'}
$s.modes.daily.pages_cached=0;$r.run_attempt=2
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'A different attempt must not recover.'}
$r.run_attempt=1;$old.run_id='11'
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'The same old run must not be treated as a newer clean batch.'}
$old.run_id='10';$s.modes.daily.details_fail=1
if (Test-SavedControllerRecovery $old $s $r $repo 'home') {throw 'Query errors must stay stopped.'}
Write-Host 'PASS: newer clean save, failure, challenge, ambiguous dispatch, cached-only, identity and errors.'
