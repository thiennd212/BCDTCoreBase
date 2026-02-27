# Test Submission + Upload Excel - full cases
# Require: API running at http://localhost:5080
#   Chay API trong terminal khac: dotnet run --project src/BCDT.Api --launch-profile http
#   Form 1 phai co it nhat 1 sheet + columns + mapping, ReportingPeriod 2 hoac 3.
$base = "http://localhost:5080"
$script:results = @()

function Test-Step($name, $pass, $detail) {
    $status = if ($pass) { "Pass" } else { "Fail" }
    $script:results += "$name : $status - $detail"
    Write-Output "$name : $status - $detail"
}

# Upload file via multipart/form-data (works in PS 5.1 where -Form is not available)
function Invoke-UploadFile($uri, $headers, $filePath) {
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $ext = [System.IO.Path]::GetExtension($fileName).ToLowerInvariant()
    $contentType = if ($ext -eq ".xlsx") { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" } else { "application/octet-stream" }
    $header = [System.Text.Encoding]::UTF8.GetBytes(
        "--$boundary$LF" +
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"$LF" +
        "Content-Type: $contentType$LF$LF"
    )
    $footer = [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary--$LF")
    $body = New-Object byte[] ($header.Length + $fileBytes.Length + $footer.Length)
    [System.Buffer]::BlockCopy($header, 0, $body, 0, $header.Length)
    [System.Buffer]::BlockCopy($fileBytes, 0, $body, $header.Length, $fileBytes.Length)
    [System.Buffer]::BlockCopy($footer, 0, $body, $header.Length + $fileBytes.Length, $footer.Length)
    $allHeaders = @{ "Content-Type" = "multipart/form-data; boundary=$boundary" }
    foreach ($k in $headers.Keys) { $allHeaders[$k] = $headers[$k] }
    Invoke-RestMethod -Uri $uri -Method POST -Headers $allHeaders -Body $body
}

# 0) Check API is running
try {
    $null = Invoke-RestMethod -Uri "$base/health" -Method GET -TimeoutSec 3
    Write-Output "API OK at $base (process API dang chay)"
} catch {
    Write-Output "FAIL: API chua chay tai $base"
    Write-Output "Hay chay trong terminal khac: dotnet run --project src/BCDT.Api --launch-profile http"
    exit 1
}

# 1) Login
try {
    $login = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body '{"Username":"admin","Password":"Admin@123"}' -ContentType "application/json"
    $token = $login.data.accessToken
    $h = @{ Authorization = "Bearer $token" }
    Test-Step "1.Login" $true "token received"
} catch {
    Test-Step "1.Login" $false $_.Exception.Message
    $script:results | Out-File -FilePath "docs/script_core/submission-upload-result.txt" -Encoding utf8
    exit 1
}

# 2) POST create submission (form 1, version 1, org 1, period 3)
try {
    $body = '{"FormDefinitionId":1,"FormVersionId":1,"OrganizationId":1,"ReportingPeriodId":3,"Status":"Draft"}'
    $create = Invoke-RestMethod -Uri "$base/api/v1/submissions" -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } -Method POST -Body $body
    $sid = $create.data.id
    Test-Step "2.POST /submissions" $true "submissionId=$sid"
} catch {
    $sc = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    $msg = $_.ErrorDetails.Message
    if ($sc -eq 409 -or ($msg -and $msg -match "CONFLICT")) {
        $list = Invoke-RestMethod -Uri "$base/api/v1/submissions" -Headers $h -Method GET
        $sid = $list.data[0].id
        Test-Step "2.POST /submissions" $true "using existing submissionId=$sid"
    } else {
        Test-Step "2.POST /submissions" $false "StatusCode=$sc $msg"
        $sid = $null
    }
}

if (-not $sid) {
    $list = Invoke-RestMethod -Uri "$base/api/v1/submissions" -Headers $h -Method GET
    if ($list.data.Count -gt 0) { $sid = $list.data[0].id }
}
if (-not $sid) {
    Test-Step "2b.GET list for sid" $false "no submission available"
    $script:results | Out-File -FilePath "docs/script_core/submission-upload-result.txt" -Encoding utf8
    exit 1
}

# 3) GET list
$list = Invoke-RestMethod -Uri "$base/api/v1/submissions" -Headers $h -Method GET
Test-Step "3.GET /submissions" ($list.data.Count -ge 1) "count=$($list.data.Count)"

# 4) GET submission by id
try {
    $one = Invoke-RestMethod -Uri "$base/api/v1/submissions/$sid" -Headers $h -Method GET
    Test-Step "4.GET /submissions/$sid" $true "status=$($one.data.status)"
} catch {
    Test-Step "4.GET /submissions/$sid" $false $_.Exception.Response.StatusCode
}

# 5) GET template
try {
    $templatePath = [System.IO.Path]::GetTempFileName() + ".xlsx"
    Invoke-WebRequest -Uri "$base/api/v1/forms/1/template" -Headers $h -OutFile $templatePath -UseBasicParsing
    $sz = (Get-Item $templatePath).Length
    Test-Step "5.GET /forms/1/template" ($sz -gt 0) "size=$sz"
} catch {
    Test-Step "5.GET /forms/1/template" $false $_.Exception.Message
    $templatePath = $null
}

# 6) POST upload-excel without file (multipart empty)
$boundary = [System.Guid]::NewGuid().ToString()
$bodyEmpty = "--$boundary`r`nContent-Disposition: form-data; name=`"file`"; filename=`"`"`r`nContent-Type: application/octet-stream`r`n`r`n`r`n--$boundary--"
try {
    Invoke-RestMethod -Uri "$base/api/v1/submissions/$sid/upload-excel" -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "multipart/form-data; boundary=$boundary" } -Method POST -Body $bodyEmpty
    Test-Step "6.POST upload-excel (no file)" $false "expected 400"
} catch {
    $sc = [int]$_.Exception.Response.StatusCode
    Test-Step "6.POST upload-excel (no file)" ($sc -eq 400) "StatusCode=$sc"
}

