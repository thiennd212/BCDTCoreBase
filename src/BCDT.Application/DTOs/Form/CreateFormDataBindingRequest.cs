namespace BCDT.Application.DTOs.Form;

public class CreateFormDataBindingRequest
{
    public string BindingType { get; set; } = "Static";
    public string? SourceTable { get; set; }
    public string? SourceColumn { get; set; }
    public string? SourceCondition { get; set; }
    public string? ApiEndpoint { get; set; }
    public string? ApiMethod { get; set; }
    public string? ApiResponsePath { get; set; }
    public string? Formula { get; set; }
    public int? ReferenceEntityTypeId { get; set; }
    public string? ReferenceDisplayColumn { get; set; }
    public string? DefaultValue { get; set; }
    public string? TransformExpression { get; set; }
    public int CacheMinutes { get; set; }
    public bool IsActive { get; set; } = true;
}
