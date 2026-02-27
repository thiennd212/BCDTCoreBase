<#
.SYNOPSIS
    Kiểm tra dữ liệu test cho màn nhập liệu Excel và chạy seed khi thiếu.
.DESCRIPTION
    - Kiểm tra Form TEST_EXCEL_ENTRY có submission + ReportDataRow.
    - Kiểm tra Form TEST_EXCEL_FULL có submission + ReportDataRow.
    - Nếu thiếu thì chạy seed_test_excel_entry.sql, seed_test_excel_full_form.sql, seed_more_submissions_excel_entry.sql.
.PARAMETER ConnectionString
    Chuỗi kết nối SQL Server. Mặc định đọc từ env BCDT_ConnectionString hoặc appsettings.Development.json.
.PARAMETER SkipMoreSubmissions
    Không chạy seed_more_submissions_excel_entry.sql (chỉ đảm bảo có ít nhất 1 submission có data).
.EXAMPLE
    .\Ensure-TestData.ps1
    .\Ensure-TestData.ps1 -ConnectionString "Server=localhost;Database=BCDT;User Id=sa;Password=xxx;TrustServerCertificate=True"
#>

param(
    [string] $ConnectionString = $env:BCDT_ConnectionString,
    [switch] $SkipMoreSubmissions
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot

# --- Lấy connection string từ appsettings nếu chưa có ---
if (-not $ConnectionString) {
    # ScriptDir = .../docs/script_core/sql/v2 -> repo root = 4 cấp lên
    $repoRoot = $ScriptDir | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
    $appsettingsPath = Join-Path $repoRoot 'src\BCDT.Api\appsettings.Development.json'
    if (Test-Path $appsettingsPath) {
        $json = Get-Content $appsettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $ConnectionString = $json.ConnectionStrings.DefaultConnection
    }
}

if (-not $ConnectionString) {
    Write-Error 'Thieu ConnectionString. Dat env BCDT_ConnectionString hoac -ConnectionString, hoac appsettings.Development.json.'
}

# --- Parse connection string thành tham số sqlcmd ---
$cs = @{}
foreach ($pair in ($ConnectionString -split ';')) {
    $kv = $pair -split '=', 2
    if ($kv.Count -eq 2) { $cs[$kv[0].Trim()] = $kv[1].Trim() }
}
$server = if ($cs['Server']) { $cs['Server'] } else { $cs['Data Source'] }
$database = if ($cs['Database']) { $cs['Database'] } else { $cs['Initial Catalog'] }
$user = if ($cs['User Id']) { $cs['User Id'] } else { $cs['UserId'] }
$password = $cs['Password']
$trustCert = ($cs['TrustServerCertificate'] -eq 'True')

if (-not $server -or -not $database) {
    Write-Error "ConnectionString phai co Server va Database. Server=$server, Database=$database"
}

# --- Kiểm tra sqlcmd có sẵn ---
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    Write-Warning 'Khong tim thay sqlcmd. Cai SQL Server Command Line Utilities.'
    Write-Host 'Hoac chay thu cong: seed_test_excel_entry.sql, seed_test_excel_full_form.sql, seed_more_submissions_excel_entry.sql'
    exit 1
}

function Invoke-SqlcmdCheck {
    param([string]$Query)
    $sqlArgs = @('-S', $server, '-d', $database, '-Q', $Query, '-h', '-1', '-W')
    if ($user) { $sqlArgs += '-U', $user; if ($password) { $sqlArgs += '-P', $password } }
    else { $sqlArgs += '-E' }
    if ($trustCert) { $sqlArgs += '-C' }
    $out = & sqlcmd @sqlArgs 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    $out = ($out | Where-Object { $_ -match '\S' }) -join ' '
    return $out.Trim()
}

function Invoke-SqlcmdFile {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) {
        Write-Warning "File khong ton tai: $FilePath"
        return $false
    }
    Write-Host "Chay: $FilePath" -ForegroundColor Cyan
    $sqlArgs = @('-S', $server, '-d', $database, '-i', $FilePath, '-b')
    if ($user) { $sqlArgs += '-U', $user; if ($password) { $sqlArgs += '-P', $password } }
    else { $sqlArgs += '-E' }
    if ($trustCert) { $sqlArgs += '-C' }
    & sqlcmd @sqlArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "sqlcmd loi: $LASTEXITCODE"
        return $false
    }
    return $true
}

Write-Host '=== Kiểm tra dữ liệu test BCDT ===' -ForegroundColor Green
Write-Host "Server: $server, Database: $database"

# Kiem tra schema (bang form ton tai)
$qTable = "SELECT 1 WHERE EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FormDefinition')"
$hasSchema = Invoke-SqlcmdCheck -Query $qTable
if (-not $hasSchema) {
    Write-Error 'Chua co schema BCDT. Chay 01..14 (schema + seed_data), 12 (RLS), roi chay lai script nay.'
}

