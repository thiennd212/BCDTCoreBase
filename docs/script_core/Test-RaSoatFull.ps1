# Test script cho rà soát: Auth, Change password, Policy, NOT_FOUND->404
# Chạy khi API đang chạy: dotnet run --project src/BCDT.Api --launch-profile http
$baseUrl = "http://localhost:5080"
$results = @()

function Test-Step($name, $block) {
    try {
        & $block
        $script:results += "PASS: $name"
        return $true
    } catch {
        $script:results += "FAIL: $name - $($_.Exception.Message)"
        return $false
    }
}

# 1. Build (đã chạy riêng)
$results += "INFO: Build BE/FE đã chạy riêng"

# 2. Health
Test-Step "Health" {
    $r = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET -ErrorAction Stop
    if ($r.status -ne "healthy") { throw "status != healthy" }
} | Out-Null

# 3. Login
$loginBody = '{"username":"admin","password":"Admin@123"}'
$script:loginRes = $null
Test-Step "Login" {
    $script:loginRes = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginBody -ErrorAction Stop
    if (-not $script:loginRes.data.accessToken) { throw "no accessToken" }
} | Out-Null

$token = $script:loginRes.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

# 4. Me
Test-Step "Me" {
    $me = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/me" -Headers $headers -ErrorAction Stop
    if (-not $me.data.username) { throw "no user" }
} | Out-Null

# 5. Change password - wrong current -> 401
Test-Step "Change password wrong current -> 401" {
    $body = '{"currentPassword":"WrongPass","newPassword":"NewPass123"}'
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/change-password" -Method POST -Headers $headers -ContentType "application/json" -Body $body -ErrorAction Stop
        throw "Expected 401"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 401) { throw "Expected 401, got $($_.Exception.Response.StatusCode.value__)" }
    }
} | Out-Null

# 6. Change password - success (then revert for next run)
Test-Step "Change password success" {
    $body = '{"currentPassword":"Admin@123","newPassword":"TempPass123!"}'
    Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/change-password" -Method POST -Headers $headers -ContentType "application/json" -Body $body -ErrorAction Stop
} | Out-Null

# 7. Login with new password (sau khi đổi pass thành công)
$login2 = $null
try { $login2 = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"admin","password":"TempPass123!"}' -ErrorAction Stop } catch {}
if ($login2 -and $login2.data.accessToken) {
    $token2 = $login2.data.accessToken
    $headers2 = @{ Authorization = "Bearer $token2" }
    # Revert password
    $revertBody = '{"currentPassword":"TempPass123!","newPassword":"Admin@123"}'
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/change-password" -Method POST -Headers $headers2 -ContentType "application/json" -Body $revertBody -ErrorAction Stop
        $results += "PASS: Change password revert"
    } catch { $results += "FAIL: Change password revert - $($_.Exception.Message)" }
} else {
    $results += "FAIL: Login with new password (revert skipped)"
}

# Token mới sau revert (hoặc dùng lại token cũ nếu không đổi pass)
$token = $script:loginRes.data.accessToken
try {
    $reLogin = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginBody -ErrorAction Stop
    $token = $reLogin.data.accessToken
} catch {}
$headers = @{ Authorization = "Bearer $token" }

# 8. Users list (AdminManageUsers policy)
Test-Step "Users list 200" {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/v1/users" -Headers $headers -ErrorAction Stop
    if (-not $r.data) { throw "no data" }
} | Out-Null

# 9. User by id 999 -> 404
Test-Step "User 999 -> 404" {
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/users/999" -Headers $headers -ErrorAction Stop
        throw "Expected 404"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw "Expected 404, got $($_.Exception.Response.StatusCode.value__)" }
    }
} | Out-Null

# 10. Roles list (AdminManageRoles)
Test-Step "Roles list 200" {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/v1/roles" -Headers $headers -ErrorAction Stop
    if (-not $r.data) { throw "no data" }
} | Out-Null

# 11. Organizations list (AdminManageOrg)
Test-Step "Organizations list 200" {
    $r = Invoke-RestMethod -Uri "$baseUrl/api/v1/organizations" -Headers $headers -ErrorAction Stop
    if (-not $r.data) { throw "no data" }
} | Out-Null

# 12. Menu by id 99999 -> 404
Test-Step "Menu 99999 -> 404" {
    try {
        Invoke-RestMethod -Uri "$baseUrl/api/v1/menus/99999" -Headers $headers -ErrorAction Stop
        throw "Expected 404"
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw "Expected 404" }
    }
} | Out-Null

# 13. Refresh
Test-Step "Refresh" {
    $ref = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/refresh" -Method POST -ContentType "application/json" -Body ("{`"refreshToken`":`"" + $script:loginRes.data.refreshToken + "`"}") -ErrorAction Stop
    if (-not $ref.data.accessToken) { throw "no accessToken" }
} | Out-Null

$results | ForEach-Object { Write-Host $_ }
