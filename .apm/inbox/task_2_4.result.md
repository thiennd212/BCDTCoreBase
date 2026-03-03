---
task_ref: "Task 2.4 – Backend Unit Tests (xUnit)"
agent: Agent_Backend
status: DONE
timestamp: 2025-02-27
---

## Kết quả thực thi

- Đã tạo project **BCDT.Tests** (xUnit, Moq, EF Core InMemory), thêm vào solution.
- **FormDefinitionServiceTests**: 5 tests (CreateAsync success/conflict, GetByIdAsync found/not found, GetListPagedAsync count).
- **ReportSubmissionServiceTests**: 5 tests (Create Draft, GetById, UpdateAsync Submitted/Approved/Rejected) – dùng ReportSubmissionService thay WorkflowService vì không có service riêng.
- **AuthServiceTests**: 5 tests (Login user not found, wrong password, success; Refresh token not found, revoked).
- **Verify:** `dotnet test src/BCDT.Tests` → **15 passed**, 0 failed.

## Files đã thay đổi

- `src/BCDT.Tests/BCDT.Tests.csproj` – tạo mới (net8.0, refs Application + Infrastructure, packages xunit, Moq, EF InMemory, Test.Sdk)
- `src/BCDT.Tests/Services/FormDefinitionServiceTests.cs` – tạo mới
- `src/BCDT.Tests/Services/ReportSubmissionServiceTests.cs` – tạo mới
- `src/BCDT.Tests/Services/AuthServiceTests.cs` – tạo mới
- `BCDTCoreBase.sln` – thêm project BCDT.Tests
- `.apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_4_Backend_Unit_Tests.md` – ghi Memory Log

## Memory Log

Đã ghi đầy đủ theo Memory_Log_Guide vào `.apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_4_Backend_Unit_Tests.md`.

## Flags

- important_findings: false
- compatibility_issue: false
- ad_hoc_delegation: false

## Ghi chú cho Manager

- FormDefinitionService.GetByIdAsync hiện trả `Result.Ok(null)` khi không tìm thấy, không trả NOT_FOUND; test phản ánh hành vi hiện tại.
- Workflow/state transitions được test qua ReportSubmissionService.UpdateAsync (Draft → Submitted → Approved/Rejected); không có WorkflowService riêng trong codebase.
