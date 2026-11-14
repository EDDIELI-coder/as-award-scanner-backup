param([ValidateSet('home','office')][string]$Device='home')
$ErrorActionPreference='Stop'
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
