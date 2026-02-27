using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/filter-definitions")]
[Authorize]
[Produces("application/json")]
public class FilterDefinitionsController : ControllerBase
{
    private readonly IFilterDefinitionService _service;

    public FilterDefinitionsController(IFilterDefinitionService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FilterDefinitionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<FilterDefinitionDto>>(result.Data!));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FilterDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Bộ lọc không tồn tại."));
        return Ok(new ApiSuccessResponse<FilterDefinitionDto>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FilterDefinitionDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] CreateFilterDefinitionRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { id = result.Data!.Id }, new ApiSuccessResponse<FilterDefinitionDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FilterDefinitionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateFilterDefinitionRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var uid) ? uid : -1;
        var result = await _service.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<FilterDefinitionDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
