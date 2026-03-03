---
agent: Agent_Backend
task_ref: "Task 2.4 – Backend Unit Tests (xUnit)"
status: Completed
ad_hoc_delegation: false
compatibility_issues: false
important_findings: false
---

# Task Log: Task 2.4 – Backend Unit Tests

## Summary

Đã tạo project `BCDT.Tests` với 15 unit tests cho FormDefinitionService, ReportSubmissionService (workflow/state transitions) và AuthService. Tất cả tests dùng xUnit, Moq, EF Core InMemory; `dotnet test` pass 15/15.

## Details

- Tạo `src/BCDT.Tests/BCDT.Tests.csproj` tham chiếu Application + Infrastructure; thêm package xUnit, Moq, Microsoft.EntityFrameworkCore.InMemory, Microsoft.NET.Test.Sdk. Không reference BCDT.Api (Clean Architecture).
- **FormDefinitionServiceTests** (5 tests): CreateAsync thành công trả FormDefinitionId hợp lệ; CreateAsync trùng Code trả CONFLICT; GetByIdAsync tìm thấy trả đúng data; GetByIdAsync không tìm thấy trả success với Data null (hiện tại service không trả NOT_FOUND cho GetById); GetListPagedAsync trả đúng count và items.
- **ReportSubmissionServiceTests** (5 tests): Thay WorkflowService bằng ReportSubmissionService (không có service riêng). Cover CreateAsync Draft; GetByIdAsync; UpdateAsync chuyển trạng thái Submitted, Approved, Rejected. Seed FormDefinition, FormVersion, Organization, ReportingPeriod qua helper.
- **AuthServiceTests** (5 tests): LoginAsync user không tồn tại / sai password → UNAUTHORIZED; LoginAsync thành công → AccessToken, RefreshToken; RefreshAsync token không tồn tại / token đã revoke → UNAUTHORIZED. Mock IJwtService và IOptions<JwtOptions>.

## Output

- `src/BCDT.Tests/BCDT.Tests.csproj` – project file, ImplicitUsings enable
- `src/BCDT.Tests/Services/FormDefinitionServiceTests.cs` – 5 tests
- `src/BCDT.Tests/Services/ReportSubmissionServiceTests.cs` – 5 tests
- `src/BCDT.Tests/Services/AuthServiceTests.cs` – 5 tests
- Solution: `dotnet sln add src/BCDT.Tests/BCDT.Tests.csproj` đã chạy

## Issues

None.

## Next Steps

Có thể mở rộng: test FormDefinitionService.GetByIdAsync khi không tìm thấy trả NOT_FOUND (nếu đổi spec); thêm test state machine Submit khi đã Submitted trả lỗi (nếu ReportSubmissionService bổ sung validation).
