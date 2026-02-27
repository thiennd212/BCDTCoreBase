# /bcdt-verify – Phase Verify: build + checklist + báo Pass/Fail

(Thuộc workflow Plan → Execute → Verify → Reflect; dùng khi chỉ chạy bước kiểm tra.)

1. **Build:** Tắt BCDT.Api (PowerShell: `Get-Process -Name "BCDT.Api" -EA SilentlyContinue | Stop-Process -Force`). `dotnet build src/BCDT.Api/BCDT.Api.csproj`. Nếu sửa FE: `npm run build` trong src/bcdt-web. Ghi **Build: Pass/Fail**.
2. **Checklist:** File đề xuất tương ứng → mục "Kiểm tra cho AI" hoặc *_TEST_CASES.md. Chạy từng bước; ghi Pass/Fail. API → rule **bcdt-postman-test-cases** (cập nhật Postman, xác thực JSON).
3. Báo: **1. Build: … 2. TC-01: … …** Chỉ báo xong khi tất cả Pass.

**Tự động:** Thực hiện không hỏi lại.
