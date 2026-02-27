using BCDT.Api.Common;
using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services;
using BCDT.Application.Services.Data;
using BCDT.Application.Services.Workflow;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/submissions")]
[Authorize]
[Produces("application/json")]
public class SubmissionsController : ControllerBase
{
    private readonly IReportSubmissionService _submissionService;
    private readonly IReportPresentationService _presentationService;
    private readonly IBuildWorkbookFromSubmissionService _buildWorkbookService;
    private readonly ISubmissionExcelService _submissionExcelService;
    private readonly ISyncFromPresentationService _syncFromPresentationService;
    private readonly IWorkflowExecutionService _workflowExecutionService;
    private readonly IAggregationService _aggregationService;
    private readonly ISubmissionPdfService _submissionPdfService;
    private readonly ISubmissionDynamicIndicatorService _dynamicIndicatorService;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public SubmissionsController(IReportSubmissionService submissionService, IReportPresentationService presentationService, IBuildWorkbookFromSubmissionService buildWorkbookService, ISubmissionExcelService submissionExcelService, ISyncFromPresentationService syncFromPresentationService, IWorkflowExecutionService workflowExecutionService, IAggregationService aggregationService, ISubmissionPdfService submissionPdfService, ISubmissionDynamicIndicatorService dynamicIndicatorService, IAuditService auditService, ICurrentUserService currentUserService)
    {
        _submissionService = submissionService;
        _presentationService = presentationService;
        _buildWorkbookService = buildWorkbookService;
        _submissionExcelService = submissionExcelService;
        _syncFromPresentationService = syncFromPresentationService;
        _workflowExecutionService = workflowExecutionService;
        _aggregationService = aggregationService;
        _submissionPdfService = submissionPdfService;
        _dynamicIndicatorService = dynamicIndicatorService;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>Lấy danh sách submission. Filter: formDefinitionId, organizationId, reportingPeriodId, status, includeDeleted. Pagination: pageSize (max 500), pageNumber (khi có → trả meta totalCount, hasNext).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReportSubmissionDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiSuccessResponse<PagedResultDto<ReportSubmissionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] int? formDefinitionId,
        [FromQuery] int? organizationId,
        [FromQuery] int? reportingPeriodId,
        [FromQuery] string? status,
        [FromQuery] bool includeDeleted = false,
        [FromQuery] int? pageSize = null,
        [FromQuery] int? pageNumber = null,
        CancellationToken cancellationToken = default)
    {
        if (pageSize is > 0)
        {
            var paged = await _submissionService.GetListPagedAsync(formDefinitionId, organizationId, reportingPeriodId, status, includeDeleted, pageSize.Value, pageNumber ?? 1, cancellationToken);
            if (!paged.IsSuccess)
                return BadRequest(new ApiErrorResponse(paged.Code, paged.Message));
            return Ok(new ApiSuccessResponse<PagedResultDto<ReportSubmissionDto>>(paged.Data!));
        }
        var result = await _submissionService.GetListAsync(formDefinitionId, organizationId, reportingPeriodId, status, includeDeleted, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<ReportSubmissionDto>>(result.Data!));
    }

    /// <summary>Lấy submission theo Id.</summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportSubmissionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(long id, CancellationToken cancellationToken = default)
    {
        var result = await _submissionService.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == ApiErrorCodes.NotFound)
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        if (result.Data == null)
            return NotFound(new ApiErrorResponse(ApiErrorCodes.NotFound, "Submission không tồn tại."));
        return Ok(new ApiSuccessResponse<ReportSubmissionDto>(result.Data));
    }

    /// <summary>Tạo submission mới.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportSubmissionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateReportSubmissionRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _submissionService.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportSubmissionDto>(result.Data!));
    }

    /// <summary>Tạo hàng loạt submission (một bản ghi per organization).</summary>
    [HttpPost("bulk")]
    [ProducesResponseType(typeof(ApiSuccessResponse<BulkCreateSubmissionsResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> BulkCreate([FromBody] BulkCreateSubmissionsRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _submissionService.BulkCreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<BulkCreateSubmissionsResultDto>(result.Data!));
    }

    /// <summary>Cập nhật submission.</summary>
    [HttpPut("{id:long}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportSubmissionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateReportSubmissionRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _submissionService.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportSubmissionDto>(result.Data!));
    }

    /// <summary>Xóa submission (soft delete).</summary>
    [HttpDelete("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _submissionService.DeleteAsync(id, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Lấy presentation (Layer 1 JSON) của submission. Chưa có thì trả 200 với data = null (tránh 404 gây báo lỗi Console).</summary>
    [HttpGet("{id:long}/presentation")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportPresentationDto?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPresentation(long id, CancellationToken cancellationToken = default)
    {
        var result = await _presentationService.GetBySubmissionIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<ReportPresentationDto?>(result.Data));
    }

    /// <summary>Lấy danh sách chỉ tiêu động của submission (R4, R8).</summary>
    [HttpGet("{id:long}/dynamic-indicators")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReportDynamicIndicatorItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDynamicIndicators(long id, CancellationToken cancellationToken = default)
    {
        var result = await _dynamicIndicatorService.GetBySubmissionIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<ReportDynamicIndicatorItemDto>>(result.Data!));
    }

    /// <summary>Ghi đè danh sách chỉ tiêu động của submission (batch). RLS: submission thuộc đơn vị user.</summary>
    [HttpPut("{id:long}/dynamic-indicators")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> PutDynamicIndicators(long id, [FromBody] PutDynamicIndicatorsRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _dynamicIndicatorService.PutAsync(id, request ?? new PutDynamicIndicatorsRequest(), userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }

    /// <summary>Lấy dữ liệu workbook từ cấu trúc biểu mẫu và ReportDataRow (tiêu chí hàng cột theo đơn vị). Dùng khi cần load dữ liệu theo form + đơn vị thay vì chỉ từ presentation đã lưu.</summary>
    [HttpGet("{id:long}/workbook-data")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkbookFromSubmissionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetWorkbookData(long id, CancellationToken cancellationToken = default)
    {
        var result = await _buildWorkbookService.BuildAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkbookFromSubmissionDto>(result.Data!));
    }

    /// <summary>Tạo hoặc cập nhật presentation (upsert) cho submission.</summary>
    [HttpPut("{id:long}/presentation")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportPresentationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpsertPresentation(long id, [FromBody] CreateReportPresentationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var req = new CreateReportPresentationRequest
        {
            SubmissionId = id,
            WorkbookJson = request.WorkbookJson,
            WorkbookHash = request.WorkbookHash,
            FileSize = request.FileSize,
            SheetCount = request.SheetCount
        };
        var result = await _presentationService.UpsertBySubmissionIdAsync(id, req, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportPresentationDto>(result.Data!));
    }

    /// <summary>Tạo presentation mới cho submission (chỉ khi chưa có).</summary>
    [HttpPost("{id:long}/presentation")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportPresentationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreatePresentation(long id, [FromBody] CreateReportPresentationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var req = new CreateReportPresentationRequest
        {
            SubmissionId = id,
            WorkbookJson = request.WorkbookJson,
            WorkbookHash = request.WorkbookHash,
            FileSize = request.FileSize,
            SheetCount = request.SheetCount
        };
        var result = await _presentationService.CreateAsync(req, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportPresentationDto>(result.Data!));
    }

    /// <summary>Gửi submission (Draft → Submitted), tạo WorkflowInstance nếu form có cấu hình workflow.</summary>
    [HttpPost("{id:long}/submit")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowInstanceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Submit(long id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _workflowExecutionService.SubmitSubmissionAsync(id, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkflowInstanceDto>(result.Data!));
    }

    /// <summary>Lấy workflow instance của submission (nếu có).</summary>
    [HttpGet("{id:long}/workflow-instance")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowInstanceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetWorkflowInstance(long id, CancellationToken cancellationToken = default)
    {
        var result = await _workflowExecutionService.GetInstanceBySubmissionIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Submission chưa có workflow instance."));
        return Ok(new ApiSuccessResponse<WorkflowInstanceDto>(result.Data));
    }

    /// <summary>Upload file Excel cho submission: đọc theo FormColumnMapping, ghi ReportDataRow và ReportPresentation.</summary>
    [HttpPost("{id:long}/upload-excel")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiSuccessResponse<SubmissionUploadResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UploadExcel(long id, IFormFile? file, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "Vui lòng chọn file Excel."));
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ext != ".xlsx" && ext != ".xls")
            return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "Chỉ chấp nhận file .xlsx hoặc .xls."));

        var userId = _currentUserService.GetUserId() ?? -1;
        await using var stream = file.OpenReadStream();
        var result = await _submissionExcelService.ProcessUploadedExcelAsync(id, stream, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<SubmissionUploadResultDto>(result.Data!));
    }

    /// <summary>Đồng bộ ReportDataRow từ WorkbookJson đã lưu (sau khi nhập liệu web).</summary>
    [HttpPost("{id:long}/sync-from-presentation")]
    [ProducesResponseType(typeof(ApiSuccessResponse<SubmissionUploadResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SyncFromPresentation(long id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _syncFromPresentationService.SyncFromPresentationAsync(id, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<SubmissionUploadResultDto>(result.Data!));
    }

    /// <summary>Tính lại ReportSummary từ ReportDataRow cho submission.</summary>
    [HttpPost("{id:long}/aggregate")]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Aggregate(long id, CancellationToken cancellationToken = default)
    {
        var result = await _aggregationService.AggregateSubmissionAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Lịch sử audit (cell-level) của submission.</summary>
    [HttpGet("{id:long}/audit")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<AuditEntryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAudit(long id, CancellationToken cancellationToken = default)
    {
        var result = await _auditService.GetAuditHistoryAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<AuditEntryDto>>(result.Data!));
    }

    /// <summary>Xuất PDF cho submission.</summary>
    [HttpGet("{id:long}/pdf")]
    [ProducesResponseType(typeof(FileContentResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPdf(long id, CancellationToken cancellationToken = default)
    {
        var result = await _submissionPdfService.GeneratePdfAsync(id, cancellationToken);
        if (!result.IsSuccess || result.Data == null)
            return NotFound(new ApiErrorResponse(result.Code, result.Message));
        var fileName = $"submission-{id}.pdf";
        return File(result.Data, "application/pdf", fileName);
    }
}
