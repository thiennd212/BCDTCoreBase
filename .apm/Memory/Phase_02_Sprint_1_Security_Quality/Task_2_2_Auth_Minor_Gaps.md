---
agent: Agent_Backend
task_ref: Task 2.2 – Auth Minor Gaps (Permission Policy + Refresh Token Rotation)
status: Completed
important_findings: false
compatibility_issue: false
---

# Task Log: Task 2.2 – Auth Minor Gaps

## Summary

- **Gap 2 – Refresh Token Rotation:** Implemented trong `AuthService.RefreshAsync`: sau khi verify refresh token hợp lệ, tạo refresh token mới, revoke token cũ (`RevokedAt`, `ReplacedByToken`), lưu token mới vào `BCDT_RefreshToken`, trả `RefreshResponse.RefreshToken` mới (AuthController đã set qua Set-Cookie). Entity `RefreshToken` đã có `ReplacedByToken`; EF config bổ sung `ReplacedByToken` HasMaxLength(500).
- **Gap 1 – Permission-based Authorization:** Thêm `PermissionRequirement` (Application.Common.Authorization), `PermissionAuthorizationHandler` (Infrastructure.Authorization) kiểm tra UserId → UserRole → RolePermission → Permission.Code; đăng ký handler Scoped trong Program.cs; thêm policies `Form.View`, `Form.Edit`, `Submission.Submit`; áp dụng `Form.Edit` lên FormDefinitionsController POST Create và `Submission.Submit` lên SubmissionsController Submit.

## Output (files đã tạo/sửa)

- `src/BCDT.Application/Common/Authorization/PermissionRequirement.cs` – IAuthorizationRequirement theo permission code
- `src/BCDT.Application/BCDT.Application.csproj` – PackageReference Microsoft.AspNetCore.Authorization 8.0.11
- `src/BCDT.Infrastructure/Authorization/PermissionAuthorizationHandler.cs` – Handler query BCDT_UserRole/RolePermission/Permission
- `src/BCDT.Infrastructure/Services/AuthService.cs` – RefreshAsync: rotation (revoke old, create new, return new RefreshToken)
- `src/BCDT.Infrastructure/Persistence/AppDbContext.cs` – RefreshToken.ReplacedByToken HasMaxLength(500)
- `src/BCDT.Api/Program.cs` – AddScoped PermissionAuthorizationHandler; policies Form.View, Form.Edit, Submission.Submit
- `src/BCDT.Api/Controllers/ApiV1/FormDefinitionsController.cs` – [Authorize(Policy = "Form.Edit")] trên POST Create
- `src/BCDT.Api/Controllers/ApiV1/SubmissionsController.cs` – [Authorize(Policy = "Submission.Submit")] trên POST {id}/submit

## Verify

- Build: ✅ Pass (`dotnet build src/BCDT.Api`)
- Rotation: Không còn path nào giữ nguyên refresh_token cũ sau RefreshAsync; token cũ bị revoke, token mới trả qua response và AuthController set cookie

## Next Steps

- Agent_TechLead / Agent_Security review nếu cần; E2E với BE chạy để xác nhận login → refresh → cookie mới.
