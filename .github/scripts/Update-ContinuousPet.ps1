param([ValidateSet('home','office')][string]$Device='home',[switch]$TestOnly)
$ErrorActionPreference='Stop'
function Test-SavedControllerRecovery($Previous,$Summary,$Run,[string]$Repo,[string]$Device) {
  if (!$Previous -or $Previous.state -notin @('scan_failed','batch_not_started')) { return $false }
  if ($Summary.runner_repo -ne $Repo -or $Summary.executor_kind -ne $Device -or $Summary.state -notin @('partial','complete') -or $Summary.blocked) { return $false }
  if ([string]$Summary.github_run_id -notmatch '^\d+
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'scheduler-source\jx_fares\desktop_pet'
$receipts=@{};$enable=@{}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$null
  for ($i=0;$i -lt 15;$i++) {
    if (Test-Path $path) { $status=Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    if (!$status -or $status.state -ne 'requesting') { break }
    Start-Sleep -Seconds 2
  }
  if ($status.state -eq 'requesting') { throw 'Dispatch is still being confirmed; controller update withheld.' }
  Get-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop | Out-Null
  if ($status.state -in @('scan_failed','batch_not_started')) {
    $repo=if ($part -eq 'primary') {'EDDIELI-coder/as-award-scanner'} else {'EDDIELI-coder/as-award-scanner-backup'}
    $env:GH_PROMPT_DISABLED='1'
    $encoded=& gh.exe api "repos/EDDIELI-coder/claude--/contents/worker_data/$part/scan_status.json?ref=award-data" --jq '.content'
    if ($LASTEXITCODE -ne 0) { throw 'Saved result could not be checked; stopped controller retained.' }
    $saved=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($encoded -join ''))) | ConvertFrom-Json
    if ([string]$saved.github_run_id -match '^\d+
  $enable[$part]=!($status.state -in @('needs_verification','scan_failed','dispatch_unconfirmed','batch_not_started'))
}
# Stop only metadata controllers; their scan workflow, Python and Chrome continue.
foreach ($part in @('primary','backup')) {
  Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
  $expected=Join-Path $root 'Start-DesktopScan.ps1'
  if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {
    Stop-Process -Id $row.ProcessId -ErrorAction Stop
  }
}
foreach ($name in @('ContinuousScan.ps1','Start-ProgressPet.ps1')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$receipts[$part]
  if ($enable[$part]) {
    # Resume the known run before considering another dispatch.
    if ($status -and $status.run_id -match '^\d+$' -and [int]$status.attempt -gt 0) {
      $status.enabled=$true;$status.state='saving_result'
      $status | ConvertTo-Json -Compress | Set-Content $path -Encoding UTF8
    }
    Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
    Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
  } else {
    Write-Host "[controller] $part retained stop reason $($status.state)"
  }
}
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) { $health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldPid=[int]$health.pid }
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and $row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) { Stop-Process -Id $oldPid -ErrorAction Stop }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 12 -and $health.visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v12 did not confirm startup.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible)"
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  if (Test-Path $path) {
    Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object partition,state,enabled,run_id,attempt,batches,error_code | ConvertTo-Json -Compress
  }
}
 -or [string]$Previous.run_id -notmatch '^\d+
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'scheduler-source\jx_fares\desktop_pet'
$receipts=@{};$enable=@{}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$null
  for ($i=0;$i -lt 15;$i++) {
    if (Test-Path $path) { $status=Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    if (!$status -or $status.state -ne 'requesting') { break }
    Start-Sleep -Seconds 2
  }
  if ($status.state -eq 'requesting') { throw 'Dispatch is still being confirmed; controller update withheld.' }
  Get-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop | Out-Null
  $receipts[$part]=$status
  $enable[$part]=!($status.state -in @('needs_verification','scan_failed','dispatch_unconfirmed','batch_not_started'))
}
# Stop only metadata controllers; their scan workflow, Python and Chrome continue.
foreach ($part in @('primary','backup')) {
  Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
  $expected=Join-Path $root 'Start-DesktopScan.ps1'
  if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {
    Stop-Process -Id $row.ProcessId -ErrorAction Stop
  }
}
foreach ($name in @('ContinuousScan.ps1','Start-ProgressPet.ps1')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$receipts[$part]
  if ($enable[$part]) {
    # Resume the known run before considering another dispatch.
    if ($status -and $status.run_id -match '^\d+$' -and [int]$status.attempt -gt 0) {
      $status.enabled=$true;$status.state='saving_result'
      $status | ConvertTo-Json -Compress | Set-Content $path -Encoding UTF8
    }
    Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
    Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
  } else {
    Write-Host "[controller] $part retained stop reason $($status.state)"
  }
}
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) { $health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldPid=[int]$health.pid }
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and $row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) { Stop-Process -Id $oldPid -ErrorAction Stop }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 12 -and $health.visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v12 did not confirm startup.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible)"
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  if (Test-Path $path) {
    Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object partition,state,enabled,run_id,attempt,batches,error_code | ConvertTo-Json -Compress
  }
}
 -or [long]$Summary.github_run_id -le [long]$Previous.run_id) { return $false }
  if ($Run.status -ne 'completed' -or $Run.conclusion -ne 'success' -or [string]$Run.id -ne [string]$Summary.github_run_id -or [string]$Run.run_attempt -ne [string]$Summary.github_run_attempt) { return $false }
  $reads=0
  foreach ($mode in $Summary.modes.PSObject.Properties) {
    $s=$mode.Value
    if ($s.blocked -or $s.process_error -or $s.pages_err -or $s.details_fail -or $s.errors.PSObject.Properties.Count -or $s.retry_errors.PSObject.Properties.Count) { return $false }
    $reads += [math]::Max(0,[int]$s.pages_ok-[int]$s.pages_cached)+[int]$s.details_ok
  }
  return $reads -gt 0
}

