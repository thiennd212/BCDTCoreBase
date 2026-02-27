using System.Text.Json.Serialization;

namespace BCDT.Api.Common;

/// <summary>
/// Response success chuẩn BCDT: { "success": true, "data": ... } (04.GIAI_PHAP_KY_THUAT mục 7).
/// HTTP: 200/201. Frontend dùng response.data.data.
/// </summary>
public record ApiSuccessResponse<T>([property: JsonPropertyName("data")] T Data)
{
    [JsonPropertyName("success")]
    public bool Success => true;
}

/// <summary>
/// Response lỗi chuẩn BCDT: { "success": false, "errors": [ { "code", "message", "field" } ] }.
/// HTTP status (400/404/409/401/403/500) chỉ loại lỗi; message hiển thị lấy từ errors[0].message, logic nghiệp vụ từ errors[0].code.
/// </summary>
public record ApiErrorResponse(string Code, string Message, string? Field = null)
{
    [JsonPropertyName("success")]
    public bool Success => false;

    [JsonPropertyName("errors")]
    public List<ApiError> Errors => new() { new ApiError(Code, Message, Field) };
}

public record ApiError(
    [property: JsonPropertyName("code")] string Code,
    [property: JsonPropertyName("message")] string Message,
    [property: JsonPropertyName("field")] string? Field);

/// <summary>Mã lỗi nghiệp vụ (code trong errors[0]). Dùng thống nhất để FE có thể phân nhánh (vd 404 → trống, CONFLICT → thông báo trùng).</summary>
public static class ApiErrorCodes
{
    public const string NotFound = "NOT_FOUND";
    public const string Conflict = "CONFLICT";
    public const string ValidationFailed = "VALIDATION_FAILED";
    public const string Unauthorized = "UNAUTHORIZED";
    public const string InvalidFile = "INVALID_FILE";
}
