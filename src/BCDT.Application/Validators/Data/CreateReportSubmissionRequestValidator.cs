using BCDT.Application.DTOs.Data;
using FluentValidation;

namespace BCDT.Application.Validators.Data;

/// <summary>Prod-5 (R5): FluentValidation cho CreateReportSubmissionRequest.</summary>
public class CreateReportSubmissionRequestValidator : AbstractValidator<CreateReportSubmissionRequest>
{
    public CreateReportSubmissionRequestValidator()
    {
        RuleFor(x => x.FormDefinitionId)
            .GreaterThan(0).WithMessage("FormDefinitionId phải lớn hơn 0.");
        RuleFor(x => x.FormVersionId)
            .GreaterThan(0).WithMessage("FormVersionId phải lớn hơn 0.");
        RuleFor(x => x.OrganizationId)
            .GreaterThan(0).WithMessage("OrganizationId phải lớn hơn 0.");
        RuleFor(x => x.ReportingPeriodId)
            .GreaterThan(0).WithMessage("ReportingPeriodId phải lớn hơn 0.");
        RuleFor(x => x.Status)
            .MaximumLength(50).WithMessage("Status tối đa 50 ký tự.");
    }
}
