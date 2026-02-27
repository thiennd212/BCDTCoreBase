# W16 - Do baseline performance (3 lan/API, trung binh ms)
# Require: API running at http://localhost:5080
$base = "http://localhost:5080"
$script:token = $null
$script:formId = $null
$script:sheetId = $null
$script:submissionId = $null
$script:dataSourceId = $null

function Get-ResponseMs($uri, $method = "GET", $headers = @{}, $body = $null) {
    $h = @{ "Content-Type" = "application/json" }
    foreach ($k in $headers.Keys) { $h[$k] = $headers[$k] }
    $params = @{ Uri = $uri; Method = $method; Headers = $h; TimeoutSec = 30 }
    if ($body) { $params.Body = $body }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $null = Invoke-RestMethod @params
    } catch {
        $sw.Stop()
        return [int](-1)
    }
    $sw.Stop()
    return [int]$sw.ElapsedMilliseconds
}

function Measure-Api($name, $uri, $method = "GET", $body = $null) {
    $h = @{ Authorization = "Bearer $script:token" }
    $r1 = Get-ResponseMs $uri $method $h $body
    $r2 = Get-ResponseMs $uri $method $h $body
    $r3 = Get-ResponseMs $uri $method $h $body
    if ($r1 -lt 0 -or $r2 -lt 0 -or $r3 -lt 0) {
        $avg = -1
    } else {
        $avg = [int](($r1 + $r2 + $r3) / 3)
    }
    $line = "$name | $r1 | $r2 | $r3 | $avg"
    Write-Host $line
    return @($r1, $r2, $r3, $avg)
}

# Check API
try {
    $null = Invoke-RestMethod -Uri "$base/health" -Method GET -TimeoutSec 5
} catch {
    Write-Output "ERROR: API chua chay tai $base. Chay: dotnet run --project src/BCDT.Api --launch-profile http"
    exit 1
}

# Login
$loginBody = '{"Username":"admin","Password":"Admin@123"}'
$login = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$script:token = $login.data.accessToken
if (-not $script:token) {
    Write-Output "ERROR: Login failed"
    exit 1
}

# Get form + sheet + submission IDs
$forms = Invoke-RestMethod -Uri "$base/api/v1/forms" -Headers @{ Authorization = "Bearer $script:token" } -Method GET
if ($forms.data.Count -gt 0) {
    $script:formId = $forms.data[0].id
    $fv = Invoke-RestMethod -Uri "$base/api/v1/forms/$($script:formId)/versions" -Headers @{ Authorization = "Bearer $script:token" } -Method GET
    if ($fv.data.Count -gt 0) {
        $sheets = Invoke-RestMethod -Uri "$base/api/v1/forms/$($script:formId)/sheets" -Headers @{ Authorization = "Bearer $script:token" } -Method GET
        if ($sheets.data.Count -gt 0) { $script:sheetId = $sheets.data[0].id }
    }
}
$subs = Invoke-RestMethod -Uri "$base/api/v1/submissions" -Headers @{ Authorization = "Bearer $script:token" } -Method GET
if ($subs.data.Count -gt 0) { $script:submissionId = $subs.data[0].id }
$ds = Invoke-RestMethod -Uri "$base/api/v1/data-sources" -Headers @{ Authorization = "Bearer $script:token" } -Method GET
if ($ds.data.Count -gt 0) { $script:dataSourceId = $ds.data[0].id }

Write-Output "formId=$script:formId sheetId=$script:sheetId submissionId=$script:submissionId dataSourceId=$script:dataSourceId"
Write-Output "API | L1(ms) | L2(ms) | L3(ms) | Avg(ms)"
Write-Output "----|--------|--------|--------|--------"

$results = @{}
$results["login"] = Measure-Api "POST /auth/login" "$base/api/v1/auth/login" "POST" $loginBody
$results["forms"] = Measure-Api "GET /forms" "$base/api/v1/forms"
$results["submissions"] = Measure-Api "GET /submissions" "$base/api/v1/submissions"
if ($script:submissionId) {
    $results["workbook-data"] = Measure-Api "GET /submissions/{id}/workbook-data" "$base/api/v1/submissions/$($script:submissionId)/workbook-data"
}
$results["dashboard"] = Measure-Api "GET /dashboard/admin/stats" "$base/api/v1/dashboard/admin/stats"
$results["data-sources"] = Measure-Api "GET /data-sources" "$base/api/v1/data-sources"
if ($script:dataSourceId) {
    $results["data-sources-columns"] = Measure-Api "GET /data-sources/{id}/columns" "$base/api/v1/data-sources/$($script:dataSourceId)/columns"
}
$results["filter-definitions"] = Measure-Api "GET /filter-definitions" "$base/api/v1/filter-definitions"
if ($script:formId -and $script:sheetId) {
    $results["placeholder-occurrences"] = Measure-Api "GET /placeholder-occurrences" "$base/api/v1/forms/$($script:formId)/sheets/$($script:sheetId)/placeholder-occurrences"
    $results["dynamic-column-regions"] = Measure-Api "GET /dynamic-column-regions" "$base/api/v1/forms/$($script:formId)/sheets/$($script:sheetId)/dynamic-column-regions"
    $results["placeholder-column-occurrences"] = Measure-Api "GET /placeholder-column-occurrences" "$base/api/v1/forms/$($script:formId)/sheets/$($script:sheetId)/placeholder-column-occurrences"
}

Write-Output "DONE"
