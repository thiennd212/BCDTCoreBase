# B8 Form Sheet, Column, Data-binding, Column-mapping - Full test (API on http://localhost:5080)
$ErrorActionPreference = "Stop"
$base = "http://localhost:5080"
$results = @()
$formIdCreated = $null

# --- 1. Login ---
try {
    $loginResp = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"
    $token = $loginResp.data.accessToken
    $results += "1. Login: Pass"
} catch { $results += "1. Login: Fail - $_"; $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b8-checklist-result.txt"; exit 1 }

$headers = @{ Authorization = "Bearer $token" }

# --- 2. Get or create Form ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $formId = $r.data[0].Id
        $results += "2. GET forms (use first): Pass (formId=$formId)"
    } else {
        $body = '{"code":"BC_B8_TEST","name":"B8 Test Form","formType":"Input","deadlineOffsetDays":5,"allowLateSubmission":true,"requireApproval":true,"autoCreateReport":false}'
        $r2 = Invoke-RestMethod -Uri "$base/api/v1/forms" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        $formId = $r2.data.Id
        $formIdCreated = $formId
        $results += "2. POST form (create for B8): Pass (formId=$formId)"
    }
} catch { $results += "2. Get/Create form: Fail - $_"; $formId = 0 }

if ($formId -eq 0) { $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b8-checklist-result.txt"; exit 1 }

# --- 3. Sheets: GET list (may be empty) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets" -Headers $headers
    if ($r.success -and $null -ne $r.data) { $results += "3. GET sheets list: Pass" } else { $results += "3. GET sheets list: Fail" }
} catch { $results += "3. GET sheets list: Fail - $_" }

# --- 4. Sheets: POST create ---
try {
    $body = '{"sheetIndex":0,"sheetName":"Sheet1","displayName":"Data Sheet","isDataSheet":true,"isVisible":true,"displayOrder":0}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0 -and $r.data.SheetName -eq "Sheet1") {
        $results += "4. POST sheet: Pass"
        $sheetId = $r.data.Id
    } else { $results += "4. POST sheet: Fail"; $sheetId = 0 }
} catch { $results += "4. POST sheet: Fail - $_"; $sheetId = 0 }

if ($sheetId -eq 0) {
    $results += "4b. Skip remaining (no sheetId). Deploy B8: stop API, dotnet build, start API."
    $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b8-checklist-result.txt"
    $results
    exit 1
}

# --- 5. Sheets: GET by id ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId" -Headers $headers
    if ($r.success -and $r.data.Id -eq $sheetId) { $results += "5. GET sheet by id: Pass" } else { $results += "5. GET sheet by id: Fail" }
} catch { $results += "5. GET sheet by id: Fail - $_" }

# --- 6. Sheets: PUT update ---
try {
    $body = '{"sheetIndex":0,"sheetName":"Sheet1","displayName":"Data Sheet (updated)","isDataSheet":true,"isVisible":true,"displayOrder":0}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId" -Method PUT -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.DisplayName -like "*updated*") { $results += "6. PUT sheet: Pass" } else { $results += "6. PUT sheet: Fail" }
} catch { $results += "6. PUT sheet: Fail - $_" }

# --- 7. Columns: GET list (may be empty) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns" -Headers $headers
    if ($r.success -and $null -ne $r.data) { $results += "7. GET columns list: Pass" } else { $results += "7. GET columns list: Fail" }
} catch { $results += "7. GET columns list: Fail - $_" }

# --- 8. Columns: POST create ---
try {
    $body = '{"columnCode":"COL_A","columnName":"Ma","excelColumn":"A","dataType":"Text","isRequired":false,"isEditable":true,"isHidden":false,"displayOrder":0}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0 -and $r.data.ColumnCode -eq "COL_A") {
        $results += "8. POST column: Pass"
        $columnId = $r.data.Id
    } else { $results += "8. POST column: Fail"; $columnId = 0 }
} catch { $results += "8. POST column: Fail - $_"; $columnId = 0 }

if ($columnId -eq 0) { $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b8-checklist-result.txt"; exit 1 }

# --- 9. Columns: GET by id ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId" -Headers $headers
    if ($r.success -and $r.data.Id -eq $columnId) { $results += "9. GET column by id: Pass" } else { $results += "9. GET column by id: Fail" }
} catch { $results += "9. GET column by id: Fail - $_" }

# --- 10. Columns: PUT update ---
try {
    $body = '{"columnCode":"COL_A","columnName":"Ma (updated)","excelColumn":"A","dataType":"Text","isRequired":false,"isEditable":true,"isHidden":false,"displayOrder":0}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId" -Method PUT -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.ColumnName -like "*updated*") { $results += "10. PUT column: Pass" } else { $results += "10. PUT column: Fail" }
} catch { $results += "10. PUT column: Fail - $_" }

# --- 11. Data-binding: GET (expect 404 when not set) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/data-binding" -Headers $headers
    $results += "11. GET data-binding (no config): Pass (got 200 with data)"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) { $results += "11. GET data-binding (expect 404): Pass" }
    else { $results += "11. GET data-binding: Fail - $_" }
}

