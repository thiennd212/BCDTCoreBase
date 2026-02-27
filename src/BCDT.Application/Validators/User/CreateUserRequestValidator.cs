using BCDT.Application.DTOs.User;
using FluentValidation;

namespace BCDT.Application.Validators.User;

/// <summary>Prod-5 (R5): FluentValidation cho CreateUserRequest.</summary>
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Tên đăng nhập không được để trống.")
            .MaximumLength(256).WithMessage("Tên đăng nhập tối đa 256 ký tự.");
        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Mật khẩu không được để trống.")
            .MaximumLength(512).WithMessage("Mật khẩu tối đa 512 ký tự.");
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email không được để trống.")
            .MaximumLength(256).WithMessage("Email tối đa 256 ký tự.");
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Họ tên không được để trống.")
            .MaximumLength(256).WithMessage("Họ tên tối đa 256 ký tự.");
        RuleFor(x => x.Phone)
            .MaximumLength(50).WithMessage("Số điện thoại tối đa 50 ký tự.");
        RuleFor(x => x.PrimaryOrganizationId)
            .GreaterThan(0).When(x => x.PrimaryOrganizationId.HasValue)
            .WithMessage("PrimaryOrganizationId phải lớn hơn 0 khi có giá trị.");
    }
}
