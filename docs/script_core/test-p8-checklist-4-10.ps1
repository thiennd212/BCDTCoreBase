# P8 checklist bước 4-10: GET/POST data-sources, filter-definitions, placeholder-occurrences
$ErrorActionPreference = 'Stop'
$base = 'http://localhost:5080'

function Test-Step {
    param([string]$Name, [scriptblock]$Run)
    try {
        $Run.Invoke()
        Write-Host "  [$Name] Pass" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [$Name] Fail: $_" -ForegroundColor Red
        return $false
    }
}

$results = @{}
$script:dsId = $null
$script:filterId = $null
Write-Host "`n--- Login ---"
$loginBody = '{"username":"admin","password":"Admin@123"}'
$loginResp = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResp.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

# Bước 4: GET data-sources
$results['4'] = Test-Step '4.GET data-sources' {
    $r = Invoke-RestMethod -Uri "$base/api/v1/data-sources" -Headers $headers -Method GET
    if ($r.success -ne $true -or $null -eq $r.data) { throw "success=$($r.success), data null or not array" }
}

# Bước 5: POST data-source (code duy nhất để tránh 409 khi chạy lại)
$results['5'] = Test-Step '5.POST data-source' {
    $code = "DS_ORG_" + [Guid]::NewGuid().ToString("N").Substring(0,8)
    $body = "{`"code`":`"$code`",`"name`":`"Organization`",`"sourceType`":`"Table`",`"sourceRef`":`"BCDT_Organization`"}"
    $r = Invoke-RestMethod -Uri "$base/api/v1/data-sources" -Headers $headers -Method POST -Body $body -ContentType "application/json"
    if ($r.success -ne $true -or -not $r.data.id) { throw "expected 201 with id" }
    $script:dsId = $r.data.id
}

# Bước 6: GET data-sources/{id}/columns
$results['6'] = Test-Step '6.GET data-sources/{id}/columns' {
    if (-not $script:dsId) { throw "no dsId from step 5" }
    $r = Invoke-RestMethod -Uri "$base/api/v1/data-sources/$($script:dsId)/columns" -Headers $headers -Method GET
    if ($r.success -ne $true -or $null -eq $r.data) { throw "success=$($r.success)" }
    if ($r.data -isnot [array] -or $r.data.Count -eq 0) { throw "expected non-empty array of columns" }
}

# Bước 7: GET filter-definitions
$results['7'] = Test-Step '7.GET filter-definitions' {
    $r = Invoke-RestMethod -Uri "$base/api/v1/filter-definitions" -Headers $headers -Method GET
    if ($r.success -ne $true -or $null -eq $r.data) { throw "success=$($r.success)" }
}

# Bước 8: POST filter-definition (code duy nhất để tránh 409 khi chạy lại)
$results['8'] = Test-Step '8.POST filter-definition' {
    $code = "FD_TEST_" + [Guid]::NewGuid().ToString("N").Substring(0,8)
    $body = "{`"code`":`"$code`",`"name`":`"Test Filter`",`"logicalOperator`":`"AND`",`"conditions`":[{`"conditionOrder`":0,`"field`":`"Id`",`"operator`":`"Gt`",`"valueType`":`"Literal`",`"value`":`"0`"}]}"
    $r = Invoke-RestMethod -Uri "$base/api/v1/filter-definitions" -Headers $headers -Method POST -Body $body -ContentType "application/json"
    if ($r.success -ne $true -or -not $r.data.id) { throw "expected 201 with id" }
    $script:filterId = $r.data.id
}

# formId/sheetId hợp lệ: sheet 6 thuộc form 4
$formId = 4
$sheetId = 6
# FormDynamicRegionId=1 có FormSheetId=6
$regionId = 1

# Bước 9: GET placeholder-occurrences
$results['9'] = Test-Step '9.GET placeholder-occurrences' {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/placeholder-occurrences" -Headers $headers -Method GET
    if ($r.success -ne $true -or $null -eq $r.data) { throw "success=$($r.success)" }
}

# Bước 10: POST placeholder-occurrence
$results['10'] = Test-Step '10.POST placeholder-occurrence' {
    if (-not $script:filterId) { throw "no filterId from step 8" }
    $body = "{`"formDynamicRegionId`":$regionId,`"excelRowStart`":10,`"filterDefinitionId`":$($script:filterId),`"displayOrder`":0}"
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/placeholder-occurrences" -Headers $headers -Method POST -Body $body -ContentType "application/json"
    if ($r.success -ne $true -or -not $r.data.id) { throw "expected 201 with id" }
}

Write-Host "`n--- Kết quả P8 bước 4-10 ---"
$passed = ($results.GetEnumerator() | Where-Object { $_.Value }).Count
$failed = ($results.GetEnumerator() | Where-Object { -not $_.Value }).Count
foreach ($k in (4..10)) {
    $s = if ($results["$k"]) { "Pass" } else { "Fail" }
    Write-Host "  Bước $k : $s"
}
Write-Host "  Tổng: $passed Pass, $failed Fail"
if ($failed -gt 0) { exit 1 }
