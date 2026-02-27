<#
.SYNOPSIS
    Đảm bảo dữ liệu test cho màn nhập liệu Excel (gọi script SQL).
.DESCRIPTION
    Chạy docs/script_core/sql/v2/Ensure-TestData.ps1 với đường dẫn và connection string từ repo.
.EXAMPLE
    .\scripts\Ensure-TestData.ps1
    .\scripts\Ensure-TestData.ps1 -SkipMoreSubmissions
#>

param(
    [string] $ConnectionString = $env:BCDT_ConnectionString,
    [switch] $SkipMoreSubmissions
)

$RepoRoot = Split-Path $PSScriptRoot -Parent
$SqlScriptDir = Join-Path $RepoRoot 'docs\script_core\sql\v2'
$EnsureScript = Join-Path $SqlScriptDir 'Ensure-TestData.ps1'

if (-not (Test-Path $EnsureScript)) {
    Write-Error "Không tìm thấy script: $EnsureScript"
    exit 1
}

& $EnsureScript -ConnectionString $ConnectionString -SkipMoreSubmissions @args
