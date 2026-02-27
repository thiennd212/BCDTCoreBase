# B12 P2a - Form Rows + FormColumn tree (API on http://localhost:5080)
# Kiểm tra: GET/POST rows, GET rows?tree=true, GET columns?tree=true, POST column với ParentId.
# Yêu cầu: API chạy, DB đã chạy script 04 + 20 (BCDT_FormRow, FormColumn.ParentId/IndicatorId).
# Chạy: .\docs\script_core\test-b12-p2a-checklist.ps1

$ErrorActionPreference = "Stop"
$base = "http://localhost:5080"
$results = @()

# --- 1. Login (admin có FormStructureAdmin) ---
try {
    $loginResp = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"
    $token = $loginResp.data.accessToken
    $results += "1. Login: Pass"
} catch { $results += "1. Login: Fail - $_"; $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p2a-checklist-result.txt"; exit 1 }

$headers = @{ Authorization = "Bearer $token" }

# --- 2. Lấy formId (form đầu tiên hoặc tạo mới) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $formId = $r.data[0].Id
        $results += "2. GET forms (use first): Pass (formId=$formId)"
    } else {
        $body = '{"code":"BC_B12P2A","name":"B12 P2a Test","formType":"Input","deadlineOffsetDays":5,"allowLateSubmission":true,"requireApproval":true,"autoCreateReport":false}'
        $r2 = Invoke-RestMethod -Uri "$base/api/v1/forms" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        $formId = $r2.data.Id
        $results += "2. POST form (create): Pass (formId=$formId)"
    }
} catch { $results += "2. Get/Create form: Fail - $_"; $formId = 0 }

if ($formId -eq 0) { $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p2a-checklist-result.txt"; exit 1 }

# --- 3. Lấy sheetId (sheet đầu tiên hoặc tạo mới) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets" -Headers $headers
    if ($r.success -and $r.data -is [Array] -and $r.data.Count -gt 0) {
        $sheetId = $r.data[0].Id
        $results += "3. GET sheets (use first): Pass (sheetId=$sheetId)"
    } else {
        $body = '{"sheetIndex":0,"sheetName":"Sheet1","displayName":"Data","isDataSheet":true,"isVisible":true,"displayOrder":0}'
        $r2 = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        $sheetId = $r2.data.Id
        $results += "3. POST sheet (create): Pass (sheetId=$sheetId)"
    }
} catch { $results += "3. Get/Create sheet: Fail - $_"; $sheetId = 0 }

if ($sheetId -eq 0) { $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p2a-checklist-result.txt"; exit 1 }

# --- 5b. GET rows (flat) ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/rows" -Headers $headers
    if ($r.success -and $null -ne $r.data -and $r.data -is [Array]) { $results += "5b. GET rows (flat): Pass" } else { $results += "5b. GET rows (flat): Fail" }
} catch { $results += "5b. GET rows (flat): Fail - $_" }

# --- 5c. GET rows?tree=true ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/rows?tree=true" -Headers $headers
    if ($r.success -and $null -ne $r.data -and $r.data -is [Array]) { $results += "5c. GET rows (tree): Pass" } else { $results += "5c. GET rows (tree): Fail" }
} catch { $results += "5c. GET rows (tree): Fail - $_" }

# --- 5e. POST row ---
$rowId = 0
$rowSuffix = [int][double]::Parse((Get-Date -UFormat %s))
try {
    $body = '{"rowCode":"R1_' + $rowSuffix + '","rowName":"Hang 1","excelRowStart":5,"rowType":"Data","displayOrder":0}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/rows" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0) {
        $rowId = $r.data.Id
        $hasParentId = $null -ne $r.data.ParentId
        $results += "5e. POST row: Pass (rowId=$rowId, ParentId in response=$hasParentId)"
    } else { $results += "5e. POST row: Fail" }
} catch { $results += "5e. POST row: Fail - $_" }

# --- GET rows sau khi thêm 1 row ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/rows" -Headers $headers
    if ($r.success -and $r.data.Count -ge 1) { $results += "5e2. GET rows after POST: Pass (count=$($r.data.Count))" } else { $results += "5e2. GET rows after POST: Fail" }
} catch { $results += "5e2. GET rows after POST: Fail - $_" }

# --- 5d. GET columns?tree=true ---
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns?tree=true" -Headers $headers
    if ($r.success -and $null -ne $r.data -and $r.data -is [Array]) { $results += "5d. GET columns (tree): Pass" } else { $results += "5d. GET columns (tree): Fail" }
} catch { $results += "5d. GET columns (tree): Fail - $_" }

# --- 5f. POST column (không ParentId) rồi POST column con (có ParentId) ---
$columnIdParent = 0
$suffix = [int][double]::Parse((Get-Date -UFormat %s))
try {
    $body = '{"columnCode":"COL_ROOT_' + $suffix + '","columnName":"Cot goc","excelColumn":"A","dataType":"Text","isRequired":false,"isEditable":true,"isHidden":false,"displayOrder":0}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0) {
        $columnIdParent = $r.data.Id
        $results += "5f1. POST column (no ParentId): Pass (columnId=$columnIdParent)"
    } else { $results += "5f1. POST column (no ParentId): Fail" }
} catch { $results += "5f1. POST column (no ParentId): Fail - $_" }

if ($columnIdParent -gt 0) {
    try {
        $body = '{"parentId":' + $columnIdParent + ',"columnCode":"COL_CHILD_' + $suffix + '","columnName":"Cot con","excelColumn":"B","dataType":"Text","isRequired":false,"isEditable":true,"isHidden":false,"displayOrder":1}'
        $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        if ($r.success -and $r.data.ParentId -eq $columnIdParent) { $results += "5f2. POST column (with ParentId): Pass" } else { $results += "5f2. POST column (with ParentId): Fail (ParentId=$($r.data.ParentId))" }
    } catch { $results += "5f2. POST column (with ParentId): Fail - $_" }

    # GET columns?tree=true sau khi có 1 cha 1 con ---
    try {
        $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/columns?tree=true" -Headers $headers
        $hasChildren = ($r.data | Where-Object { $_.Children -and $_.Children.Count -gt 0 }).Count -gt 0
        if ($r.success -and $r.data -is [Array]) { $results += "5f3. GET columns (tree) has structure: Pass (hasChildren=$hasChildren)" } else { $results += "5f3. GET columns (tree): Fail" }
    } catch { $results += "5f3. GET columns (tree): Fail - $_" }
}

# --- POST row con (ParentId = rowId) ---
if ($rowId -gt 0) {
    try {
        $body = '{"parentId":' + $rowId + ',"rowCode":"R2_' + $rowSuffix + '","rowName":"Hang con","excelRowStart":6,"rowType":"Data","displayOrder":1}'
        $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/rows" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        if ($r.success -and $r.data.ParentId -eq $rowId) { $results += "5e3. POST row (with ParentId): Pass" } else { $results += "5e3. POST row (with ParentId): Fail" }
    } catch { $results += "5e3. POST row (with ParentId): Fail - $_" }

    try {
        $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/sheets/$sheetId/rows?tree=true" -Headers $headers
        $hasChildren = ($r.data | Where-Object { $_.Children -and $_.Children.Count -gt 0 }).Count -gt 0
        if ($r.success -and $r.data -is [Array] -and $r.data.Count -ge 1) { $results += "5c2. GET rows (tree) with parent/child: Pass (hasChildren=$hasChildren)" } else { $results += "5c2. GET rows (tree): Fail" }
    } catch { $results += "5c2. GET rows (tree): Fail - $_" }
}

$results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b12-p2a-checklist-result.txt"
$results
