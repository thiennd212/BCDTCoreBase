---
name: bcdt-test
description: Write unit and integration tests for BCDT following bcdt-testing rule. Use when user says "viết test", "unit test", "đạt coverage", "test cho", or wants to add tests for a service, controller, or component.
---

# BCDT Test Generator

Tạo unit test và integration test theo convention của dự án. Đọc rule [bcdt-testing.mdc](../../rules/bcdt-testing.mdc) trước khi sinh code.

## Workflow

1. **Xác định phạm vi:**
   - Backend: Unit test cho Service/Validator hay Integration test cho Controller?
   - Frontend: Unit test cho component/hook?
   - Cần test những scenario nào (success, not found, validation error, unauthorized)?

2. **Đọc rule bcdt-testing:** Naming `should_Behavior_When_Condition`, Arrange–Act–Assert, mock ở Application layer.

3. **Sinh test:**

### Backend – Unit test (Service)

- File: `tests/BCDT.Application.Tests/Services/{Module}/{ServiceName}Tests.cs` (hoặc `src/BCDT.Application.Tests/...` tùy cấu trúc).
- Mock: `IRepository`, dependency khác qua Moq/NSubstitute.
- Naming: `GetByIdAsync_ReturnsNotFound_WhenIdNotExists`, `CreateAsync_ReturnsSuccess_WhenValidRequest`.
- Assert: Result.IsSuccess, Result.Error, hoặc FluentAssertions.

```csharp
public class FormServiceTests
{
    private readonly Mock<IFormRepository> _repo;
    private readonly FormService _sut;

    public FormServiceTests() { _repo = new Mock<IFormRepository>(); _sut = new FormService(_repo.Object, ...); }

    [Fact]
    public async Task GetByIdAsync_ReturnsNotFound_WhenIdNotExists()
    {
        _repo.Setup(r => r.GetByIdAsync(999)).ReturnsAsync((FormDefinition?)null);
        var result = await _sut.GetAsync(999);
        result.IsSuccess.Should().BeFalse();
    }
}
```

### Backend – Unit test (Validator)

- File: `tests/BCDT.Application.Tests/Validators/{ValidatorName}Tests.cs`.
- Test: Valid request → no error; invalid (empty, max length, format) → HasErrorMessage.

### Backend – Integration test (Controller)

- Project: `BCDT.Api.Tests`; dùng `WebApplicationFactory<Program>`.
- Gửi HTTP request (GET/POST với body); assert status 200/404/400 và response body.

### Frontend – Component/hook test

- File: cùng thư mục component với suffix `.test.tsx` hoặc trong `__tests__/`.
- Vitest + React Testing Library: `render`, `screen.getByRole`/`getByLabelText`, `userEvent`.
- Test: render đúng, submit với data hợp lệ/invalid, loading/error state.

## Script test API (Submission + Upload Excel)

- **File:** `docs/script_core/test-submission-upload.ps1`. Test đầy đủ: login, POST/GET submissions, GET template, upload Excel (no file / .txt / .xlsx), GET presentation, duplicate 409.
- **Điều kiện:** API phải chạy trước: `dotnet run --project src/BCDT.Api --launch-profile http` (localhost:5080). Script kiểm tra `/health` trước; nếu không có API thì thoát với thông báo.
- **Kỳ vọng:** 10/10 Pass. Rule: [bcdt-testing.mdc](../../rules/bcdt-testing.mdc) (Script test API).

## Checklist

- [ ] Naming `should_Behavior_When_Condition`
- [ ] Arrange – Act – Assert
- [ ] Mock interface, không mock entity (trừ khi cần)
- [ ] Backend: xUnit, Moq/NSubstitute; Frontend: Vitest, React Testing Library
- [ ] Không test implementation detail
- [ ] Nếu test submission/upload: chạy API trước, dùng script test-submission-upload.ps1 để xác nhận 10/10 Pass
