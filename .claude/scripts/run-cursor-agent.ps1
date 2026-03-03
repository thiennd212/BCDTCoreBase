param(
    [Parameter(Mandatory=$true)][string]$TaskFile,
    [string]$Model          = "auto",
    [string]$Workspace      = "D:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase",
    [string]$ApiKey         = $env:CURSOR_API_KEY,
    [int]   $TimeoutSeconds = 120,
    [switch]$RunBuild,
    [switch]$RunTest
)

$agentExe   = "C:\Users\thien\AppData\Local\cursor-agent\agent.cmd"
$taskRel    = ".apm\inbox\$TaskFile.md"
$taskAbs    = Join-Path $Workspace $taskRel
$resultPath = Join-Path $Workspace ".apm\inbox\$TaskFile.result.md"

if (-not (Test-Path $taskAbs)) { Write-Error "Task not found: $taskAbs"; exit 1 }

# Fix encoding for Vietnamese output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONUTF8 = "1"

$prompt = "Read the file $taskRel in this workspace and execute ALL instructions in it. Only read and edit files - do NOT run shell commands like dotnet or npm. Write all required output files."

Write-Host "cursor-agent | task: $TaskFile | model: $Model | timeout: ${TimeoutSeconds}s"

# Run agent in background job to support timeout
$job = Start-Job -ScriptBlock {
    param($exe, $key, $ws, $model, $prompt)
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $env:CURSOR_API_KEY = $key
    & $exe --api-key $key --print --trust --workspace $ws --model $model --output-format text $prompt 2>&1
} -ArgumentList $agentExe, $ApiKey, $Workspace, $Model, $prompt

$completed = Wait-Job $job -Timeout $TimeoutSeconds
if (-not $completed) {
    Stop-Job $job | Out-Null
    Remove-Job $job -Force
    Write-Error "TIMEOUT after ${TimeoutSeconds}s"
    $status = "TIMEOUT"
    $result = "Agent did not complete within ${TimeoutSeconds}s. Try increasing -TimeoutSeconds or splitting the task."
} else {
    $rawBytes = Receive-Job $job
    Remove-Job $job -Force
    $result = ($rawBytes | ForEach-Object { "$_" }) -join "`n"
    $status  = "DONE"
}

$buildLine = ""
if ($RunBuild) {
    Write-Host "dotnet build..."
    $bo = & dotnet build "$Workspace\src\BCDT.Api" --no-restore -c Release 2>&1
    $buildLine = if ($LASTEXITCODE -eq 0) { "Build: PASS" } else { "Build: FAIL`n" + ($bo -join "`n") }
    Write-Host $buildLine
}

$testLine = ""
if ($RunTest) {
    Write-Host "dotnet test..."
    $to = & dotnet test "$Workspace\src\BCDT.Tests" 2>&1
    $testLine = if ($LASTEXITCODE -eq 0) { "Test: PASS" } else { "Test: FAIL`n" + ($to -join "`n") }
    Write-Host $testLine
}

$ts  = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$out = "status: $status`ntimestamp: $ts`n`n$result"
if ($buildLine) { $out += "`n`n$buildLine" }
if ($testLine)  { $out += "`n`n$testLine" }

[System.IO.File]::WriteAllText($resultPath, $out, [System.Text.Encoding]::UTF8)
Write-Host "Done -> $resultPath"
