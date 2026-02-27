using BCDT.Application.DTOs.Auth;
using FluentValidation;

namespace BCDT.Application.Validators.Auth;

/// <summary>Prod-5 (R5): FluentValidation cho LoginRequest.</summary>
public class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Tên đăng nhập không được để trống.")
            .MaximumLength(256).WithMessage("Tên đăng nhập tối đa 256 ký tự.");
        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Mật khẩu không được để trống.")
            .MaximumLength(512).WithMessage("Mật khẩu tối đa 512 ký tự.");
    }
}
