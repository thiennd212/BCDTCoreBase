namespace BCDT.Application.Common;

/// <summary>Giới hạn phân trang cho list API (production cả nước – R8/Prod-1).</summary>
public static class PagingConstants
{
    /// <summary>Giá trị tối đa cho pageSize khi gọi list API. Client gửi lớn hơn sẽ bị cap.</summary>
    public const int MaxPageSize = 500;
}
