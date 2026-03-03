---
task_ref: "Task 2.4 – Backend Unit Tests (xUnit)"
agent_assignment: "Agent_Backend"
phase: "Phase_02_Sprint_1_Security_Quality"
memory_log_path: ".apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_4_Backend_Unit_Tests.md"
execution_type: single-step
---

# Task Assignment: Task 2.4 – Backend Unit Tests

## Mục tiêu

Tạo project `BCDT.Tests` với ≥ 15 unit tests cho 3 service quan trọng. `dotnet test` phải pass toàn bộ.

## Bối cảnh

- **Stack:** xUnit + Moq + EF Core InMemory
- **Solution file:** tại root (`BCDTCoreBase.sln` hoặc tương tự – kiểm tra trước)
- **Clean Architecture:** Test project chỉ reference `BCDT.Application` và `BCDT.Infrastructure`; không reference `BCDT.Api`
- **Pattern Result\<T\>:** Các service trả `Result<T>` – test phải assert `result.IsSuccess`, `result.Data`, `result.Code`

## Các việc cần làm

### 1. Tạo project

```
src/BCDT.Tests/BCDT.Tests.csproj
```

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit" Version="2.9.*" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.*" />
    <PackageReference Include="Moq" Version="4.20.*" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="8.0.*" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.11.*" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="../BCDT.Application/BCDT.Application.csproj" />
    <ProjectReference Include="../BCDT.Infrastructure/BCDT.Infrastructure.csproj" />
  </ItemGroup>
</Project>
```

Thêm project vào solution: `dotnet sln add src/BCDT.Tests/BCDT.Tests.csproj`

### 2. Tests cho FormDefinitionService (≥ 5 tests)

File: `src/BCDT.Tests/Services/FormDefinitionServiceTests.cs`

Cover:
- `CreateAsync` – thành công trả `IsSuccess = true` với FormDefinitionId hợp lệ
- `CreateAsync` – trùng tên (CONFLICT) trả `IsSuccess = false`, code = "CONFLICT"
- `GetByIdAsync` – tìm thấy trả đúng data
- `GetByIdAsync` – không tìm thấy trả `IsSuccess = false`, code = "NOT_FOUND"
- `GetAllAsync` – paginated trả đúng count

### 3. Tests cho WorkflowService / Submission state transitions (≥ 5 tests)

File: `src/BCDT.Tests/Services/WorkflowServiceTests.cs` (hoặc SubmissionWorkflowTests.cs)

Cover các state transition hợp lệ và không hợp lệ:
- Submit hợp lệ: Draft → Submitted thành công
- Submit không hợp lệ: Submitted → Submitted trả lỗi
- Approve: Submitted → Approved thành công
- Reject: Submitted → Rejected thành công
- Approve khi đã Approved → lỗi

### 4. Tests cho AuthService (≥ 5 tests)

File: `src/BCDT.Tests/Services/AuthServiceTests.cs`

Cover:
- `LoginAsync` – username không tồn tại → `IsSuccess = false`, code = "INVALID_CREDENTIALS" (hoặc tương đương)
- `LoginAsync` – sai password → `IsSuccess = false`
- `LoginAsync` – thành công → `IsSuccess = true`, có `AccessToken`, có `RefreshToken`
- `RefreshAsync` – token không tồn tại → `IsSuccess = false`
- `RefreshAsync` – token đã revoke → `IsSuccess = false`

### 5. Verify

```
dotnet test src/BCDT.Tests
```

Tất cả ≥ 15 tests phải pass. Ghi Memory Log vào `memory_log_path`.

## Output mong đợi

1. `src/BCDT.Tests/BCDT.Tests.csproj` tồn tại và reference đúng
2. ≥ 15 tests, tất cả pass
3. Memory Log ghi đầy đủ