# --- 12. Data-binding: POST create ---
try {
    $body = '{"bindingType":"Static","defaultValue":"N/A","cacheMinutes":0,"isActive":true}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/data-binding" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0 -and $r.data.BindingType -eq "Static") { $results += "12. POST data-binding: Pass" } else { $results += "12. POST data-binding: Fail" }
} catch { $results += "12. POST data-binding: Fail - $_" }

# --- 13. Data-binding: GET (now should have data) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/data-binding" -Headers $headers
    if ($r.success -and $r.data.FormColumnId -eq $columnId) { $results += "13. GET data-binding: Pass" } else { $results += "13. GET data-binding: Fail" }
} catch { $results += "13. GET data-binding: Fail - $_" }

# --- 14. Data-binding: PUT update ---
try {
    $body = '{"bindingType":"Static","defaultValue":"Updated default","cacheMinutes":5,"isActive":true}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/data-binding" -Method PUT -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.DefaultValue -eq "Updated default") { $results += "14. PUT data-binding: Pass" } else { $results += "14. PUT data-binding: Fail" }
} catch { $results += "14. PUT data-binding: Fail - $_" }

# --- 15. Column-mapping: GET (expect 404 when not set) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/column-mapping" -Headers $headers
    $results += "15. GET column-mapping (no config): Pass (got 200)"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) { $results += "15. GET column-mapping (expect 404): Pass" }
    else { $results += "15. GET column-mapping: Fail - $_" }
}

# --- 16. Column-mapping: POST create ---
try {
    $body = '{"targetColumnName":"TextValue1","targetColumnIndex":0,"aggregateFunction":null}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/column-mapping" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0 -and $r.data.TargetColumnName -eq "TextValue1") { $results += "16. POST column-mapping: Pass" } else { $results += "16. POST column-mapping: Fail" }
} catch { $results += "16. POST column-mapping: Fail - $_" }

# --- 17. Column-mapping: GET ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/column-mapping" -Headers $headers
    if ($r.success -and $r.data.FormColumnId -eq $columnId) { $results += "17. GET column-mapping: Pass" } else { $results += "17. GET column-mapping: Fail" }
} catch { $results += "17. GET column-mapping: Fail - $_" }

# --- 18. Column-mapping: PUT update ---
try {
    $body = '{"targetColumnName":"TextValue2","targetColumnIndex":1,"aggregateFunction":"SUM"}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/column-mapping" -Method PUT -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.TargetColumnName -eq "TextValue2") { $results += "18. PUT column-mapping: Pass" } else { $results += "18. PUT column-mapping: Fail" }
} catch { $results += "18. PUT column-mapping: Fail - $_" }

# --- 19. POST sheet duplicate SheetIndex (expect 409) ---
try {
    $body = '{"sheetIndex":0,"sheetName":"Sheet0Dup","isDataSheet":true,"isVisible":true,"displayOrder":0}'
    Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    $results += "19. POST sheet duplicate SheetIndex (expect 409): Fail - expected Conflict"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) { $results += "19. POST sheet duplicate SheetIndex (expect 409): Pass" }
    else { $results += "19. POST sheet duplicate SheetIndex: Fail - $_" }
}

# --- 20. POST column duplicate ColumnCode (expect 409) ---
try {
    $body = '{"columnCode":"COL_A","columnName":"Other","excelColumn":"B","dataType":"Text","displayOrder":1}'
    Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    $results += "20. POST column duplicate ColumnCode (expect 409): Fail - expected Conflict"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) { $results += "20. POST column duplicate ColumnCode (expect 409): Pass" }
    else { $results += "20. POST column duplicate ColumnCode: Fail - $_" }
}

# --- 21. DELETE data-binding ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/data-binding" -Method DELETE -Headers $headers
    if ($r.success) { $results += "21. DELETE data-binding: Pass" } else { $results += "21. DELETE data-binding: Fail" }
} catch { $results += "21. DELETE data-binding: Fail - $_" }

# --- 22. DELETE column-mapping ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId/column-mapping" -Method DELETE -Headers $headers
    if ($r.success) { $results += "22. DELETE column-mapping: Pass" } else { $results += "22. DELETE column-mapping: Fail" }
} catch { $results += "22. DELETE column-mapping: Fail - $_" }

# --- 23. DELETE column ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns/$columnId" -Method DELETE -Headers $headers
    if ($r.success) { $results += "23. DELETE column: Pass" } else { $results += "23. DELETE column: Fail" }
} catch { $results += "23. DELETE column: Fail - $_" }

# --- 24. DELETE sheet ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId" -Method DELETE -Headers $headers
    if ($r.success) { $results += "24. DELETE sheet: Pass" } else { $results += "24. DELETE sheet: Fail" }
} catch { $results += "24. DELETE sheet: Fail - $_" }

# --- 25. GET sheet 404 after delete ---
try {
    Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId" -Headers $headers
    $results += "25. GET sheet after delete (expect 404): Fail - expected 404"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) { $results += "25. GET sheet after delete (expect 404): Pass" }
    else { $results += "25. GET sheet after delete: Fail - $_" }
}

$results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b8-checklist-result.txt"
$results
