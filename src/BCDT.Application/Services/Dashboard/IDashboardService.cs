using BCDT.Application.Common;
using BCDT.Application.DTOs.Dashboard;

namespace BCDT.Application.Services.Dashboard;

public interface IDashboardService
{
    Task<Result<DashboardAdminStatsDto>> GetAdminStatsAsync(int? userId, CancellationToken cancellationToken = default);
    Task<Result<DashboardUserTasksDto>> GetUserTasksAsync(int userId, CancellationToken cancellationToken = default);
}
