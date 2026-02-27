using BCDT.Application.DTOs.Form;
using FluentValidation;

namespace BCDT.Application.Validators.Form;

/// <summary>Prod-5 (R5): FluentValidation cho UpdateFormDefinitionRequest.</summary>
public class UpdateFormDefinitionRequestValidator : AbstractValidator<UpdateFormDefinitionRequest>
{
    public UpdateFormDefinitionRequestValidator()
    {
        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("Mã biểu mẫu không được để trống.")
            .MaximumLength(50).WithMessage("Mã biểu mẫu tối đa 50 ký tự.");
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Tên biểu mẫu không được để trống.")
            .MaximumLength(500).WithMessage("Tên biểu mẫu tối đa 500 ký tự.");
        RuleFor(x => x.Description)
            .MaximumLength(2000).WithMessage("Mô tả tối đa 2000 ký tự.");
        RuleFor(x => x.FormType)
            .MaximumLength(50).WithMessage("FormType tối đa 50 ký tự.");
        RuleFor(x => x.ReportingFrequencyId)
            .GreaterThan(0).When(x => x.ReportingFrequencyId.HasValue)
            .WithMessage("ReportingFrequencyId phải lớn hơn 0 khi có giá trị.");
        RuleFor(x => x.DeadlineOffsetDays)
            .GreaterThanOrEqualTo(0).WithMessage("DeadlineOffsetDays phải >= 0.");
        RuleFor(x => x.Status)
            .MaximumLength(50).WithMessage("Status tối đa 50 ký tự.");
    }
}
