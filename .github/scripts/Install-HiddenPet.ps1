$ErrorActionPreference='Stop'
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'hidden-pet-source\jx_fares\desktop_pet'
$healthPath=Join-Path $root 'widget-status.json'
$oldPid=0
if (Test-Path $healthPath) {
  $old=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $oldPid=[int]$old.pid
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row -and (!$row.CommandLine -or $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -lt 0)) {throw 'Widget PID identity changed; installation withheld.'}
}
# Stop only the progress widget; scan and continuous-controller tasks stay running.
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ($oldPid -gt 0) {
  $row=Get-CimInstance Win32_Process -Filter "ProcessId=$oldPid"
  $expected=Join-Path $root 'Start-ProgressPet.ps1'
  if ($row) {
    if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0) {Stop-Process -Id $oldPid -ErrorAction Stop}
    else {throw 'Widget PID reused; installation withheld.'}
  }
}
foreach ($name in @('Start-ProgressPet.ps1','Pet.xaml')) {
  $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
  [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
$settings=Join-Path $root 'settings.json'
$prefs=if (Test-Path $settings) {Get-Content $settings -Raw -Encoding UTF8 | ConvertFrom-Json} else {[pscustomobject]@{}}
$prefs | Add-Member -NotePropertyName hidden -NotePropertyValue $true -Force
$prefs | ConvertTo-Json | Set-Content $settings -Encoding UTF8
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
  Start-Sleep -Seconds 1
  try {$health=Get-Content $healthPath -Raw -Encoding UTF8 | ConvertFrom-Json} catch {continue}
  if ($health.version -eq 13 -and $health.hidden -and !$health.visible -and $health.tray_visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Hidden widget did not report its tray and heartbeat.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible) hidden=$($health.hidden) tray=$($health.tray_visible)"