# 7) POST upload-excel with .txt (expect 400 or 415)
$badPath = [System.IO.Path]::GetTempFileName() + ".txt"
Set-Content -Path $badPath -Value "not excel"
try {
    Invoke-UploadFile -Uri "$base/api/v1/submissions/$sid/upload-excel" -headers @{ Authorization = "Bearer $token" } -filePath $badPath
    Test-Step "7.POST upload-excel (.txt)" $false "expected 400"
} catch {
    $sc = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    $reject = ($sc -eq 400 -or $sc -eq 415)
    Test-Step "7.POST upload-excel (.txt)" $reject "StatusCode=$sc"
}
Remove-Item $badPath -Force -ErrorAction SilentlyContinue

# 8) POST upload-excel with valid xlsx
if ($templatePath -and (Test-Path $templatePath)) {
    try {
        $upload = Invoke-UploadFile -Uri "$base/api/v1/submissions/$sid/upload-excel" -headers @{ Authorization = "Bearer $token" } -filePath $templatePath
        Test-Step "8.POST upload-excel (xlsx)" $true "dataRowCount=$($upload.data.dataRowCount), sheetCount=$($upload.data.sheetCount)"
    } catch {
        $err = $_.ErrorDetails.Message; if (-not $err) { $err = $_.Exception.Message }
        Test-Step "8.POST upload-excel (xlsx)" $false $err
    }
    Remove-Item $templatePath -Force -ErrorAction SilentlyContinue
} else {
    Test-Step "8.POST upload-excel (xlsx)" $false "no template file"
}

# 9) GET presentation
try {
    $pres = Invoke-RestMethod -Uri "$base/api/v1/submissions/$sid/presentation" -Headers $h -Method GET
    Test-Step "9.GET /submissions/$sid/presentation" $true "fileSize=$($pres.data.fileSize)"
} catch {
    Test-Step "9.GET presentation" $false $_.Exception.Message
}

# 10) POST create same (1,1,1,3) -> expect 409
try {
    $body2 = '{"FormDefinitionId":1,"FormVersionId":1,"OrganizationId":1,"ReportingPeriodId":3,"Status":"Draft"}'
    Invoke-RestMethod -Uri "$base/api/v1/submissions" -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } -Method POST -Body $body2
    Test-Step "10.POST /submissions (duplicate)" $false "expected 409"
} catch {
    $sc = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    $is409 = ($sc -eq 409) -or ($_.ErrorDetails.Message -match "CONFLICT")
    Test-Step "10.POST /submissions (duplicate)" $is409 "StatusCode=$sc"
}

$passCount = ($script:results | Where-Object { $_ -match " : Pass " }).Count
$total = $script:results.Count
Write-Output "---"
Write-Output "Result: $passCount/$total Pass"
$script:results | Out-File -FilePath "docs/script_core/submission-upload-result.txt" -Encoding utf8
