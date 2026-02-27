<#
.SYNOPSIS
    Chay script 21.p8_filter_placeholder.sql (P8a).
#>
param([string] $ConnectionString = $env:BCDT_ConnectionString)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot
if (-not $ConnectionString) {
    $repoRoot = $ScriptDir | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
    $appPath = Join-Path $repoRoot 'src\BCDT.Api\appsettings.Development.json'
    if (Test-Path $appPath) {
        $json = Get-Content $appPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $ConnectionString = $json.ConnectionStrings.DefaultConnection
    }
}
if (-not $ConnectionString) { Write-Error 'Thieu ConnectionString'; exit 1 }

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
if (-not $server -or -not $database) { Write-Error 'ConnectionString phai co Server va Database'; exit 1 }

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if (-not $sqlcmd) { Write-Error 'Khong tim thay sqlcmd'; exit 1 }

$scriptPath = Join-Path $ScriptDir '21.p8_filter_placeholder.sql'
$sqlArgs = @('-S', $server, '-d', $database, '-i', $scriptPath, '-b')
if ($user) { $sqlArgs += '-U', $user; if ($password) { $sqlArgs += '-P', $password } } else { $sqlArgs += '-E' }
if ($trustCert) { $sqlArgs += '-C' }
& sqlcmd @sqlArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host '21.p8_filter_placeholder.sql completed.'
