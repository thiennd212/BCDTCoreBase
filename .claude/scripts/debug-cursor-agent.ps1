# Debug script – test cursor agent với timeout
$key   = 'key_b59b6087a2e665275dc3b89e83df7ecd2ff6c8614354a0b47f1cd34f573ab746'
$agent = 'C:\Users\thien\AppData\Local\cursor-agent\agent.cmd'
$ws    = 'D:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase'

Write-Host "=== Test 1: Read-only, no file ops ==="
$p1 = 'Read the file .apm/inbox/task_2_5.md and list the 3 main steps. Do NOT edit any files.'

$job = Start-Job -ScriptBlock {
    param($agent, $key, $ws, $prompt)
    & $agent --api-key $key --print --trust --workspace $ws --model auto $prompt 2>&1
} -ArgumentList $agent, $key, $ws, $p1

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline -and $job.State -eq 'Running') {
    Start-Sleep -Milliseconds 500
    Receive-Job $job | ForEach-Object { Write-Host "OUT: $_" }
}
Receive-Job $job | ForEach-Object { Write-Host "OUT: $_" }
$state = $job.State
Stop-Job $job -PassThru | Remove-Job -Force
Write-Host "Job state: $state"
Write-Host ""

Write-Host "=== Test 2: Write a simple file ==="
$p2 = 'Create a file called .apm/inbox/cli_write_test.txt with the content: "write test OK"'

$job2 = Start-Job -ScriptBlock {
    param($agent, $key, $ws, $prompt)
    & $agent --api-key $key --print --trust --workspace $ws --model auto $prompt 2>&1
} -ArgumentList $agent, $key, $ws, $p2

$deadline2 = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline2 -and $job2.State -eq 'Running') {
    Start-Sleep -Milliseconds 500
    Receive-Job $job2 | ForEach-Object { Write-Host "OUT: $_" }
}
Receive-Job $job2 | ForEach-Object { Write-Host "OUT: $_" }
$state2 = $job2.State
Stop-Job $job2 -PassThru | Remove-Job -Force
Write-Host "Job state: $state2"

Write-Host ""
Write-Host "=== Check if file was created ==="
if (Test-Path "$ws\.apm\inbox\cli_write_test.txt") {
    Write-Host "FILE EXISTS:" (Get-Content "$ws\.apm\inbox\cli_write_test.txt")
} else {
    Write-Host "FILE NOT CREATED"
}
