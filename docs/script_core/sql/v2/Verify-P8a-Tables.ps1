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
$q = "SELECT name FROM sys.tables WHERE name IN ('BCDT_DataSource','BCDT_FilterDefinition','BCDT_FilterCondition','BCDT_FormPlaceholderOccurrence') ORDER BY name"
$sqlArgs = @('-S', $server, '-d', $database, '-Q', $q, '-h', '-1', '-W')
if ($user) { $sqlArgs += '-U', $user; if ($password) { $sqlArgs += '-P', $password } } else { $sqlArgs += '-E' }
if ($trustCert) { $sqlArgs += '-C' }
& sqlcmd @sqlArgs
