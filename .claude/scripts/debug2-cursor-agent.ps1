# Test: file edit OK, shell command hang?
$key   = 'key_b59b6087a2e665275dc3b89e83df7ecd2ff6c8614354a0b47f1cd34f573ab746'
$agent = 'C:\Users\thien\AppData\Local\cursor-agent\agent.cmd'
$ws    = 'D:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase'

Write-Host "=== Test: Write file + run shell command ==="
$prompt = 'Do two things: 1) Create .apm/inbox/test_shell.txt with content "shell test". 2) Run the shell command: echo hello_from_shell'

$job = Start-Job -ScriptBlock {
    param($agent, $key, $ws, $prompt)
    & $agent --api-key $key --print --trust --workspace $ws --model auto $prompt 2>&1
} -ArgumentList $agent, $key, $ws, $prompt

$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline -and $job.State -eq 'Running') {
    Start-Sleep -Milliseconds 500
    Receive-Job $job | ForEach-Object { Write-Host "OUT: $_" }
}
Receive-Job $job | ForEach-Object { Write-Host "OUT: $_" }
Write-Host "Job state: $($job.State)"
Stop-Job $job -PassThru | Remove-Job -Force

if (Test-Path "$ws\.apm\inbox\test_shell.txt") {
    Write-Host "File created: OK"
} else {
    Write-Host "File NOT created (agent hung before/during file write)"
}
