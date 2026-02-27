# B7 Form Definition - Checklist 7.1 (run when API is running on http://localhost:5080)
$ErrorActionPreference = "Stop"
$base = "http://localhost:5080"
$results = @()

# Login
try {
    $loginResp = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"
    $token = $loginResp.data.accessToken
    $results += "2. API + Login: Pass"
} catch { $results += "2. API + Login: Fail - $_"; $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b7-checklist-result.txt"; exit 1 }

$headers = @{ Authorization = "Bearer $token" }

# 3. GET /forms
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms" -Headers $headers
    if ($r.success -and $null -ne $r.data) { $results += "3. GET /forms: Pass" } else { $results += "3. GET /forms: Fail" }
} catch { $results += "3. GET /forms: Fail - $_" }

# 4. POST create
try {
    $body = '{"code":"BC_TEST_01","name":"Form test","formType":"Input","deadlineOffsetDays":5,"allowLateSubmission":true,"requireApproval":true,"autoCreateReport":false}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Id -gt 0 -and $r.data.Code -eq "BC_TEST_01" -and $r.data.Status -eq "Draft") {
        $results += "4. POST create: Pass"
        $formId = $r.data.Id
    } else { $results += "4. POST create: Fail"; $formId = 0 }
} catch { $results += "4. POST create: Fail - $_"; $formId = 0 }

if ($formId -eq 0) { $results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b7-checklist-result.txt"; exit 1 }

# 5. GET by id
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId" -Headers $headers
    if ($r.success -and $r.data.Id -eq $formId) { $results += "5. GET by id: Pass" } else { $results += "5. GET by id: Fail" }
} catch { $results += "5. GET by id: Fail - $_" }

# 6. GET by code
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/code/BC_TEST_01" -Headers $headers
    if ($r.success -and $r.data.Code -eq "BC_TEST_01") { $results += "6. GET by code: Pass" } else { $results += "6. GET by code: Fail" }
} catch { $results += "6. GET by code: Fail - $_" }

# 7. PUT update
try {
    $body = '{"code":"BC_TEST_01","name":"Bieu mau test (updated)","formType":"Input","deadlineOffsetDays":5,"allowLateSubmission":true,"requireApproval":true,"autoCreateReport":false,"status":"Draft","isActive":true}'
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId" -Method PUT -Headers $headers -Body $body -ContentType "application/json"
    if ($r.success -and $r.data.Name -like "*updated*") { $results += "7. PUT update: Pass" } else { $results += "7. PUT update: Fail" }
} catch { $results += "7. PUT update: Fail - $_" }

# 8. GET versions
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId/versions" -Headers $headers
    if ($r.success -and $null -ne $r.data) { $results += "8. GET versions: Pass" } else { $results += "8. GET versions: Fail" }
} catch { $results += "8. GET versions: Fail - $_" }

# 9. POST duplicate code -> 409
try {
    $body = '{"code":"BC_TEST_01","name":"Duplicate","formType":"Input","deadlineOffsetDays":5,"allowLateSubmission":true,"requireApproval":true,"autoCreateReport":false}'
    Invoke-RestMethod -Uri "$base/api/v1/forms" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    $results += "9. POST duplicate (expect 409): Fail - expected Conflict"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) { $results += "9. POST duplicate (expect 409): Pass" }
    else { $results += "9. POST duplicate (expect 409): Fail - $_" }
}

# 10. DELETE
try {
    $r = Invoke-RestMethod -Uri "$base/api/v1/forms/$formId" -Method DELETE -Headers $headers
    if ($r.success) { $results += "10. DELETE: Pass" } else { $results += "10. DELETE: Fail" }
} catch { $results += "10. DELETE: Fail - $_" }

$results | Out-File -FilePath "d:\00.AEQUITAS\MOF\BCDT\BCDTCoreBase\docs\script_core\b7-checklist-result.txt"
$results
