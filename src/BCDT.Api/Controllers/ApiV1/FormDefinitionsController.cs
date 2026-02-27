using BCDT.Api.Common;
using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms")]
[Authorize]
public class FormDefinitionsController : ControllerBase
{
    private readonly IFormDefinitionService _formDefinitionService;
    private readonly IFormTemplateService _formTemplateService;
    private readonly ICurrentUserService _currentUserService;

    public FormDefinitionsController(IFormDefinitionService formDefinitionService, IFormTemplateService formTemplateService, ICurrentUserService currentUserService)
    {
        _formDefinitionService = formDefinitionService;
        _formTemplateService = formTemplateService;
        _currentUserService = currentUserService;
    }

    /// <summary>Lấy danh sách biểu mẫu. Filter: status, formType, includeInactive. Pagination: pageSize (max 500), pageNumber (khi có → trả meta totalCount, hasNext).</summary>
    [HttpGet]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormDefinitionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiSuccessResponse<PagedResultDto<FormDefinitionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] string? status,
        [FromQuery] string? formType,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int? pageSize = null,
        [FromQuery] int? pageNumber = null,
        CancellationToken cancellationToken = default)
    {
        if (pageSize is > 0)
        {
            var paged = await _formDefinitionService.GetListPagedAsync(status, formType, includeInactive, pageSize.Value, pageNumber ?? 1, cancellationToken);
            if (!paged.IsSuccess)
                return BadRequest(new ApiErrorResponse(paged.Code, paged.Message));
            return Ok(new ApiSuccessResponse<PagedResultDto<FormDefinitionDto>>(paged.Data!));
        }
        var result = await _formDefinitionService.GetListAsync(status, formType, includeInactive, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormDefinitionDto>>(result.Data!));
    }

    /// <summary>Tạo biểu mẫu từ file template Excel: chỉ cần upload file + nhập tên biểu mẫu; số sheet, cột, format/style trích xuất từ template.</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost("from-template")]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreateFromTemplate(
        [FromForm] IFormFile file,
        [FromForm] string name,
        [FromForm] string? code,
        CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new ApiErrorResponse("INVALID_FILE", "Vui lòng chọn file Excel (.xlsx)."));
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ext != ".xlsx")
            return BadRequest(new ApiErrorResponse("INVALID_FILE", "Chỉ chấp nhận file .xlsx."));
        if (string.IsNullOrWhiteSpace(name))
            return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "Tên biểu mẫu không được để trống."));

        var userId = _currentUserService.GetUserId() ?? 0;
        byte[] bytes;
        await using (var stream = file.OpenReadStream())
        using (var ms = new MemoryStream())
        {
            await stream.CopyToAsync(ms, cancellationToken);
            bytes = ms.ToArray();
        }

        var result = await _formDefinitionService.CreateFromTemplateAsync(bytes, file.FileName, name.Trim(), string.IsNullOrWhiteSpace(code) ? null : code.Trim(), userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDefinitionDto>(result.Data!));
    }

    /// <summary>Lấy biểu mẫu theo Id.</summary>
    [HttpGet("{id:int}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _formDefinitionService.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDefinitionDto>(result.Data!));
    }

    /// <summary>Lấy biểu mẫu theo Code.</summary>
    [HttpGet("code/{code}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByCode(string code, CancellationToken cancellationToken = default)
    {
        var result = await _formDefinitionService.GetByCodeAsync(code, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Biểu mẫu không tồn tại."));
        return Ok(new ApiSuccessResponse<FormDefinitionDto>(result.Data));
    }

    /// <summary>Lấy danh sách phiên bản của biểu mẫu.</summary>
    [HttpGet("{id:int}/versions")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormVersionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetVersions(int id, CancellationToken cancellationToken = default)
    {
        var result = await _formDefinitionService.GetVersionsAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormVersionDto>>(result.Data!));
    }

    /// <summary>Tải file Excel template từ Form Definition (sheets + columns). Query fillBinding=true để điền giá trị từ Data Binding (Static, Organization, System, …). Optional: organizationId, reportingPeriodId cho context.</summary>
    [HttpGet("{id:int}/template")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [Produces("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")]
    public async Task<IActionResult> GetTemplate(
        int id,
        [FromQuery] bool fillBinding = false,
        [FromQuery] int? organizationId = null,
        [FromQuery] int? reportingPeriodId = null,
        CancellationToken cancellationToken = default)
    {
        var context = fillBinding
            ? new ResolveContext
            {
                UserId = _currentUserService.GetUserId(),
                OrganizationId = organizationId,
                ReportingPeriodId = reportingPeriodId,
                CurrentDate = DateTime.UtcNow
            }
            : null;
        var result = await _formTemplateService.GetTemplateAsync(id, fillBinding, context, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        var bytes = result.Data!;
        var form = await _formDefinitionService.GetByIdAsync(id, cancellationToken);
        var fileName = form.IsSuccess ? $"{form.Data!.Code}_template.xlsx" : "form_template.xlsx";
        return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
    }

    /// <summary>Upload file Excel template. Hệ thống parse và lưu TemplateDisplayJson (Fortune-sheet) để dùng làm base hiển thị nhập liệu.</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost("{id:int}/template")]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UploadTemplate(int id, IFormFile? file, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new ApiErrorResponse("INVALID_FILE", "Vui lòng chọn file Excel (.xlsx)."));
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ext != ".xlsx")
            return BadRequest(new ApiErrorResponse("INVALID_FILE", "Chỉ chấp nhận file .xlsx."));
        await using var stream = file.OpenReadStream();
        var result = await _formTemplateService.UploadTemplateAsync(id, stream, file.FileName, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Lấy template display (JSON Fortune-sheet) để FE dùng làm base hiển thị nhập liệu. Trả về 204 nếu chưa có.</summary>
    [HttpGet("{id:int}/template-display")]
    [Produces("application/json")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> GetTemplateDisplay(int id, CancellationToken cancellationToken = default)
    {
        var result = await _formTemplateService.GetTemplateDisplayJsonAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (string.IsNullOrEmpty(result.Data))
            return NoContent();
        return Content(result.Data!, "application/json");
    }

    /// <summary>Tạo biểu mẫu mới.</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [Authorize(Policy = "Form.Edit")]
    [HttpPost]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateFormDefinitionRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _formDefinitionService.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDefinitionDto>(result.Data!));
    }

    /// <summary>Cập nhật biểu mẫu.</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{id:int}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateFormDefinitionRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _formDefinitionService.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDefinitionDto>(result.Data!));
    }

    /// <summary>Xóa biểu mẫu (soft delete).</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{id:int}")]
    [Produces("application/json")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _formDefinitionService.DeleteAsync(id, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }

    /// <summary>Clone biểu mẫu: copy toàn bộ cấu trúc (FormVersion, FormSheet, FormColumn, FormRow) sang biểu mẫu mới với Code và Name mới.</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost("{id:int}/clone")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Clone(int id, [FromBody] CloneFormDefinitionRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _formDefinitionService.CloneAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDefinitionDto>(result.Data!));
    }
}
