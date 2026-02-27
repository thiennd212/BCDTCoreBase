using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IDataSourceService
{
    Task<Result<List<DataSourceDto>>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Result<DataSourceDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<List<DataSourceColumnDto>>> GetColumnsAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<DataSourceDto>> CreateAsync(CreateDataSourceRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<DataSourceDto>> UpdateAsync(int id, UpdateDataSourceRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
