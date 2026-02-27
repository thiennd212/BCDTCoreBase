# B12 P4 mở rộng - Tự test workbook-data (pre-fill từ catalog + merge thứ tự)
# Yêu cầu: API chạy (http://localhost:5080), đã chạy seed_b12_p4_workbook_dynamic.sql (và có form+sheet, vd seed_mcp_1).
# Chạy: .\docs\script_core\test-b12-p4-workbook-dynamic.ps1

$ErrorActionPreference = "Stop"
$base = "http://localhost:5080"
$results = @()

# --- 1. Login (admin) ---
try {
    $loginResp = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"
    $token = $loginResp.data.accessToken
    $results += "1. Login: Pass"
} catch {
    $results += "1. Login: Fail - $_"
    $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
    $results
    exit 1
}

$headers = @{ Authorization = "Bearer $token" }

# --- 2. Form: ưu tiên TEST_EXCEL_ENTRY ---
$formId = 0
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $prefer = $r.data | Where-Object { $_.Code -eq "TEST_EXCEL_ENTRY" } | Select-Object -First 1
        $form = if ($prefer) { $prefer } else { $r.data[0] }
        $formId = $form.Id
        $results += "2. GET forms: Pass (formId=$formId, Code=$($form.Code))"
    } else {
        $results += "2. GET forms: Fail (no forms - chạy seed_mcp_1 hoặc tạo form trước)"
        $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
        $results
        exit 1
    }
} catch {
    $results += "2. GET forms: Fail - $_"
    $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
    $results
    exit 1
}

# --- 3. Sheet đầu tiên ---
$sheetId = 0
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $sheetId = $r.data[0].Id
        $results += "3. GET sheets: Pass (sheetId=$sheetId)"
    } else {
        $results += "3. GET sheets: Fail (no sheets)"
        $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
        $results
        exit 1
    }
} catch {
    $results += "3. GET sheets: Fail - $_"
    $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
    $results
    exit 1
}

# --- 4. Dynamic regions (phải có ít nhất 1 vùng gắn catalog) ---
$regionId = 0
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/dynamic-regions" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $withCatalog = $r.data | Where-Object { $_.IndicatorCatalogId -ne $null } | Select-Object -First 1
        $reg = if ($withCatalog) { $withCatalog } else { $r.data[0] }
        $regionId = $reg.Id
        $results += "4. GET dynamic-regions: Pass (regionId=$regionId, IndicatorCatalogId=$($reg.IndicatorCatalogId))"
    } else {
        $results += "4. GET dynamic-regions: Fail (empty - chạy seed_b12_p4_workbook_dynamic.sql trước)"
        $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
        $results
        exit 1
    }
} catch {
    $results += "4. GET dynamic-regions: Fail - $_"
    $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
    $results
    exit 1
}

# --- 5. Submission (cần ít nhất 1) ---
$submissionId = 0
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/submissions?formDefinitionId=$formId" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $submissionId = $r.data[0].Id
        $results += "5. GET submissions: Pass (submissionId=$submissionId)"
    } else {
        $results += "5. GET submissions: Fail (no submission - chạy seed_b12_p4_workbook_dynamic.sql hoặc seed_mcp_1)"
        $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
        $results
        exit 1
    }
} catch {
    $results += "5. GET submissions: Fail - $_"
    $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
    $results
    exit 1
}

