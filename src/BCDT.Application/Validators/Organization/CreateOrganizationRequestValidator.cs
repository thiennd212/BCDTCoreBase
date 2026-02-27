using BCDT.Application.DTOs.Organization;
using FluentValidation;

namespace BCDT.Application.Validators.Organization;

/// <summary>Prod-5 (R5): FluentValidation cho CreateOrganizationRequest.</summary>
public class CreateOrganizationRequestValidator : AbstractValidator<CreateOrganizationRequest>
{
    public CreateOrganizationRequestValidator()
    {
        RuleFor(x => x.Code)
            .NotEmpty().WithMessage("Mã đơn vị không được để trống.")
            .MaximumLength(50).WithMessage("Mã đơn vị tối đa 50 ký tự.");
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Tên đơn vị không được để trống.")
            .MaximumLength(500).WithMessage("Tên đơn vị tối đa 500 ký tự.");
        RuleFor(x => x.ShortName)
            .MaximumLength(100).WithMessage("Tên viết tắt tối đa 100 ký tự.");
        RuleFor(x => x.OrganizationTypeId)
            .GreaterThan(0).WithMessage("OrganizationTypeId phải lớn hơn 0.");
        RuleFor(x => x.ParentId)
            .GreaterThan(0).When(x => x.ParentId.HasValue)
            .WithMessage("ParentId phải lớn hơn 0 khi có giá trị.");
        RuleFor(x => x.Address)
            .MaximumLength(500).WithMessage("Địa chỉ tối đa 500 ký tự.");
        RuleFor(x => x.Phone)
            .MaximumLength(50).WithMessage("Số điện thoại tối đa 50 ký tự.");
        RuleFor(x => x.Email)
            .MaximumLength(256).WithMessage("Email tối đa 256 ký tự.");
        RuleFor(x => x.TaxCode)
            .MaximumLength(50).WithMessage("Mã số thuế tối đa 50 ký tự.");
        RuleFor(x => x.DisplayOrder)
            .GreaterThanOrEqualTo(0).WithMessage("DisplayOrder phải >= 0.");
    }
}