# Điều kiện test: TEST_EXCEL_ENTRY có ít nhất 1 submission có ít nhất 1 ReportDataRow
$qEntry = @"
SELECT CAST(1 AS VARCHAR(1)) WHERE EXISTS (
  SELECT 1 FROM [dbo].[BCDT_FormDefinition] f
  INNER JOIN [dbo].[BCDT_ReportSubmission] s ON s.FormDefinitionId = f.Id
  INNER JOIN [dbo].[BCDT_ReportDataRow] r ON r.SubmissionId = s.Id
  WHERE f.[Code] = N'TEST_EXCEL_ENTRY'
)
"@
$hasEntry = Invoke-SqlcmdCheck -Query $qEntry

# Điều kiện test: TEST_EXCEL_FULL có ít nhất 1 submission có ít nhất 1 ReportDataRow
$qFull = @"
SELECT CAST(1 AS VARCHAR(1)) WHERE EXISTS (
  SELECT 1 FROM [dbo].[BCDT_FormDefinition] f
  INNER JOIN [dbo].[BCDT_ReportSubmission] s ON s.FormDefinitionId = f.Id
  INNER JOIN [dbo].[BCDT_ReportDataRow] r ON r.SubmissionId = s.Id
  WHERE f.[Code] = N'TEST_EXCEL_FULL'
)
"@
$hasFull = Invoke-SqlcmdCheck -Query $qFull

$needsMore = $false
if (-not $SkipMoreSubmissions) {
    # Có ít nhất 2 submission có data cho TEST_EXCEL_ENTRY (để test nhiều bản ghi)
    $qCount = @"
SELECT CAST(COUNT(DISTINCT s.Id) AS VARCHAR(10)) FROM [dbo].[BCDT_FormDefinition] f
INNER JOIN [dbo].[BCDT_ReportSubmission] s ON s.FormDefinitionId = f.Id
INNER JOIN [dbo].[BCDT_ReportDataRow] r ON r.SubmissionId = s.Id
WHERE f.[Code] = N'TEST_EXCEL_ENTRY'
"@
    $subCount = Invoke-SqlcmdCheck -Query $qCount
    if ([string]::IsNullOrWhiteSpace($subCount) -or [int]$subCount -lt 2) { $needsMore = $true }
}

# --- Chạy seed khi thiếu ---
if (-not $hasEntry) {
    Write-Host 'Thieu du lieu TEST_EXCEL_ENTRY. Chay seed_test_excel_entry.sql' -ForegroundColor Yellow
    $ok = Invoke-SqlcmdFile -FilePath (Join-Path $ScriptDir 'seed_test_excel_entry.sql')
    if (-not $ok) { exit 1 }
    $hasEntry = $true
} else {
    Write-Host 'TEST_EXCEL_ENTRY: da co du lieu.' -ForegroundColor Green
}

if ($needsMore) {
    Write-Host 'Bo sung submission cho TEST_EXCEL_ENTRY. Chay seed_more_submissions_excel_entry.sql' -ForegroundColor Yellow
    $ok = Invoke-SqlcmdFile -FilePath (Join-Path $ScriptDir 'seed_more_submissions_excel_entry.sql')
    if (-not $ok) { Write-Warning 'seed_more_submissions_excel_entry.sql co the loi hoac da du.' }
} else {
    Write-Host 'TEST_EXCEL_ENTRY: du submission de test.' -ForegroundColor Green
}

if (-not $hasFull) {
    Write-Host 'Thieu du lieu TEST_EXCEL_FULL. Chay seed_test_excel_full_form.sql' -ForegroundColor Yellow
    $ok = Invoke-SqlcmdFile -FilePath (Join-Path $ScriptDir 'seed_test_excel_full_form.sql')
    if (-not $ok) { exit 1 }
} else {
    Write-Host 'TEST_EXCEL_FULL: da co du lieu.' -ForegroundColor Green
}

# B12 P4: Danh mục chỉ tiêu + cây Indicator + FormDynamicRegion (cho test workbook-data pre-fill/merge)
$qP4 = "SELECT CAST(1 AS VARCHAR(1)) WHERE EXISTS (SELECT 1 FROM [dbo].[BCDT_IndicatorCatalog] WHERE Code = N'DM_P4_TEST')"
$hasP4 = Invoke-SqlcmdCheck -Query $qP4
if (-not $hasP4) {
    Write-Host 'B12 P4: Thieu danh muc DM_P4_TEST. Chay seed_b12_p4_workbook_dynamic.sql' -ForegroundColor Yellow
    $ok = Invoke-SqlcmdFile -FilePath (Join-Path $ScriptDir 'seed_b12_p4_workbook_dynamic.sql')
    if (-not $ok) { Write-Warning 'seed_b12_p4_workbook_dynamic.sql co the loi (can script 20 + form/sheet).' }
} else {
    Write-Host 'B12 P4 (DM_P4_TEST): da co du lieu.' -ForegroundColor Green
}

Write-Host ''
Write-Host '=== Ket thuc. Du lieu test san sang. ===' -ForegroundColor Green
Write-Host 'Mo man nhap lieu: /submissions/{id}/entry voi id submission cua form TEST_EXCEL_ENTRY hoac TEST_EXCEL_FULL.'
