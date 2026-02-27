namespace BCDT.Application.DTOs.Data;

/// <summary>Kết quả file export báo cáo tổng hợp (Excel) theo kỳ báo cáo.</summary>
public class ExportSummaryFileDto
{
    public byte[] Content { get; set; } = Array.Empty<byte>();
    public string ContentType { get; set; } = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    public string FileName { get; set; } = "bao-cao-tong-hop.xlsx";
}