if ($TestOnly) { return }
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'scheduler-source\jx_fares\desktop_pet'
$receipts=@{};$enable=@{}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$null
  for ($i=0;$i -lt 15;$i++) {
    if (Test-Path $path) { $status=Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    if (!$status -or $status.state -ne 'requesting') { break }
    Start-Sleep -Seconds 2
  }
  if ($status.state -eq 'requesting') { throw 'Dispatch is still being confirmed; controller update withheld.' }
  Get-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop | Out-Null
  $receipts[$part]=$status
  $enable[$part]=!($status.state -in @('needs_verification','scan_failed','dispatch_unconfirmed','batch_not_started'))
}
# Stop only metadata controllers; their scan workflow, Python and Chrome continue.
foreach ($part in @('primary','backup')) {
  Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
  $expected=Join-Path $root 'Start-DesktopScan.ps1'
  if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {
    Stop-Process -Id $row.ProcessId -ErrorAction Stop
  }
}
foreach ($name in @('ContinuousScan.ps1','Start-ProgressPet.ps1')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$receipts[$part]
  if ($enable[$part]) {
    # Resume the known run before considering another dispatch.
    if ($status -and $status.run_id -match '^\d+$' -and [int]$status.attempt -gt 0) {
      $status.enabled=$true;$status.state='saving_result'
      $status | ConvertTo-Json -Compress | Set-Content $path -Encoding UTF8
    }
    Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
    Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
  } else {
    Write-Host "[controller] $part retained stop reason $($status.state)"
  }
}
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) { $health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldPid=[int]$health.pid }
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and $row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) { Stop-Process -Id $oldPid -ErrorAction Stop }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 12 -and $health.visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v12 did not confirm startup.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible)"
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  if (Test-Path $path) {
    Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object partition,state,enabled,run_id,attempt,batches,error_code | ConvertTo-Json -Compress
  }
}
) {
      $raw=& gh.exe api "repos/$repo/actions/runs/$($saved.github_run_id)" --jq '{id:.id,run_attempt:.run_attempt,status:.status,conclusion:.conclusion}'
      if ($LASTEXITCODE -ne 0) { throw 'Result workflow could not be checked; stopped controller retained.' }
      $finished=$raw | ConvertFrom-Json
      if (Test-SavedControllerRecovery $status $saved $finished $repo $Device) {
        $status.state='saving_result';$status.enabled=$true
        $status.run_id=[string]$saved.github_run_id;$status.attempt=[int]$saved.github_run_attempt
        Write-Host "[controller] $part recovered from a newer confirmed clean saved batch"
      }
    }
  }
  $receipts[$part]=$status
  $enable[$part]=!($status.state -in @('needs_verification','scan_failed','dispatch_unconfirmed','batch_not_started'))
}
# Stop only metadata controllers; their scan workflow, Python and Chrome continue.
foreach ($part in @('primary','backup')) {
  Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
  $expected=Join-Path $root 'Start-DesktopScan.ps1'
  if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {
    Stop-Process -Id $row.ProcessId -ErrorAction Stop
  }
}
foreach ($name in @('ContinuousScan.ps1','Start-ProgressPet.ps1')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$receipts[$part]
  if ($enable[$part]) {
    # Resume the known run before considering another dispatch.
    if ($status -and $status.run_id -match '^\d+$' -and [int]$status.attempt -gt 0) {
      $status.enabled=$true;$status.state='saving_result'
      $status | ConvertTo-Json -Compress | Set-Content $path -Encoding UTF8
    }
    Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
    Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
  } else {
    Write-Host "[controller] $part retained stop reason $($status.state)"
  }
}
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) { $health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldPid=[int]$health.pid }
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and $row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) { Stop-Process -Id $oldPid -ErrorAction Stop }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 12 -and $health.visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v12 did not confirm startup.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible)"
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  if (Test-Path $path) {
    Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object partition,state,enabled,run_id,attempt,batches,error_code | ConvertTo-Json -Compress
  }
}
 -or [string]$Previous.run_id -notmatch '^\d+
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'scheduler-source\jx_fares\desktop_pet'
$receipts=@{};$enable=@{}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$null
  for ($i=0;$i -lt 15;$i++) {
    if (Test-Path $path) { $status=Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    if (!$status -or $status.state -ne 'requesting') { break }
    Start-Sleep -Seconds 2
  }
  if ($status.state -eq 'requesting') { throw 'Dispatch is still being confirmed; controller update withheld.' }
  Get-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop | Out-Null
  $receipts[$part]=$status
  $enable[$part]=!($status.state -in @('needs_verification','scan_failed','dispatch_unconfirmed','batch_not_started'))
}
# Stop only metadata controllers; their scan workflow, Python and Chrome continue.
foreach ($part in @('primary','backup')) {
  Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
  $expected=Join-Path $root 'Start-DesktopScan.ps1'
  if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {
    Stop-Process -Id $row.ProcessId -ErrorAction Stop
  }
}
foreach ($name in @('ContinuousScan.ps1','Start-ProgressPet.ps1')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$receipts[$part]
  if ($enable[$part]) {
    # Resume the known run before considering another dispatch.
    if ($status -and $status.run_id -match '^\d+$' -and [int]$status.attempt -gt 0) {
      $status.enabled=$true;$status.state='saving_result'
      $status | ConvertTo-Json -Compress | Set-Content $path -Encoding UTF8
    }
    Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
    Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
  } else {
    Write-Host "[controller] $part retained stop reason $($status.state)"
  }
}
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) { $health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldPid=[int]$health.pid }
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and $row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) { Stop-Process -Id $oldPid -ErrorAction Stop }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 12 -and $health.visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v12 did not confirm startup.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible)"
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  if (Test-Path $path) {
    Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object partition,state,enabled,run_id,attempt,batches,error_code | ConvertTo-Json -Compress
  }
}
 -or [long]$Summary.github_run_id -le [long]$Previous.run_id) { return $false }
  if ($Run.status -ne 'completed' -or $Run.conclusion -ne 'success' -or [string]$Run.id -ne [string]$Summary.github_run_id -or [string]$Run.run_attempt -ne [string]$Summary.github_run_attempt) { return $false }
  $reads=0
  foreach ($mode in $Summary.modes.PSObject.Properties) {
    $s=$mode.Value
    if ($s.blocked -or $s.process_error -or $s.pages_err -or $s.details_fail -or $s.errors.PSObject.Properties.Count -or $s.retry_errors.PSObject.Properties.Count) { return $false }
    $reads += [math]::Max(0,[int]$s.pages_ok-[int]$s.pages_cached)+[int]$s.details_ok
  }
  return $reads -gt 0
}

