---
name: bcdt-api-endpoint
description: Create a new API endpoint following BCDT REST conventions. Generates controller action, service method, and DTOs. Use when user says "tạo API", "thêm endpoint", "create API", or wants to add a new REST endpoint.
---

# BCDT API Endpoint Generator

Create new API endpoints following project conventions.

## Workflow

1. **Gather requirements**:
   - HTTP method (GET, POST, PUT, PATCH, DELETE)
   - Route path
   - Request/Response DTOs needed
   - Authorization requirements
   - Which service to call

2. **Generate code**:

### Controller Action
```csharp
// Add to existing controller or create new one

/// <summary>
/// {Description}
/// </summary>
/// <param name="id">The resource ID</param>
/// <returns>{ReturnDescription}</returns>
[HttpGet("{id}/export")]
[ProducesResponseType<ApiResponse<byte[]>>(200)]
[ProducesResponseType(404)]
[Authorize(Policy = "CanExport")]
public async Task<IActionResult> Export(int id, [FromQuery] ExportFormat format = ExportFormat.Pdf)
{
    var result = await _service.ExportAsync(id, format);
    
    if (!result.IsSuccess)
        return result.ToActionResult();
    
    return File(result.Value, GetContentType(format), $"report_{id}.{format.ToString().ToLower()}");
}
```

### Service Method
```csharp
// Interface
Task<Result<byte[]>> ExportAsync(int id, ExportFormat format);

// Implementation
public async Task<Result<byte[]>> ExportAsync(int id, ExportFormat format)
{
    var entity = await _repository.GetByIdAsync(id);
    if (entity is null)
        return Result.NotFound<byte[]>($"Entity {id} not found");
    
    var bytes = format switch
    {
        ExportFormat.Pdf => await _pdfService.GenerateAsync(entity),
        ExportFormat.Excel => await _excelService.GenerateAsync(entity),
        _ => throw new ArgumentOutOfRangeException(nameof(format))
    };
    
    return Result.Success(bytes);
}
```

### Request/Response DTOs (if needed)
```csharp
// Request
public record ExportRequest(
    [Required] int Id,
    ExportFormat Format = ExportFormat.Pdf
);

// Response (if not using file)
public record ExportResponse(
    string FileName,
    string ContentType,
    string Base64Data
);
```

## Endpoint Patterns

### List with Paging
```csharp
[HttpGet]
public async Task<ActionResult<ApiResponse<PagedList<{Entity}Dto>>>> GetList(
    [FromQuery] {Entity}Filter filter,
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20)
```

### Get Single
```csharp
[HttpGet("{id}")]
public async Task<ActionResult<ApiResponse<{Entity}Dto>>> Get(int id)
```

### Create
```csharp
[HttpPost]
public async Task<ActionResult<ApiResponse<{Entity}Dto>>> Create(
    [FromBody] Create{Entity}Request request)
{
    var result = await _service.CreateAsync(request);
    return result.IsSuccess 
        ? CreatedAtAction(nameof(Get), new { id = result.Value.Id }, ApiResponse.Success(result.Value))
        : result.ToActionResult();
}
```

### Update
```csharp
[HttpPut("{id}")]
public async Task<ActionResult<ApiResponse<{Entity}Dto>>> Update(
    int id, [FromBody] Update{Entity}Request request)
```

### Delete
```csharp
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id)
{
    var result = await _service.DeleteAsync(id);
    return result.IsSuccess ? NoContent() : result.ToActionResult();
}
```

### File Download (template)
```csharp
[HttpGet("{id}/template")]
[ProducesResponseType(StatusCodes.Status200OK)]
[ProducesResponseType(404)]
public async Task<IActionResult> GetTemplate(int id)
{
    var result = await _templateService.GenerateAsync(id);
    if (!result.IsSuccess) return result.ToActionResult();
    return File(result.Value.Stream, result.Value.ContentType, result.Value.FileName);
}
```

### File Upload (multipart)
```csharp
[HttpPost("{id}/upload-excel")]
[Consumes("multipart/form-data")]
[ProducesResponseType(typeof(ApiSuccessResponse<SubmissionUploadResultDto>), 200)]
[ProducesResponseType(400)]
public async Task<IActionResult> UploadExcel(long id, IFormFile? file, CancellationToken ct = default)
{
    if (file == null || file.Length == 0)
        return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "Vui lòng chọn file Excel."));
    var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
    if (ext != ".xlsx" && ext != ".xls")
        return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "Chỉ chấp nhận file .xlsx hoặc .xls."));
    await using var stream = file.OpenReadStream();
    var result = await _submissionExcelService.ProcessUploadedExcelAsync(id, stream, userId, ct);
    return result.IsSuccess ? Ok(ApiResponse.Success(result.Data)) : result.ToActionResult();
}
```

### Custom Action
```csharp
[HttpPost("{id}/submit")]
public async Task<ActionResult<ApiResponse<SubmissionDto>>> Submit(int id)

[HttpPost("{id}/approve")]
[Authorize(Policy = "CanApprove")]
public async Task<ActionResult<ApiResponse<WorkflowResultDto>>> Approve(
    int id, [FromBody] ApprovalRequest request)
```

## Response Codes
- 200: Success with data
- 201: Created (POST with Location header)
- 204: Success no content (DELETE)
- 400: Validation error
- 401: Unauthorized
- 403: Forbidden
- 404: Not found
- 409: Conflict (duplicate, concurrency)
- 500: Server error

## Verify / Build
- **Trước khi chạy `dotnet build`:** Kiểm tra và **hủy process BCDT.Api** nếu đang chạy để tránh lỗi file/DLL bị lock (PowerShell: `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue | Stop-Process -Force`). Sau đó mới build. Xem RUNBOOK mục 6.1.

## Checklist
- [ ] Controller action with proper HTTP method
- [ ] Swagger attributes ([ProducesResponseType])
- [ ] Authorization attribute if needed
- [ ] Service interface method
- [ ] Service implementation
- [ ] Request/Response DTOs
- [ ] Validation rules
- [ ] Trước build BE: đã hủy process BCDT.Api nếu đang chạy
