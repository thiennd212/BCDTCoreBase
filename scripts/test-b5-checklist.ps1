# B5 Checklist 7.1 - Chay day du 12 buoc, bao Pass/Fail
# Buoc 1 (Build) va 2 (API chay) chay truoc: dotnet build; dotnet run --project src/BCDT.Api
$baseUrl = "http://localhost:5080"
$token = $null
$newUserId = $null
$ErrorActionPreference = "Stop"

Write-Host "=== B5 Checklist 7.1 (Buoc 1 Build, 2 API: chay truoc) ==="

# 3. Login
$loginBody = '{"username":"admin","password":"Admin@123"}'
$loginResp = Invoke-RestMethod -Uri "$baseUrl/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 10
if (-not $loginResp.success -or -not $loginResp.data.accessToken) { Write-Host "  Buoc 3 - Login : Fail - no token"; exit 1 }
$token = $loginResp.data.accessToken
Write-Host "  Buoc 3 - Login : Pass"

# 4. GET /users (co auth)
$h = @{ Authorization = "Bearer $token" }
$list = Invoke-RestMethod -Uri "$baseUrl/api/v1/users" -Headers $h -TimeoutSec 10
if (-not $list.success) { Write-Host "  Buoc 4 - GET /users (auth) : Fail"; exit 1 }
Write-Host "  Buoc 4 - GET /users (auth) : Pass"

# 5. GET /users khong token -> 401
try {
  Invoke-RestMethod -Uri "$baseUrl/api/v1/users" -TimeoutSec 5
  Write-Host "  Buoc 5 - GET /users (no token) : Fail - expected 401"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) { Write-Host "  Buoc 5 - GET /users (no token) : Pass (401)" }
  else { Write-Host "  Buoc 5 - GET /users (no token) : Fail - $_" }
}

# 6. GET /users/99999 -> 404
try {
  Invoke-RestMethod -Uri "$baseUrl/api/v1/users/99999" -Headers $h -TimeoutSec 5
  Write-Host "  Buoc 6 - GET /users/99999 : Fail - expected 404"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 404) { Write-Host "  Buoc 6 - GET /users/99999 : Pass (404)" }
  else { Write-Host "  Buoc 6 - GET /users/99999 : Fail - $_" }
}

# 7. POST create user
$postBody = '{"username":"user1","password":"Pass@123","email":"user1@test.local","fullName":"User One","isActive":true,"roleIds":[1],"organizationIds":[],"primaryOrganizationId":null}'
$create = Invoke-RestMethod -Uri "$baseUrl/api/v1/users" -Method POST -Body $postBody -ContentType "application/json" -Headers $h -TimeoutSec 10
if (-not $create.success -or -not $create.data.Id) { Write-Host "  Buoc 7 - POST /users : Fail - $($create | ConvertTo-Json -Compress)"; exit 1 }
$newUserId = $create.data.Id
Write-Host "  Buoc 7 - POST /users : Pass (id=$newUserId)"

# 8. GET /users/{id} sau khi tao
$get = Invoke-RestMethod -Uri "$baseUrl/api/v1/users/$newUserId" -Headers $h -TimeoutSec 5
if (-not $get.success -or $get.data.Username -ne "user1") { Write-Host "  Buoc 8 - GET /users/$newUserId : Fail"; exit 1 }
Write-Host "  Buoc 8 - GET /users/$newUserId : Pass"

# 9. PUT update
$putBody = '{"email":"user1@updated.local","fullName":"User One Updated","isActive":true,"roleIds":[1],"organizationIds":[],"primaryOrganizationId":null}'
$put = Invoke-RestMethod -Uri "$baseUrl/api/v1/users/$newUserId" -Method PUT -Body $putBody -ContentType "application/json" -Headers $h -TimeoutSec 10
if (-not $put.success -or $put.data.fullName -ne "User One Updated") { Write-Host "  Buoc 9 - PUT /users/$newUserId : Fail"; exit 1 }
Write-Host "  Buoc 9 - PUT /users/$newUserId : Pass"

# 10. DELETE
$del = Invoke-RestMethod -Uri "$baseUrl/api/v1/users/$newUserId" -Method DELETE -Headers $h -TimeoutSec 5
if (-not $del.success) { Write-Host "  Buoc 10 - DELETE /users/$newUserId : Fail"; exit 1 }
Write-Host "  Buoc 10 - DELETE /users/$newUserId : Pass"

# 11. GET /users/{id} sau khi xoa -> 404
try {
  Invoke-RestMethod -Uri "$baseUrl/api/v1/users/$newUserId" -Headers $h -TimeoutSec 5
  Write-Host "  Buoc 11 - GET /users/$newUserId (sau xoa) : Fail - expected 404"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 404) { Write-Host "  Buoc 11 - GET /users/$newUserId (sau xoa) : Pass (404)" }
  else { Write-Host "  Buoc 11 - GET /users/$newUserId (sau xoa) : Fail - $_" }
}

# 12. Postman collection JSON parse
$collPath = "docs/postman/BCDT-API.postman_collection.json"
$json = Get-Content $collPath -Raw | ConvertFrom-Json
if (-not $json.info.name) { Write-Host "  Buoc 12 - Postman JSON : Fail"; exit 1 }
Write-Host "  Buoc 12 - Postman JSON : Pass"

Write-Host "=== Ket thuc checklist ==="
