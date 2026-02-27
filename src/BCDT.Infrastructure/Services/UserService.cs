using BCDT.Application.Common;
using BCDT.Application.DTOs.User;
using BCDT.Application.Services.User;
using BCDT.Domain.Entities.Authentication;
using BCDT.Domain.Entities.Authorization;
using BCDT.Domain.Entities.Organization;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class UserService : IUserService
{
    private readonly AppDbContext _db;

    public UserService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<Result<UserDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users
            .AsNoTracking()
            .Where(u => u.Id == id && !u.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);
        if (user == null)
            return Result.Ok<UserDto?>(null);

        var assignments = await (
            from ur in _db.UserRoles.AsNoTracking().Where(ur => ur.UserId == id && ur.IsActive)
            join r in _db.Roles.AsNoTracking() on ur.RoleId equals r.Id
            join o in _db.Organizations.AsNoTracking() on ur.OrganizationId equals o.Id into orgJoin
            from o in orgJoin.DefaultIfEmpty()
            select new UserRoleOrgItemDto
            {
                RoleId = r.Id,
                RoleCode = r.Code,
                RoleName = r.Name,
                OrganizationId = ur.OrganizationId,
                OrganizationCode = o != null ? o.Code : null,
                OrganizationName = o != null ? o.Name : null
            }
        ).ToListAsync(cancellationToken);

        var orgRows = await _db.UserOrganizations
            .AsNoTracking()
            .Where(uo => uo.UserId == id && uo.IsActive && uo.LeftAt == null)
            .Select(uo => new { uo.OrganizationId, uo.IsPrimary })
            .ToListAsync(cancellationToken);
        var primaryOrgId = orgRows.FirstOrDefault(x => x.IsPrimary)?.OrganizationId;

        return Result.Ok<UserDto?>(MapToDto(user, assignments, primaryOrgId));
    }

    public async Task<Result<List<UserDto>>> GetListAsync(int? organizationId, bool includeInactive, CancellationToken cancellationToken = default)
    {
        var query = _db.Users.AsNoTracking().Where(u => !u.IsDeleted);
        if (!includeInactive)
            query = query.Where(u => u.IsActive);
        if (organizationId.HasValue)
        {
            var userIdsInOrg = await _db.UserOrganizations
                .AsNoTracking()
                .Where(uo => uo.OrganizationId == organizationId.Value && uo.IsActive && uo.LeftAt == null)
                .Select(uo => uo.UserId)
                .Distinct()
                .ToListAsync(cancellationToken);
            query = query.Where(u => userIdsInOrg.Contains(u.Id));
        }

        var users = await query.OrderBy(u => u.Username).ToListAsync(cancellationToken);
        if (users.Count == 0)
            return Result.Ok(new List<UserDto>());

        // Batch load all roles and organizations to avoid N+1 query
        var userIds = users.Select(u => u.Id).ToList();

        var allRoles = await _db.UserRoles
            .AsNoTracking()
            .Where(ur => userIds.Contains(ur.UserId) && ur.IsActive)
            .Select(ur => new { ur.UserId, ur.RoleId })
            .ToListAsync(cancellationToken);
        var rolesByUser = allRoles
            .GroupBy(x => x.UserId)
            .ToDictionary(g => g.Key, g => g.Select(x => x.RoleId).Distinct().ToList());

        var allOrgs = await _db.UserOrganizations
            .AsNoTracking()
            .Where(uo => userIds.Contains(uo.UserId) && uo.IsActive && uo.LeftAt == null)
            .Select(uo => new { uo.UserId, uo.OrganizationId, uo.IsPrimary })
            .ToListAsync(cancellationToken);
        var orgsByUser = allOrgs
            .GroupBy(x => x.UserId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var dtos = new List<UserDto>();
        foreach (var u in users)
        {
            var roleIds = rolesByUser.TryGetValue(u.Id, out var r) ? r : new List<int>();
            var orgRows = orgsByUser.TryGetValue(u.Id, out var o) ? o : [];
            var organizationIds = orgRows.Select(x => x.OrganizationId).ToList();
            var primaryOrgId = orgRows.FirstOrDefault(x => x.IsPrimary)?.OrganizationId;
            dtos.Add(MapToDto(u, roleIds, organizationIds, primaryOrgId));
        }

        return Result.Ok(dtos);
    }

    public async Task<Result<UserDto>> CreateAsync(CreateUserRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (await _db.Users.AnyAsync(u => u.Username == request.Username && !u.IsDeleted, cancellationToken))
            return Result.Fail<UserDto>("CONFLICT", "Tên đăng nhập đã tồn tại.");
        if (await _db.Users.AnyAsync(u => u.Email == request.Email && !u.IsDeleted, cancellationToken))
            return Result.Fail<UserDto>("CONFLICT", "Email đã tồn tại.");

        var useRoleOrg = request.RoleOrgAssignments is { Count: > 0 };
        List<UserRoleOrgInputDto> roleOrgList = useRoleOrg ? request.RoleOrgAssignments! : new List<UserRoleOrgInputDto>();
        List<int> roleIdsForValidate = useRoleOrg ? roleOrgList.Select(x => x.RoleId).Distinct().ToList() : request.RoleIds;
        var orgIdsFromAssignments = useRoleOrg ? roleOrgList.Where(x => x.OrganizationId.HasValue).Select(x => x.OrganizationId!.Value).Distinct().ToList() : new List<int>();
        var organizationIdsForValidate = useRoleOrg ? orgIdsFromAssignments : request.OrganizationIds;

        foreach (var roleId in roleIdsForValidate)
        {
            var exists = await _db.Roles.AnyAsync(r => r.Id == roleId, cancellationToken);
            if (!exists)
                return Result.Fail<UserDto>("NOT_FOUND", $"Vai trò Id={roleId} không tồn tại.");
        }
        foreach (var orgId in organizationIdsForValidate)
        {
            var exists = await _db.Organizations.AnyAsync(o => o.Id == orgId && !o.IsDeleted, cancellationToken);
            if (!exists)
                return Result.Fail<UserDto>("NOT_FOUND", $"Đơn vị Id={orgId} không tồn tại.");
        }
        if (request.PrimaryOrganizationId.HasValue && !organizationIdsForValidate.Contains(request.PrimaryOrganizationId.Value))
            return Result.Fail<UserDto>("VALIDATION_FAILED", "PrimaryOrganizationId phải thuộc danh sách đơn vị của user.");

        var nowUtc = DateTime.UtcNow;
        var user = new User
        {
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Email = request.Email,
            FullName = request.FullName,
            Phone = request.Phone,
            AuthProvider = "BuiltIn",
            IsActive = request.IsActive,
            IsDeleted = false,
            CreatedAt = nowUtc,
            CreatedBy = createdBy
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync(cancellationToken);

        if (useRoleOrg)
        {
            foreach (var a in roleOrgList)
            {
                _db.UserRoles.Add(new UserRole
                {
                    UserId = user.Id,
                    RoleId = a.RoleId,
                    OrganizationId = a.OrganizationId,
                    ValidFrom = nowUtc,
                    IsActive = true,
                    GrantedBy = createdBy,
                    GrantedAt = nowUtc
                });
            }
            foreach (var orgId in orgIdsFromAssignments)
            {
                _db.UserOrganizations.Add(new UserOrganization
                {
                    UserId = user.Id,
                    OrganizationId = orgId,
                    IsPrimary = orgId == request.PrimaryOrganizationId,
                    IsActive = true,
                    JoinedAt = nowUtc,
                    CreatedAt = nowUtc,
                    CreatedBy = createdBy
                });
            }
        }
        else
        {
            foreach (var roleId in request.RoleIds.Distinct())
            {
                _db.UserRoles.Add(new UserRole
                {
                    UserId = user.Id,
                    RoleId = roleId,
                    OrganizationId = null,
                    ValidFrom = nowUtc,
                    IsActive = true,
                    GrantedBy = createdBy,
                    GrantedAt = nowUtc
                });
            }
            foreach (var orgId in request.OrganizationIds.Distinct())
            {
                _db.UserOrganizations.Add(new UserOrganization
                {
                    UserId = user.Id,
                    OrganizationId = orgId,
                    IsPrimary = orgId == request.PrimaryOrganizationId,
                    IsActive = true,
                    JoinedAt = nowUtc,
                    CreatedAt = nowUtc,
                    CreatedBy = createdBy
                });
            }
        }
        await _db.SaveChangesAsync(cancellationToken);

        if (useRoleOrg)
        {
            var assignments = await LoadRoleOrgAssignmentsAsync(user.Id, cancellationToken);
            var primaryOrgId = request.PrimaryOrganizationId;
            return Result.Ok(MapToDto(user, assignments, primaryOrgId));
        }
        return Result.Ok(MapToDto(user, request.RoleIds.Distinct().ToList(), request.OrganizationIds, request.PrimaryOrganizationId));
    }

    public async Task<Result<UserDto>> UpdateAsync(int id, UpdateUserRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted, cancellationToken);
        if (user == null)
            return Result.Fail<UserDto>("NOT_FOUND", "Người dùng không tồn tại.");
        if (await _db.Users.AnyAsync(u => u.Email == request.Email && u.Id != id && !u.IsDeleted, cancellationToken))
            return Result.Fail<UserDto>("CONFLICT", "Email đã được sử dụng bởi người dùng khác.");

        var useRoleOrg = request.RoleOrgAssignments is { Count: > 0 };
        List<UserRoleOrgInputDto> roleOrgList = useRoleOrg ? request.RoleOrgAssignments! : new List<UserRoleOrgInputDto>();
        var orgIdsFromAssignments = useRoleOrg ? roleOrgList.Where(x => x.OrganizationId.HasValue).Select(x => x.OrganizationId!.Value).Distinct().ToList() : new List<int>();
        var roleIdsForValidate = useRoleOrg ? roleOrgList.Select(x => x.RoleId).Distinct().ToList() : request.RoleIds;
        var organizationIdsForValidate = useRoleOrg ? orgIdsFromAssignments : request.OrganizationIds;

        foreach (var roleId in roleIdsForValidate)
        {
            var exists = await _db.Roles.AnyAsync(r => r.Id == roleId, cancellationToken);
            if (!exists)
                return Result.Fail<UserDto>("NOT_FOUND", $"Vai trò Id={roleId} không tồn tại.");
        }
        foreach (var orgId in organizationIdsForValidate)
        {
            var exists = await _db.Organizations.AnyAsync(o => o.Id == orgId && !o.IsDeleted, cancellationToken);
            if (!exists)
                return Result.Fail<UserDto>("NOT_FOUND", $"Đơn vị Id={orgId} không tồn tại.");
        }
        if (request.PrimaryOrganizationId.HasValue && !organizationIdsForValidate.Contains(request.PrimaryOrganizationId.Value))
            return Result.Fail<UserDto>("VALIDATION_FAILED", "PrimaryOrganizationId phải thuộc danh sách đơn vị của user.");

        user.Email = request.Email;
        user.FullName = request.FullName;
        user.Phone = request.Phone;
        user.IsActive = request.IsActive;
        user.UpdatedAt = DateTime.UtcNow;
        user.UpdatedBy = updatedBy;
        if (!string.IsNullOrWhiteSpace(request.NewPassword))
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);

        var nowUtc = DateTime.UtcNow;
        if (useRoleOrg)
        {
            var currentRoles = await _db.UserRoles.Where(ur => ur.UserId == id).ToListAsync(cancellationToken);
            foreach (var ur in currentRoles)
                _db.UserRoles.Remove(ur);
            foreach (var a in roleOrgList)
            {
                _db.UserRoles.Add(new UserRole
                {
                    UserId = id,
                    RoleId = a.RoleId,
                    OrganizationId = a.OrganizationId,
                    ValidFrom = nowUtc,
                    IsActive = true,
                    GrantedBy = updatedBy,
                    GrantedAt = nowUtc
                });
            }

            var currentOrgs = await _db.UserOrganizations.Where(uo => uo.UserId == id && uo.LeftAt == null).ToListAsync(cancellationToken);
            foreach (var uo in currentOrgs.Where(uo => !orgIdsFromAssignments.Contains(uo.OrganizationId)))
            {
                uo.LeftAt = nowUtc;
                uo.IsActive = false;
            }
            foreach (var orgId in orgIdsFromAssignments.Where(oid => !currentOrgs.Any(uo => uo.OrganizationId == oid)))
            {
                _db.UserOrganizations.Add(new UserOrganization
                {
                    UserId = id,
                    OrganizationId = orgId,
                    IsPrimary = orgId == request.PrimaryOrganizationId,
                    IsActive = true,
                    JoinedAt = nowUtc,
                    CreatedAt = nowUtc,
                    CreatedBy = updatedBy
                });
            }
            foreach (var uo in currentOrgs.Where(uo => orgIdsFromAssignments.Contains(uo.OrganizationId)))
                uo.IsPrimary = uo.OrganizationId == request.PrimaryOrganizationId;
        }
        else
        {
            var currentRoles = await _db.UserRoles.Where(ur => ur.UserId == id).ToListAsync(cancellationToken);
            var requestedRoleIds = request.RoleIds.Distinct().ToList();
            foreach (var ur in currentRoles.Where(ur => !requestedRoleIds.Contains(ur.RoleId) || ur.OrganizationId != null))
                _db.UserRoles.Remove(ur);
            foreach (var roleId in requestedRoleIds.Where(rid => !currentRoles.Any(ur => ur.RoleId == rid && ur.OrganizationId == null)))
            {
                _db.UserRoles.Add(new UserRole
                {
                    UserId = id,
                    RoleId = roleId,
                    OrganizationId = null,
                    ValidFrom = nowUtc,
                    IsActive = true,
                    GrantedBy = updatedBy,
                    GrantedAt = nowUtc
                });
            }

            var currentOrgs = await _db.UserOrganizations.Where(uo => uo.UserId == id && uo.LeftAt == null).ToListAsync(cancellationToken);
            var requestedOrgIds = request.OrganizationIds.Distinct().ToList();
            foreach (var uo in currentOrgs.Where(uo => !requestedOrgIds.Contains(uo.OrganizationId)))
            {
                uo.LeftAt = nowUtc;
                uo.IsActive = false;
            }
            foreach (var orgId in requestedOrgIds.Where(oid => !currentOrgs.Any(uo => uo.OrganizationId == oid)))
            {
                _db.UserOrganizations.Add(new UserOrganization
                {
                    UserId = id,
                    OrganizationId = orgId,
                    IsPrimary = orgId == request.PrimaryOrganizationId,
                    IsActive = true,
                    JoinedAt = nowUtc,
                    CreatedAt = nowUtc,
                    CreatedBy = updatedBy
                });
            }
            foreach (var uo in currentOrgs.Where(uo => requestedOrgIds.Contains(uo.OrganizationId)))
                uo.IsPrimary = uo.OrganizationId == request.PrimaryOrganizationId;
        }

        await _db.SaveChangesAsync(cancellationToken);

        if (useRoleOrg)
        {
            var assignments = await LoadRoleOrgAssignmentsAsync(id, cancellationToken);
            return Result.Ok(MapToDto(user, assignments, request.PrimaryOrganizationId));
        }
        var roleIds = await _db.UserRoles.AsNoTracking().Where(ur => ur.UserId == id && ur.IsActive).Select(ur => ur.RoleId).Distinct().ToListAsync(cancellationToken);
        var orgRows = await _db.UserOrganizations.AsNoTracking().Where(uo => uo.UserId == id && uo.IsActive && uo.LeftAt == null).Select(uo => new { uo.OrganizationId, uo.IsPrimary }).ToListAsync(cancellationToken);
        return Result.Ok(MapToDto(user, roleIds, orgRows.Select(x => x.OrganizationId).ToList(), orgRows.FirstOrDefault(x => x.IsPrimary)?.OrganizationId));
    }

    public async Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted, cancellationToken);
        if (user == null)
            return Result.Fail<object>("NOT_FOUND", "Người dùng không tồn tại.");
        user.IsDeleted = true;
        user.UpdatedAt = DateTime.UtcNow;
        user.UpdatedBy = deletedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(null!);
    }

    private async Task<List<UserRoleOrgItemDto>> LoadRoleOrgAssignmentsAsync(int userId, CancellationToken cancellationToken)
    {
        return await (
            from ur in _db.UserRoles.AsNoTracking().Where(ur => ur.UserId == userId && ur.IsActive)
            join r in _db.Roles.AsNoTracking() on ur.RoleId equals r.Id
            join o in _db.Organizations.AsNoTracking() on ur.OrganizationId equals o.Id into orgJoin
            from o in orgJoin.DefaultIfEmpty()
            select new UserRoleOrgItemDto
            {
                RoleId = r.Id,
                RoleCode = r.Code,
                RoleName = r.Name,
                OrganizationId = ur.OrganizationId,
                OrganizationCode = o != null ? o.Code : null,
                OrganizationName = o != null ? o.Name : null
            }
        ).ToListAsync(cancellationToken);
    }

    private static UserDto MapToDto(User u, List<int> roleIds, List<int> organizationIds, int? primaryOrganizationId) => new()
    {
        Id = u.Id,
        Username = u.Username,
        Email = u.Email,
        FullName = u.FullName,
        Phone = u.Phone,
        IsActive = u.IsActive,
        RoleIds = roleIds,
        OrganizationIds = organizationIds,
        PrimaryOrganizationId = primaryOrganizationId,
        RoleOrgAssignments = new List<UserRoleOrgItemDto>()
    };

    private static UserDto MapToDto(User u, List<UserRoleOrgItemDto> assignments, int? primaryOrganizationId)
    {
        var roleIds = assignments.Select(a => a.RoleId).Distinct().ToList();
        var organizationIds = assignments.Where(a => a.OrganizationId.HasValue).Select(a => a.OrganizationId!.Value).Distinct().ToList();
        return new UserDto
        {
            Id = u.Id,
            Username = u.Username,
            Email = u.Email,
            FullName = u.FullName,
            Phone = u.Phone,
            IsActive = u.IsActive,
            RoleIds = roleIds,
            OrganizationIds = organizationIds,
            PrimaryOrganizationId = primaryOrganizationId,
            RoleOrgAssignments = assignments
        };
    }
}
