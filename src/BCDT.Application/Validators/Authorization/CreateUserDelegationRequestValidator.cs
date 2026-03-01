using BCDT.Application.DTOs.Authorization;
using FluentValidation;

namespace BCDT.Application.Validators.Authorization;

/// <summary>S4.2: FluentValidation cho CreateUserDelegationRequest.</summary>
public class CreateUserDelegationRequestValidator : AbstractValidator<CreateUserDelegationRequest>
{
    private static readonly string[] AllowedTypes = ["Full", "Partial"];

    public CreateUserDelegationRequestValidator()
    {
        RuleFor(x => x.FromUserId)
            .GreaterThan(0).WithMessage("FromUserId phải lớn hơn 0.");

        RuleFor(x => x.ToUserId)
            .GreaterThan(0).WithMessage("ToUserId phải lớn hơn 0.")
            .NotEqual(x => x.FromUserId).WithMessage("Người nhận ủy quyền không được trùng với người ủy quyền.");

        RuleFor(x => x.DelegationType)
            .NotEmpty().WithMessage("DelegationType không được để trống.")
            .Must(t => AllowedTypes.Contains(t)).WithMessage("DelegationType phải là 'Full' hoặc 'Partial'.");

        RuleFor(x => x.Permissions)
            .NotEmpty().WithMessage("Permissions bắt buộc khi DelegationType là Partial.")
            .When(x => x.DelegationType == "Partial");

        RuleFor(x => x.ValidFrom)
            .NotEmpty().WithMessage("ValidFrom không được để trống.");

        RuleFor(x => x.ValidTo)
            .NotEmpty().WithMessage("ValidTo không được để trống.")
            .GreaterThan(x => x.ValidFrom).WithMessage("ValidTo phải sau ValidFrom.");

        RuleFor(x => x.Reason)
            .MaximumLength(512).WithMessage("Reason tối đa 512 ký tự.")
            .When(x => x.Reason != null);
    }
}