# --- 6. GET workbook-data (Pre-fill - TC-11). Thu tu cay: 4 dong, dong 2 = con 1, dong 4 = con 2 (ASCII) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/submissions/$submissionId/workbook-data" -Headers $headers
    if (-not $r.success) {
        $results += "6. GET workbook-data (pre-fill): Fail (success=false)"
    } else {
        $sheets = $r.data.Sheets
        $dr = $sheets | ForEach-Object { $_.DynamicRegions } | Where-Object { $_ -ne $null } | Select-Object -First 1
        if ($null -eq $dr -or $null -eq $dr.Rows) {
            $results += "6. GET workbook-data (pre-fill): Fail (no DynamicRegions/Rows)"
        } else {
            $rows = $dr.Rows
            $names = @($rows | ForEach-Object { $_.IndicatorName })
            $ok = $rows.Count -ge 4 -and $names[1].IndexOf("con 1", [StringComparison]::OrdinalIgnoreCase) -ge 0 -and $names[3].IndexOf("con 2", [StringComparison]::OrdinalIgnoreCase) -ge 0
            if ($ok) {
                $results += "6. GET workbook-data (pre-fill): Pass (rows=$($rows.Count), con 1 @2, con 2 @4)"
            } else {
                $results += "6. GET workbook-data (pre-fill): Fail (ky vong 4 dong, con 1/con 2; thuc te: $($rows.Count))"
            }
        }
    }
} catch {
    $results += "6. GET workbook-data (pre-fill): Fail - $_"
}

# --- 7. PUT dynamic-indicators (giá trị mẫu, thứ tự trùng cây: gốc, con1, cháu, con2) ---
try {
    $items = @(
        @{ FormDynamicRegionId = $regionId; RowOrder = 0; IndicatorName = "Chỉ tiêu gốc"; IndicatorValue = "100" },
        @{ FormDynamicRegionId = $regionId; RowOrder = 1; IndicatorName = "Chỉ tiêu con 1"; IndicatorValue = "200" },
        @{ FormDynamicRegionId = $regionId; RowOrder = 2; IndicatorName = "Chỉ tiêu cháu"; IndicatorValue = "300" },
        @{ FormDynamicRegionId = $regionId; RowOrder = 3; IndicatorName = "Chỉ tiêu con 2"; IndicatorValue = "400" }
    )
    $body = @{ Items = $items } | ConvertTo-Json -Depth 5
    $r = Invoke-RestMethod -Uri "$base/api/v1/submissions/$submissionId/dynamic-indicators" -Method PUT -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success) {
        $results += "7. PUT dynamic-indicators: Pass"
    } else {
        $results += "7. PUT dynamic-indicators: Fail (success=false)"
    }
} catch {
    $results += "7. PUT dynamic-indicators: Fail - $_"
}

# --- 8. GET workbook-data lan 2 (Merge - TC-12: thu tu giu, gia tri da luu 100,200,300,400) ---
$expectedValues = @("100", "200", "300", "400")
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/submissions/$submissionId/workbook-data" -Headers $headers
    if (-not $r.success) {
        $results += "8. GET workbook-data (merge): Fail (success=false)"
    } else {
        $dr = $r.data.Sheets | ForEach-Object { $_.DynamicRegions } | Where-Object { $_ -ne $null } | Select-Object -First 1
        if ($null -eq $dr -or $null -eq $dr.Rows) {
            $results += "8. GET workbook-data (merge): Fail (no DynamicRegions/Rows)"
        } else {
            $rows = $dr.Rows
            $values = @($rows | ForEach-Object { $_.IndicatorValue })
            $matchOrder = $rows.Count -ge 4 -and $rows[1].IndicatorName.IndexOf("con 1", [StringComparison]::OrdinalIgnoreCase) -ge 0 -and $rows[3].IndicatorName.IndexOf("con 2", [StringComparison]::OrdinalIgnoreCase) -ge 0
            $matchVal = $true
            for ($i = 0; $i -lt [Math]::Min(4, $expectedValues.Count); $i++) {
                if ($i -ge $rows.Count -or [string]$rows[$i].IndicatorValue -ne $expectedValues[$i]) { $matchVal = $false; break }
            }
            if ($matchOrder -and $matchVal) {
                $results += "8. GET workbook-data (merge): Pass (thu tu + gia tri 100,200,300,400 dung)"
            } else {
                $results += "8. GET workbook-data (merge): Fail (order=$matchOrder, values=$matchVal; thuc te: $($values -join '|'))"
            }
        }
    }
} catch {
    $results += "8. GET workbook-data (merge): Fail - $_"
}

$results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p4-workbook-dynamic-result.txt"
$results
