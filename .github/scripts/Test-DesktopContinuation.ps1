$ErrorActionPreference='Stop'
$root=Join-Path $env:LOCALAPPDATA 'AsAwardProgressPet'
. (Join-Path $root 'ProgressModel.ps1')
. (Join-Path $root 'ScanLauncher.ps1')
. (Join-Path $root 'ContinuousScan.ps1')
foreach ($part in @('primary','backup')) {
    $receipt=Read-PetJson (Join-Path $root "launch-status-$part.json")
    Write-Host "[receipt] $part state=$($receipt.state) error=$($receipt.error_code) location=$($receipt.error_location)"
    $repo=Get-PetControllerRepo $part
    $phase='runs'
    try {
        $runs=@(Get-PetControllerRuns $repo)
        Write-Host "[metadata] $part runs=$($runs.Count)"
        if ($receipt.run_id -notmatch '^\d+$') {Write-Host "[metadata] $part no known run";continue}
        $phase='run'
        $run=Get-PetControllerRun $repo ([string]$receipt.run_id)
        Write-Host "[metadata] $part run=$($run.id) status=$($run.status) conclusion=$($run.conclusion) attempt=$($run.attempt)"
        $phase='skipped'
        $skipped=Get-PetControllerSkipped $repo ([string]$receipt.run_id)
        Write-Host "[metadata] $part skipped=$skipped"
        $phase='summary'
        $summary=Get-PetControllerSummary $repo $part
        Write-Host "[metadata] $part summary_run=$($summary.github_run_id) state=$($summary.state) mode_count=$(@($summary.modes.PSObject.Properties).Count)"
        $phase='decision'
        $decision=Get-PetContinuationDecision $summary $repo ([string]$receipt.run_id) ([int]$receipt.attempt) $run.conclusion
        Write-Host "[metadata] $part decision=$decision"
    } catch {
        # Known functions read only run metadata and safe scan summaries, never credentials.
        $message=$_.Exception.Message -replace '[\r\n]+',' '
        if ($message.Length -gt 200) {$message=$message.Substring(0,200)}
        Write-Host "[diagnostic] $part phase=$phase type=$($_.Exception.GetType().Name) line=$($_.InvocationInfo.ScriptLineNumber) message=$message"
    }
}
