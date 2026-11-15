param([ValidateSet('home','office')][string]$Device='home')
$ErrorActionPreference='Stop'
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
$source=Join-Path $env:GITHUB_WORKSPACE 'backlog-source\jx_fares\desktop_pet'
. (Join-Path $source 'ProgressModel.ps1')
$receipts=@{};$enabled=@{}
foreach ($part in @('primary','backup')) {
    $task=Get-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part" -ErrorAction Stop
    if (!@($task.Triggers | Where-Object {$_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger'}).Count) {throw 'Expected login trigger missing; no changes made.'}
    $receipt=Read-PetJson (Join-Path $root "launch-status-$part.json")
    if ($receipt.state -eq 'requesting') {throw 'A dispatch is being confirmed. Retry maintenance after it settles.'}
    $receipts[$part]=$receipt
    $enabled[$part]=($receipt -and $receipt.state -in @('running_continuous','waiting_verification','saving_result','requested','next_batch','metadata_retry','idle_wait','idle_no_reads','stopped_continuous'))
    Write-Host "[before] $part task=$($task.State) state=$($receipt.state) enabled=$($receipt.enabled) error=$($receipt.error_code) run=$($receipt.run_id) at=$($receipt.at)"
}
# Only metadata controllers are stopped. GitHub jobs, scan Python and Chrome remain alive.
foreach ($part in @('primary','backup')) {Stop-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"}
Start-Sleep -Seconds 2
foreach ($row in Get-CimInstance Win32_Process | Where-Object {$_.Name -in @('powershell.exe','pythonw.exe')}) {
    $expected=Join-Path $root 'Start-DesktopScan.ps1'
    if ($row.CommandLine -and $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $row.CommandLine -match '-Partition\s+(primary|backup)(\s|$)') {Stop-Process -Id $row.ProcessId -ErrorAction Stop}
}
foreach ($part in @('primary','backup')) {
    $after=Read-PetJson (Join-Path $root "launch-status-$part.json")
    # A newer dispatch/terminal decision must win over the initial snapshot.
    if ($after -and $after.at -gt $receipts[$part].at -and $after.state -ne 'stopped_continuous') {
        $receipts[$part]=$after
        $enabled[$part]=$after.state -in @('running_continuous','waiting_verification','saving_result','requested','next_batch','metadata_retry','idle_wait','idle_no_reads')
    }
}
$healthPath=Join-Path $root 'widget-status.json'
$old=Read-PetJson $healthPath
Stop-ScheduledTask -TaskName 'AS-Award-ProgressPet' -ErrorAction Stop
Start-Sleep -Seconds 2
if ([int]$old.pid -gt 0) {
    $row=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$old.pid)"
    $expected=Join-Path $root 'Start-ProgressPet.ps1'
    if ($row) {
        if (!$row.CommandLine -or $row.CommandLine.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -lt 0) {throw 'Widget PID identity changed; no process killed.'}
        Stop-Process -Id $row.ProcessId
    }
}
foreach ($name in @('Start-ProgressPet.ps1','Pet.xaml','ProgressModel.ps1','BacklogView.ps1','ContinuousScan.ps1','Start-DesktopScan.ps1')) {
    $body=Get-Content (Join-Path $source $name) -Raw -Encoding UTF8
    [IO.File]::WriteAllText((Join-Path $root $name),$body,[Text.UTF8Encoding]::new($true))
}
foreach ($part in @('primary','backup')) {
    New-Item -ItemType File -Path (Join-Path $root "autostart-$part") -Force | Out-Null
    $receipt=$receipts[$part]
    if ($enabled[$part]) {
        # Resume the same identity before considering another dispatch.
        if ($receipt.run_id -match '^\d+$') {$receipt.state='saving_result';$receipt.enabled=$true}
        $receipt | ConvertTo-Json -Compress | Set-Content (Join-Path $root "launch-status-$part.json") -Encoding UTF8
        Remove-Item (Join-Path $root "stop-continuous-$part") -ErrorAction SilentlyContinue
        New-Item -ItemType File -Path (Join-Path $root "continuous-enabled-$part") -Force | Out-Null
        Start-ScheduledTask -TaskName "AS-Award-Continuous-$Device-$part"
    } else {
        Remove-Item (Join-Path $root "continuous-enabled-$part") -ErrorAction SilentlyContinue
        $receipt | ConvertTo-Json -Compress | Set-Content (Join-Path $root "launch-status-$part.json") -Encoding UTF8
        Write-Host "[retained-stop] $part $($receipt.state); verification/failure/ambiguous dispatch is not reset by installation"
    }
}
$started=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
Start-ScheduledTask -TaskName 'AS-Award-ProgressPet'
$ready=$false
for ($i=0;$i -lt 30;$i++) {
    Start-Sleep -Seconds 1
    $health=Read-PetJson $healthPath
    if ($health.version -eq 14 -and $health.tray_visible -and $health.at -ge $started) {$ready=$true;break}
}
if (!$ready) {throw 'Widget v14 did not report a fresh heartbeat.'}
Write-Host "[widget] version=$($health.version) visible=$($health.visible) hidden=$($health.hidden) tray=$($health.tray_visible)"
foreach ($part in @('primary','backup')) {
    $receipt=Read-PetJson (Join-Path $root "launch-status-$part.json")
    Write-Host "[after] $part state=$($receipt.state) enabled=$($receipt.enabled) error=$($receipt.error_code) run=$($receipt.run_id) at=$($receipt.at)"
    $repo=if ($part -eq 'primary') {'as-award-scanner'} else {'as-award-scanner-backup'}
    $data=Join-Path $env:LOCALAPPDATA "AsAwardRunner\$Device\$part\_work\$repo\$repo\data"
    $summary=Read-PetJson (Join-Path $data 'scan_status.json')
    Write-Host "[scan] $part state=$($summary.state) reason=$($summary.stop_reason) reads=$($summary.successful_reads) executor=$($summary.executor_kind) run=$($summary.github_run_id)"
}
