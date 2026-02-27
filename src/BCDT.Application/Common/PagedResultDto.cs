namespace BCDT.Application.Common;

/// <summary>Kết quả list có phân trang chuẩn: items + meta (totalCount, pageNumber, pageSize, hasNext).</summary>
public record PagedResultDto<T>(
    IReadOnlyList<T> Items,
    int TotalCount,
    int PageNumber,
    int PageSize)
{
    public bool HasNext => PageNumber * PageSize < TotalCount;
}
