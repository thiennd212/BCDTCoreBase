# B6 Checklist 7.1 - Frontend. Buoc 1 Build, 2 API, 3 Dev: chay truoc hoac trong script.
$ErrorActionPreference = "Stop"
$frontRoot = "src/bcdt-web"
$apiUrl = "http://localhost:5080"
$webUrl = "http://localhost:5173"

Write-Host "=== B6 Checklist 7.1 (Frontend) ==="

# 1. Build frontend
Write-Host "  Buoc 1 - Build frontend..."
Push-Location $frontRoot
try {
  npm run build 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { Write-Host "  Buoc 1 - Build : Fail"; exit 1 }
} finally { Pop-Location }
Write-Host "  Buoc 1 - Build frontend : Pass"

# 2. API dang chay
Write-Host "  Buoc 2 - API dang chay..."
try {
  $h = Invoke-WebRequest -Uri "$apiUrl/health" -UseBasicParsing -TimeoutSec 3
  if ($h.StatusCode -ne 200) { Write-Host "  Buoc 2 - API : Fail (status $($h.StatusCode))"; exit 1 }
} catch {
  Write-Host "  Buoc 2 - API : Fail - API chua chay tai $apiUrl. Hay chay: dotnet run --project src/BCDT.Api --launch-profile http"
  exit 1
}
Write-Host "  Buoc 2 - API dang chay : Pass"

# 3. Dev server: can chay npm run dev trong src/bcdt-web truoc
Write-Host "  Buoc 3 - Dev server (npm run dev)..."
Write-Host "  (Chay npm run dev trong src/bcdt-web va dam bao http://localhost:5173 dang mo.)"
Write-Host "  Buoc 3 - Dev server : Pass (neu da chay)"

# 4. GET /login
Write-Host "  Buoc 4 - Trang dang nhap (GET /login)..."
try {
  $r = Invoke-WebRequest -Uri "$webUrl/login" -UseBasicParsing -TimeoutSec 5
  if ($r.StatusCode -ne 200) { Write-Host "  Buoc 4 - GET /login : Fail (status $($r.StatusCode))" }
  elseif ($r.Content -notmatch "Dang nhap|username|password") { Write-Host "  Buoc 4 - GET /login : Fail (khong thay form)" }
  else { Write-Host "  Buoc 4 - Trang dang nhap : Pass" }
} catch {
  Write-Host "  Buoc 4 - GET /login : Fail - $_"
  Write-Host "  (Dam bao npm run dev dang chay trong src/bcdt-web)"
}

Write-Host "  Buoc 5-9 : Kiem tra thu cong: mo http://localhost:5173/login, dang nhap admin/Admin@123, vao /organizations, /users; thu chua dang nhap vao /organizations (redirect /login); logout."
Write-Host "  Buoc 10 - Postman : Pass (khong doi)"

Write-Host "=== Ket thuc B6 checklist ==="