if ($TestOnly) { return }
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'scheduler-source\jx_fares\desktop_pet'
$receipts=@{};$enable=@{}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$null
  for ($i=0;$i -lt 15;$i++) {
    if (Test-Path $path) { $status=Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    if (!$status -or $status.state -ne 'requesting') { break }
    Start-Sleep -Seconds 2
  }
  if ($status.state -eq 'requesting') { throw 'Dispatch is still being confirmed; controller update withheld.' }
  Get-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop | Out-Null
  $receipts[$part]=$status
  $enable[$part]=!($status.state -in @('needs_verification','scan_failed','dispatch_unconfirmed','batch_not_started'))
}
# Stop only metadata controllers; their scan workflow, Python and Chrome continue.
foreach ($part in @('primary','backup')) {
  Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
  $expected=Join-Path $root 'Start-DesktopScan.ps1'
  if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {
    Stop-Process -Id $row.ProcessId -ErrorAction Stop
  }
}
foreach ($name in @('ContinuousScan.ps1','Start-ProgressPet.ps1')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  $status=$receipts[$part]
  if ($enable[$part]) {
    # Resume the known run before considering another dispatch.
    if ($status -and $status.run_id -match '^\d+$' -and [int]$status.attempt -gt 0) {
      $status.enabled=$true;$status.state='saving_result'
      $status | ConvertTo-Json -Compress | Set-Content $path -Encoding UTF8
    }
    Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
    Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
  } else {
    Write-Host "[controller] $part retained stop reason $($status.state)"
  }
}
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) { $health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldPid=[int]$health.pid }
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and $row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) { Stop-Process -Id $oldPid -ErrorAction Stop }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 12 -and $health.visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v12 did not confirm startup.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible)"
foreach ($part in @('primary','backup')) {
  $path=Join-Path $root "launch-status-$part.json"
  if (Test-Path $path) {
    Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object partition,state,enabled,run_id,attempt,batches,error_code | ConvertTo-Json -Compress
  }
}
