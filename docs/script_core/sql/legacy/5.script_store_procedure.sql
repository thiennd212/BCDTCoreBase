/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM01_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 01
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_BM01_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'01NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1. Parse JSON -> Table variable
            ----------------------------------------------------------
            DECLARE @TableKeHoachDuAn TABLE
            (
                Id INT,
                DonViId INT,
                TieuChiId INT,
				TenTieuChi nvarchar(2000),
                SoThuTu INT,
                BieuMauId INT,
                CauTrucGUID UNIQUEIDENTIFIER,
                KCN_NamNgoai_KKT DECIMAL(24,3) NULL,
                KCN_VenBien DECIMAL(24,3) NULL,
                KCN_CuaKhau DECIMAL(24,3) NULL,
                KCN_ChuyenBiet DECIMAL(24,3) NULL,
                TongCong DECIMAL(24,3) NULL
            );

            INSERT INTO @TableKeHoachDuAn
            (
                Id, DonViId, TieuChiId, TenTieuChi, SoThuTu, BieuMauId, CauTrucGUID,
                KCN_NamNgoai_KKT, KCN_VenBien, KCN_CuaKhau, KCN_ChuyenBiet, TongCong
            )
            SELECT
                Id,
                DonViId,
                TieuChiId,
				TenTieuChi,
                SoThuTu,
                BieuMauId,
                CauTrucGUID,
                KCN_NamNgoai_KKT,
                KCN_VenBien,
                KCN_CuaKhau,
                KCN_ChuyenBiet,
                TongCong
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
                Id INT '$.Id',               
                DonViId INT '$.DonViId',
                TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi',
                SoThuTu INT '$.SoThuTu',
                BieuMauId INT '$.BieuMauId',
                CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                KCN_NamNgoai_KKT DECIMAL(24,3) '$.KCN_NamNgoai_KKT',
                KCN_VenBien DECIMAL(24,3) '$.KCN_VenBien',
                KCN_CuaKhau DECIMAL(24,3) '$.KCN_CuaKhau',
                KCN_ChuyenBiet DECIMAL(24,3) '$.KCN_ChuyenBiet',
                TongCong DECIMAL(24,3) '$.TongCong'
            );
			
			SELECT * FROM @TableKeHoachDuAn;
            ----------------------------------------------------------
            -- 2. Chuẩn bị dữ liệu nguồn cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
                    MaBieuMau      = @maBieuMau,
                    TieuChiId,
					TenTieuChi,
                    MaTieuChi      = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
                    SoThuTu,
                    CauTrucGUID,
                    KCN_NamNgoai_KKT,
                    KCN_VenBien,
                    KCN_CuaKhau,
                    KCN_ChuyenBiet,
                    TongCong,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TableKeHoachDuAn
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            ----------------------------------------------------------
            -- 3. MERGE: Update hoặc Insert mới
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau1 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
                    T.TieuChiId         = S.TieuChiId,
					T.TenTieuChi = S.TenTieuChi,
                    T.SoThuTu           = S.SoThuTu,
                    T.BieuMauId         = S.BieuMauId,
                    T.MaTieuChi         = S.MaTieuChi,
                    T.KCN_NamNgoai_KKT  = S.KCN_NamNgoai_KKT,
                    T.KCN_VenBien       = S.KCN_VenBien,
                    T.KCN_CuaKhau       = S.KCN_CuaKhau,
                    T.KCN_ChuyenBiet    = S.KCN_ChuyenBiet,
                    T.TongCong          = S.TongCong,
                    T.BitDaXoa          = 0,
                    T.NguoiSua          = S.NguoiCapNhat,
                    T.NgaySua           = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    BieuMauId, MaBieuMau, DotKeHoach_Id, KeHoachId, DonViId,
                    TieuChiId, TenTieuChi, MaTieuChi, SoThuTu, CauTrucGUID,
                    KCN_NamNgoai_KKT, KCN_VenBien, KCN_CuaKhau, KCN_ChuyenBiet, TongCong,
                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES
                (
                    S.BieuMauId, S.MaBieuMau, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.TieuChiId, S.TenTieuChi, S.MaTieuChi, S.SoThuTu, S.CauTrucGUID,
                    S.KCN_NamNgoai_KKT, S.KCN_VenBien, S.KCN_CuaKhau, S.KCN_ChuyenBiet, S.TongCong,
                    S.NguoiCapNhat, GETDATE(), 0
                );

            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau1 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM01_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 01
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_BM01_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           CONCAT_WS(' ', ct.SoThuTuHienThi, ct.TenTieuChi) AS TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
           ct.Style,
           ct.DonViTinh,
           (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
           ISNULL(bm.KCN_NamNgoai_KKT, 0) AS KCN_NamNgoai_KKT,
           ISNULL(bm.KCN_VenBien, 0) AS KCN_VenBien,
           ISNULL(bm.KCN_CuaKhau, 0) AS KCN_CuaKhau,
           ISNULL(bm.KCN_ChuyenBiet, 0) AS KCN_ChuyenBiet,
           ISNULL(bm.TongCong, 0) AS TongCong
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau1 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0
    ORDER BY ct.Path;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM02_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create   PROCEDURE [dbo].[sp_BCDT_BM02_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN

    -- Thay giá trị này nếu mã biểu mẫu khác
    DECLARE @maBieuMau NVARCHAR(50) = N'02NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1) Parse JSON -> table variable
            ----------------------------------------------------------
            DECLARE @TableDuLieu TABLE
            (
				DuAnId INT,
				MaDuAn nvarchar(50),
				TenDuAn nvarchar(2000),
                Id INT,
				DonViId INT,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
				BieuMauId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
				CauTrucGUID UNIQUEIDENTIFIER,
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				
				DiaDiem nvarchar(4000),
				TenNhaDauTu nvarchar(1000),
				QuocTichDauTu nvarchar(200),
				TLM_QDChapThuan nvarchar(200),
				TLM_ChungNhanDangKy nvarchar(200),
				TLM_QuyMoThanhLap decimal(24, 3),
				TLM_QuyMoCNDV decimal(24, 3),
				TLM_ThoiHanThue int,
				TLM_VonNuocNgoai decimal(24, 3),
				TLM_VonTrongNuoc decimal(24, 3),
				DC_ChungNhanDangKy nvarchar(200),
				DC_ChungNhanDieuChinh nvarchar(200),
				DC_TruocDieuChinh decimal(24, 3),
				DC_SauDieuChinh decimal(24, 3)
            );

            INSERT INTO @TableDuLieu
            (
                Id,
				BieuMauId,
				DonViId,
				DuAnId,
				MaDuAn,
				TenDuAn,
				TenKKTKCN,
				KKTKCN_Id,
				KKTKCN_Ma,
				LoaiHinhKKTKCN_Id,
				CauTrucGUID,
				TieuChiId,
				TenTieuChi,

				DiaDiem,
				TenNhaDauTu,
				QuocTichDauTu,
				TLM_QDChapThuan,
				TLM_ChungNhanDangKy,
				TLM_QuyMoThanhLap,
				TLM_QuyMoCNDV,
				TLM_ThoiHanThue,
				TLM_VonNuocNgoai,
				TLM_VonTrongNuoc,
				DC_ChungNhanDangKy,
				DC_ChungNhanDieuChinh,
				DC_TruocDieuChinh,
				DC_SauDieuChinh
				

            )
            SELECT
                Id,
				BieuMauId,
				DonViId,
				DuAnId,
				MaDuAn,
				TenDuAn,
				TenKKTKCN,
				KKTKCN_Id,
				KKTKCN_Ma,
				LoaiHinhKKTKCN_Id,
				CauTrucGUID,
				TieuChiId,
				TenTieuChi,

				DiaDiem,
				TenNhaDauTu,
				QuocTichDauTu,
				TLM_QDChapThuan,
				TLM_ChungNhanDangKy,
				TLM_QuyMoThanhLap,
				TLM_QuyMoCNDV,
				TLM_ThoiHanThue,
				TLM_VonNuocNgoai,
				TLM_VonTrongNuoc,
				DC_ChungNhanDangKy,
				DC_ChungNhanDieuChinh,
				DC_TruocDieuChinh,
				DC_SauDieuChinh
				
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
			Id INT '$.Id'
			,BieuMauId INT '$.BieuMauId'
			,DonViId INT '$.DonViId'
			,DuAnId INT '$.DuAnId' 
			,MaDuAn nvarchar(50) '$.MaDuAn' 
			,TenDuAn nvarchar(2000) '$.TenDuAn' 
			,TenKKTKCN nvarchar(500) '$.TenKKTKCN' 
			,KKTKCN_Id int '$.KKTKCN_Id' 
			,KKTKCN_Ma nvarchar(50) '$.KKTKCN_Ma' 
			,LoaiHinhKKTKCN_Id nvarchar(50) '$.LoaiHinhKKTKCN_Id' 
			,CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID'
			,TieuChiId INT '$.TieuChiId'
			,TenTieuChi nvarchar(2000) '$.TenTieuChi'

			,DiaDiem nvarchar(4000) '$.DiaDiem',
			TenNhaDauTu nvarchar(1000) '$.TenNhaDauTu',
			QuocTichDauTu nvarchar(200) '$.QuocTichDauTu',
			TLM_QDChapThuan nvarchar(200) '$.TLM_QDChapThuan',
			TLM_ChungNhanDangKy nvarchar(200) '$.TLM_ChungNhanDangKy',
			TLM_QuyMoThanhLap decimal(24, 3) '$.TLM_QuyMoThanhLap',
			TLM_QuyMoCNDV decimal(24, 3) '$.TLM_QuyMoCNDV',
			TLM_ThoiHanThue int '$.TLM_ThoiHanThue',
			TLM_VonNuocNgoai decimal(24, 3) '$.TLM_VonNuocNgoai',
			TLM_VonTrongNuoc decimal(24, 3) '$.TLM_VonTrongNuoc',
			DC_ChungNhanDangKy nvarchar(200) '$.DC_ChungNhanDangKy',
			DC_ChungNhanDieuChinh nvarchar(200) '$.DC_ChungNhanDieuChinh',
			DC_TruocDieuChinh decimal(24, 3) '$.DC_TruocDieuChinh',
			DC_SauDieuChinh decimal(24, 3) '$.DC_SauDieuChinh'
            );
            ----------------------------------------------------------
            -- 2) Chuẩn bị nguồn (Src) cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    MaBieuMau      = @maBieuMau,
					DuAnId,
					MaDuAn,
					TenDuAn,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id
					,CauTrucGUID
					,TieuChiId
					,MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId)
					,TenTieuChi
					,BieuMauId

					,DiaDiem,
					TenNhaDauTu,
					QuocTichDauTu,
					TLM_QDChapThuan,
					TLM_ChungNhanDangKy,
					TLM_QuyMoThanhLap,
					TLM_QuyMoCNDV,
					TLM_ThoiHanThue,
					TLM_VonNuocNgoai,
					TLM_VonTrongNuoc,
					DC_ChungNhanDangKy,
					DC_ChungNhanDieuChinh,
					DC_TruocDieuChinh,
					DC_SauDieuChinh

                    ,NguoiCapNhat   = @NguoiDungId
                FROM @TableDuLieu
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            ----------------------------------------------------------
            -- 3) MERGE -> Update | Insert
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau2 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID     = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN            = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id    = S.LoaiHinhKKTKCN_Id,
					T.DuAnId = S.DuAnId,
					T.MaDuAn = S.MaDuAn,
					T.TenDuAn = S.TenDuAn,

					T.DiaDiem = S.DiaDiem,
					T.TenNhaDauTu = S.TenNhaDauTu,
					T.QuocTichDauTu = S.QuocTichDauTu,
					T.TLM_QDChapThuan = S.TLM_QDChapThuan,
					T.TLM_ChungNhanDangKy = S.TLM_ChungNhanDangKy,
					T.TLM_QuyMoThanhLap = S.TLM_QuyMoThanhLap,
					T.TLM_QuyMoCNDV = S.TLM_QuyMoCNDV,
					T.TLM_ThoiHanThue = S.TLM_ThoiHanThue,
					T.TLM_VonNuocNgoai = S.TLM_VonNuocNgoai,
					T.TLM_VonTrongNuoc = S.TLM_VonTrongNuoc,
					T.DC_ChungNhanDangKy = S.DC_ChungNhanDangKy,
					T.DC_ChungNhanDieuChinh = S.DC_ChungNhanDieuChinh,
					T.DC_TruocDieuChinh = S.DC_TruocDieuChinh,
					T.DC_SauDieuChinh = S.DC_SauDieuChinh

                    ,T.BitDaXoa             = 0               -- khôi phục nếu đã xoá
                    ,T.NguoiSua             = S.NguoiCapNhat
                    ,T.NgaySua              = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
				DotKeHoach_Id
				,KeHoachId
				,BieuMauId
				,MaBieuMau
				,TieuChiId, MaTieuChi, TenTieuChi
				,DonViId
				,DuAnId
				,MaDuAn
				,TenDuAn
				,TenKKTKCN
				,KKTKCN_Id
				,KKTKCN_Ma
				,LoaiHinhKKTKCN_Id
				,CauTrucGUID

				,DiaDiem,
				TenNhaDauTu,
				QuocTichDauTu,
				TLM_QDChapThuan,
				TLM_ChungNhanDangKy,
				TLM_QuyMoThanhLap,
				TLM_QuyMoCNDV,
				TLM_ThoiHanThue,
				TLM_VonNuocNgoai,
				TLM_VonTrongNuoc,
				DC_ChungNhanDangKy,
				DC_ChungNhanDieuChinh,
				DC_TruocDieuChinh,
				DC_SauDieuChinh
				,NguoiTao
				,NgayTao
				,BitDaXoa
                )
                VALUES
                (
				S.DotKeHoach_Id
				,S.KeHoachId
					,S.BieuMauId
					,S.MaBieuMau
					,S.TieuChiId, S.MaTieuChi, S.TenTieuChi
					,S.DonViId
					,S.DuAnId
					,S.MaDuAn
					,S.TenDuAn
					,S.TenKKTKCN
					,S.KKTKCN_Id
					,S.KKTKCN_Ma
					,S.LoaiHinhKKTKCN_Id
					,S.CauTrucGUID
					,S.DiaDiem,
					S.TenNhaDauTu,
					S.QuocTichDauTu,
					S.TLM_QDChapThuan,
					S.TLM_ChungNhanDangKy,
					S.TLM_QuyMoThanhLap,
					S.TLM_QuyMoCNDV,
					S.TLM_ThoiHanThue,
					S.TLM_VonNuocNgoai,
					S.TLM_VonTrongNuoc,
					S.DC_ChungNhanDangKy,
					S.DC_ChungNhanDieuChinh,
					S.DC_TruocDieuChinh,
					S.DC_SauDieuChinh
					,S.NguoiCapNhat
					,getdate()
					,0

                );

            ----------------------------------------------------------
            -- 4) ĐÁNH DẤU XÓA MỀM theo CẤU TRÚC BIỂU MẪU (fn_BCDT_GetCauTrucBieuMau)
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau2 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGUID
               AND ISNULL(T.MaBieuMau, @maBieuMau) = CT.MaBieuMau
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM02_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 02
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM02_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
	--select @thoiGianTu, @thoiGianDen
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.DiaDiem,
			bm.TenNhaDauTu,
			bm.QuocTichDauTu,
			bm.TLM_QDChapThuan,
			bm.TLM_ChungNhanDangKy,
			bm.TLM_QuyMoThanhLap,
			bm.TLM_QuyMoCNDV,
			bm.TLM_ThoiHanThue,
			bm.TLM_VonNuocNgoai,
			bm.TLM_VonTrongNuoc,
			bm.DC_ChungNhanDangKy,
			bm.DC_ChungNhanDieuChinh,
			bm.DC_TruocDieuChinh,
			bm.DC_SauDieuChinh
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau2 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0;

	WITH 
	CTE_26 AS ( --Các KCN mới được phê duyệt chủ trương đầu tư/thành lập
	    	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   dvhc.TenDonVi as DiaDiem,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichDauTu,
		   vb1.SoKyHieu + N' ngày ' + FORMAT(vb1.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS TLM_QDChapThuan,
		   vb2.SoKyHieu + N' ngày ' + FORMAT(vb2.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS TLM_ChungNhanDangKy,
		   vb2.DienTichThanhLap as TLM_QuyMoThanhLap,
		   vb2.DienTichCNDV as TLM_QuyMoCNDV,
		   vb2.ThoiHanThueDat as TLM_ThoiHanThue,
		   vb2.VonDauTuNuocNgoai as TLM_VonNuocNgoai,
		   vb2.VonDauTuTrongNuoc as TLM_VonTrongNuoc,
		   '' as DC_ChungNhanDangKy,
		   0 as DC_TruocDieuChinh,
		   '' as DC_ChungNhanDieuChinh,
		   0 as DC_SauDieuChinh
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	left join dbo.BCDT_DanhMuc_DonViHanhChinh dvhc on dvhc.MaDonVi = da.DiaChi_Tinh
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.VonDauTuNuocNgoai,
	v.VonDauTuTrongNuoc,
	v.DienTichThanhLap,
	v.DienTichCNDV,
	v.ThoiHanThueDat
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 2
		AND v.TrangThaiVanBan = 1
        AND v.NgayBanHanh BETWEEN @thoiGianTu AND @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 1
        AND v.NgayBanHanh BETWEEN @thoiGianTu AND @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb1
	WHERE tmp.Path LIKE (SELECT Path + '%' FROM #TempData WHERE MaTieuChi = 'TCCD26')
    --ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path
	),
	CTE_27 AS ( --Các KCN điều chỉnh tăng diện tích
	    SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   dvhc.TenDonVi as DiaDiem,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichDauTu,

		   '' AS TLM_QDChapThuan,
		   '' AS TLM_ChungNhanDangKy,
		   0 as TLM_QuyMoThanhLap,
		   0 as TLM_QuyMoCNDV,
		   '' as TLM_ThoiHanThue,
		   0 as TLM_VonNuocNgoai,
		   0 as TLM_VonTrongNuoc,
		   vb_truoc_dc.SoKyHieu + N' ngày ' + FORMAT(vb_truoc_dc.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as DC_ChungNhanDangKy,
		   vb_truoc_dc.DienTichThanhLap as DC_TruocDieuChinh,
		   vb_dieu_chinh.SoKyHieu + N' ngày ' + FORMAT(vb_dieu_chinh.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as DC_ChungNhanDieuChinh,
		   vb_dieu_chinh.DienTichThanhLap as DC_SauDieuChinh
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	left join dbo.BCDT_DanhMuc_DonViHanhChinh dvhc on dvhc.MaDonVi = da.DiaChi_Tinh
	-- Văn bản điều chỉnh trong kỳ
	OUTER APPLY (
	    SELECT TOP 1 
	        v.Id, v.SoKyHieu, v.NgayBanHanh, v.DienTichThanhLap
	    FROM BCDT_TieuChi_DuAn_VanBan v
	    WHERE v.DuAnId = da.Id
	        AND v.LoaiVanBan = 2
	        AND v.TrangThaiVanBan = 2
	        AND v.LoaiDieuChinh = 1
	        AND v.NgayBanHanh BETWEEN @thoiGianTu AND @thoiGianDen
			AND v.BitDaXoa = 0
	    ORDER BY v.NgayBanHanh DESC
	) vb_dieu_chinh
	
	-- Văn bản trước điều chỉnh (gần nhất trước vb_dieu_chinh)
	OUTER APPLY (
	    SELECT TOP 1 
	        v.Id, v.SoKyHieu, v.NgayBanHanh, v.DienTichThanhLap
	    FROM BCDT_TieuChi_DuAn_VanBan v
	    WHERE v.DuAnId = da.Id
	        AND v.LoaiVanBan = 2
			AND v.TrangThaiVanBan = 2
	        AND v.LoaiDieuChinh = 1
	        AND vb_dieu_chinh.NgayBanHanh IS NOT NULL
	        AND v.NgayBanHanh < vb_dieu_chinh.NgayBanHanh
			AND v.BitDaXoa = 0
	    ORDER BY v.NgayBanHanh DESC
	) vb_truoc_dc
	WHERE tmp.Path LIKE (SELECT Path + '%' FROM #TempData WHERE MaTieuChi = 'TCCD27')
    --ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path
	),
	CTE_28 AS ( --Các KCN điều chỉnh giảm diện tích
	    SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   dvhc.TenDonVi as DiaDiem,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichDauTu,

		   '' AS TLM_QDChapThuan,
		   '' AS TLM_ChungNhanDangKy,
		   0 as TLM_QuyMoThanhLap,
		   0 as TLM_QuyMoCNDV,
		   '' as TLM_ThoiHanThue,
		   0 as TLM_VonNuocNgoai,
		   0 as TLM_VonTrongNuoc,
		   vb_truoc_dc.SoKyHieu + N' ngày ' + FORMAT(vb_truoc_dc.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as DC_ChungNhanDangKy,
		   vb_truoc_dc.DienTichThanhLap as DC_TruocDieuChinh,
		   vb_dieu_chinh.SoKyHieu + N' ngày ' + FORMAT(vb_dieu_chinh.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as DC_ChungNhanDieuChinh,
		   vb_dieu_chinh.DienTichThanhLap as DC_SauDieuChinh
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	left join dbo.BCDT_DanhMuc_DonViHanhChinh dvhc on dvhc.MaDonVi = da.DiaChi_Tinh
	-- Văn bản điều chỉnh trong kỳ
	OUTER APPLY (
	    SELECT TOP 1 
	        v.Id, v.SoKyHieu, v.NgayBanHanh, v.DienTichThanhLap
	    FROM BCDT_TieuChi_DuAn_VanBan v
	    WHERE v.DuAnId = da.Id
	        AND v.LoaiVanBan = 2
	        AND v.TrangThaiVanBan = 2
	        AND v.LoaiDieuChinh = 2
	        AND v.NgayBanHanh BETWEEN @thoiGianTu AND @thoiGianDen
			AND v.BitDaXoa = 0
	    ORDER BY v.NgayBanHanh DESC
	) vb_dieu_chinh
	
	-- Văn bản trước điều chỉnh (gần nhất trước vb_dieu_chinh)
	OUTER APPLY (
	    SELECT TOP 1 
	        v.Id, v.SoKyHieu, v.NgayBanHanh, v.DienTichThanhLap
	    FROM BCDT_TieuChi_DuAn_VanBan v
	    WHERE v.DuAnId = da.Id
	        AND v.LoaiVanBan = 2
			AND v.TrangThaiVanBan = 2
	        AND v.LoaiDieuChinh = 2
	        AND vb_dieu_chinh.NgayBanHanh IS NOT NULL
	        AND v.NgayBanHanh < vb_dieu_chinh.NgayBanHanh
			AND v.BitDaXoa = 0
	    ORDER BY v.NgayBanHanh DESC
	) vb_truoc_dc
	WHERE tmp.Path LIKE (SELECT Path + '%' FROM #TempData WHERE MaTieuChi = 'TCCD28')
    --ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path
	),
	CTE_29 AS ( --Các KCN thu hồi toàn bộ diện tích đã phê duyệt chủ trương đầu tư/thành lập
	    SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   dvhc.TenDonVi as DiaDiem,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichDauTu,

		   '' AS TLM_QDChapThuan,
		   '' AS TLM_ChungNhanDangKy,
		   0 as TLM_QuyMoThanhLap,
		   0 as TLM_QuyMoCNDV,
		   '' as TLM_ThoiHanThue,
		   0 as TLM_VonNuocNgoai,
		   0 as TLM_VonTrongNuoc,
		   vb_truoc_th.SoKyHieu + N' ngày ' + FORMAT(vb_truoc_th.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as DC_ChungNhanDangKy,
		   vb_truoc_th.DienTichThanhLap as DC_TruocDieuChinh,
		   vb_thu_hoi.SoKyHieu + N' ngày ' + FORMAT(vb_thu_hoi.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as DC_ChungNhanDieuChinh,
		   vb_thu_hoi.DienTichThanhLap as DC_SauDieuChinh
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	left join dbo.BCDT_DanhMuc_DonViHanhChinh dvhc on dvhc.MaDonVi = da.DiaChi_Tinh
	-- Văn bản thu hồi trong kỳ
	OUTER APPLY (
	    SELECT TOP 1 
	        v.Id, v.SoKyHieu, v.NgayBanHanh, v.DienTichThanhLap
	    FROM BCDT_TieuChi_DuAn_VanBan v
	    WHERE v.DuAnId = da.Id
	        AND v.LoaiVanBan = 3
	        AND v.TrangThaiVanBan = 2
	        AND v.NgayBanHanh BETWEEN @thoiGianTu AND @thoiGianDen
			AND v.BitDaXoa = 0
	    ORDER BY v.NgayBanHanh DESC
	) vb_thu_hoi
	
	-- Văn bản trước thu hồi (gần nhất trước vb_thu_hoi)
	OUTER APPLY (
	    SELECT TOP 1 
	        v.Id, v.SoKyHieu, v.NgayBanHanh, v.DienTichThanhLap
	    FROM BCDT_TieuChi_DuAn_VanBan v
	    WHERE v.DuAnId = da.Id
	        AND v.LoaiVanBan = 2
	        AND vb_thu_hoi.NgayBanHanh IS NOT NULL
	        AND v.NgayBanHanh < vb_thu_hoi.NgayBanHanh
			AND v.BitDaXoa = 0
	    ORDER BY v.NgayBanHanh DESC
	) vb_truoc_th
	WHERE tmp.Path LIKE (SELECT Path + '%' FROM #TempData WHERE MaTieuChi = 'TCCD29')
    --ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path
	),
	CTE_ALL AS (
    SELECT * FROM CTE_26
    UNION ALL
    SELECT * FROM CTE_27
    UNION ALL
    SELECT * FROM CTE_28
    UNION ALL
    SELECT * FROM CTE_29
	)
	SELECT *
FROM CTE_ALL
ORDER BY SoThuTuBieuTieuChi, Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM03_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 03
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM03_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'03NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				DuAnId INT,
				MaDuAn nvarchar(50),
				TenDuAn nvarchar(2000),
				TenTieuChi nvarchar(2000),
				[QuyetDinhChapThuan] [nvarchar](200),
				[GiayChungNhan] [nvarchar](200),
				[DiaDiem] [nvarchar](2000),
				[TenNhaDauTu] [nvarchar](1000),
				[QuocTichNhaDauTu] [nvarchar](200),
				[VonDangKy_VonDauTuNN] [decimal](24, 3),
				[VonDangKy_VonDauTuTN] [decimal](24, 3),
				[QuyMoThanhLap] [decimal](24, 3),
				[QuyMoCNDV] [decimal](24, 3),
				[QuyMoDaChoThue] [decimal](24, 3),
				[TyLeLapDay] [decimal](24, 3),
				[MucDoHoanThien] [decimal](24, 3),
				[TinhTrangHoatDong] [int],
				[QuyMoDaGiao] [decimal](24, 3),
				[LuyKe_VonDauTuNN] [decimal](24, 3),
				[LuyKe_VonDauTuTN] [decimal](24, 3)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
				DuAnId,
				MaDuAn,
				TenDuAn,
				TenTieuChi,
                QuyetDinhChapThuan,
				GiayChungNhan,
				DiaDiem,
				TenNhaDauTu,
				QuocTichNhaDauTu,
				VonDangKy_VonDauTuNN,
				VonDangKy_VonDauTuTN,
				QuyMoThanhLap,
				QuyMoCNDV,
				QuyMoDaChoThue,
				TyLeLapDay,
				MucDoHoanThien,
				TinhTrangHoatDong,
				QuyMoDaGiao,
				LuyKe_VonDauTuNN,
				LuyKe_VonDauTuTN
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
				DuAnId INT '$.DuAnId', 
				MaDuAn nvarchar(50) '$.MaDuAn', 
				TenDuAn nvarchar(2000) '$.TenDuAn', 
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 
                QuyetDinhChapThuan [nvarchar](200) '$.QuyetDinhChapThuan',
				GiayChungNhan [nvarchar](200) '$.GiayChungNhan',
				DiaDiem [nvarchar](2000) '$.DiaDiem',
				TenNhaDauTu [nvarchar](1000) '$.TenNhaDauTu',
				QuocTichNhaDauTu [nvarchar](200) '$.QuocTichNhaDauTu',
				VonDangKy_VonDauTuNN [decimal](24, 3) '$.VonDangKy_VonDauTuNN',
				VonDangKy_VonDauTuTN [decimal](24, 3) '$.VonDangKy_VonDauTuTN',
				QuyMoThanhLap [decimal](24, 3) '$.QuyMoThanhLap',
				QuyMoCNDV [decimal](24, 3) '$.QuyMoCNDV',
				QuyMoDaChoThue [decimal](24, 3) '$.QuyMoDaChoThue',
				TyLeLapDay [decimal](24, 3) '$.TyLeLapDay',
				MucDoHoanThien [decimal](24, 3) '$.MucDoHoanThien',
				TinhTrangHoatDong [int] '$.TinhTrangHoatDong',
				QuyMoDaGiao [decimal](24, 3) '$.QuyMoDaGiao',
				LuyKe_VonDauTuNN [decimal](24, 3) '$.LuyKe_VonDauTuNN',
				LuyKe_VonDauTuTN [decimal](24, 3) '$.LuyKe_VonDauTuTN'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
					DuAnId,
					MaDuAn,
					TenDuAn,
					TenTieuChi,
                    QuyetDinhChapThuan,
					GiayChungNhan,
					DiaDiem,
					TenNhaDauTu,
					QuocTichNhaDauTu,
					VonDangKy_VonDauTuNN,
					VonDangKy_VonDauTuTN,
					QuyMoThanhLap,
					QuyMoCNDV,
					QuyMoDaChoThue,
					TyLeLapDay,
					MucDoHoanThien,
					TinhTrangHoatDong,
					QuyMoDaGiao,
					LuyKe_VonDauTuNN,
					LuyKe_VonDauTuTN,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau3 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN            = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id    = S.LoaiHinhKKTKCN_Id,
					T.DuAnId = S.DuAnId,
					T.MaDuAn = S.MaDuAn,
					T.TenDuAn = S.TenDuAn,

                    T.QuyetDinhChapThuan = S.QuyetDinhChapThuan,
					T.GiayChungNhan = S.GiayChungNhan,
					T.DiaDiem = S.DiaDiem,
					T.TenNhaDauTu = S.TenNhaDauTu,
					T.QuocTichNhaDauTu = S.QuocTichNhaDauTu,
					T.VonDangKy_VonDauTuNN = S.VonDangKy_VonDauTuNN,
					T.VonDangKy_VonDauTuTN = S.VonDangKy_VonDauTuTN,
					T.QuyMoThanhLap = S.QuyMoThanhLap,
					T.QuyMoCNDV = S.QuyMoCNDV,
					T.QuyMoDaChoThue = S.QuyMoDaChoThue,
					T.TyLeLapDay = S.TyLeLapDay,
					T.MucDoHoanThien = S.MucDoHoanThien,
					T.TinhTrangHoatDong = S.TinhTrangHoatDong,
					T.QuyMoDaGiao = S.QuyMoDaGiao,
					T.LuyKe_VonDauTuNN = S.LuyKe_VonDauTuNN,
					T.LuyKe_VonDauTuTN = S.LuyKe_VonDauTuTN,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, TieuChiId, MaTieuChi, TenTieuChi, MaBieuMau, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,DuAnId ,MaDuAn, TenDuAn,
                    QuyetDinhChapThuan,
					GiayChungNhan,
					DiaDiem,
					TenNhaDauTu,
					QuocTichNhaDauTu,
					VonDangKy_VonDauTuNN,
					VonDangKy_VonDauTuTN,
					QuyMoThanhLap,
					QuyMoCNDV,
					QuyMoDaChoThue,
					TyLeLapDay,
					MucDoHoanThien,
					TinhTrangHoatDong,
					QuyMoDaGiao,
					LuyKe_VonDauTuNN,
					LuyKe_VonDauTuTN,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,S.DuAnId ,S.MaDuAn ,S.TenDuAn,
                    S.QuyetDinhChapThuan,
					S.GiayChungNhan,
					S.DiaDiem,
					S.TenNhaDauTu,
					S.QuocTichNhaDauTu,
					S.VonDangKy_VonDauTuNN,
					S.VonDangKy_VonDauTuTN,
					S.QuyMoThanhLap,
					S.QuyMoCNDV,
					S.QuyMoDaChoThue,
					S.TyLeLapDay,
					S.MucDoHoanThien,
					S.TinhTrangHoatDong,
					S.QuyMoDaGiao,
					S.LuyKe_VonDauTuNN,
					S.LuyKe_VonDauTuTN,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau3 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM03_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 08
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM03_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
	PRINT @thoiGianTu
	PRINT @thoiGianDen
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.QuyetDinhChapThuan,
           bm.GiayChungNhan,
           bm.DiaDiem,
           bm.TenNhaDauTu,
           bm.QuocTichNhaDauTu,
           bm.VonDangKy_VonDauTuNN,
           bm.VonDangKy_VonDauTuTN,
		   bm.QuyMoThanhLap,
		   bm.QuyMoCNDV,
		   bm.QuyMoDaChoThue,
		   bm.TyLeLapDay,
		   bm.MucDoHoanThien,
		   bm.TinhTrangHoatDong,
		   bm.QuyMoDaGiao,
		   bm.LuyKe_VonDauTuNN,
		   bm.LuyKe_VonDauTuTN
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau3 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   vb1.SoKyHieu + N' ngày ' + FORMAT(vb1.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS QuyetDinhChapThuan,
		   vb2.SoKyHieu + N' ngày ' + FORMAT(vb2.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS GiayChungNhan,
		   dvhc.TenDonVi as DiaDiem,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichNhaDauTu,
		   vb2.VonDauTuNuocNgoai as VonDangKy_VonDauTuNN,
		   vb2.VonDauTuTrongNuoc as VonDangKy_VonDauTuTN,
		   vb2.DienTichThanhLap as QuyMoThanhLap,
		   vb2.DienTichCNDV as QuyMoCNDV,
		   tmp.QuyMoDaChoThue,
		   tmp.TyLeLapDay,
		   tmp.MucDoHoanThien,
		   tmp.TinhTrangHoatDong,
		   tmp.QuyMoDaGiao,
		   tmp.LuyKe_VonDauTuNN,
		   tmp.LuyKe_VonDauTuTN,
		   dm.NoiDung as TenTinhTrangHoatDong
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	left join dbo.BCDT_DanhMuc_DonViHanhChinh dvhc on dvhc.MaDonVi = da.DiaChi_Tinh
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm ON dm.LoaiDanhMuc = 'DA_TTHD' AND dm.Ma = tmp.TinhTrangHoatDong
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.VonDauTuNuocNgoai,
	v.VonDauTuTrongNuoc,
	v.DienTichThanhLap,
	v.DienTichCNDV
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 1
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb1
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM04_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_BCDT_BM04_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN

    -- Thay giá trị này nếu mã biểu mẫu khác
    DECLARE @maBieuMau NVARCHAR(50) = N'04NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1) Parse JSON -> table variable
            ----------------------------------------------------------
            DECLARE @TableDuLieu TABLE
            (
				DuAnId INT,
				MaDuAn nvarchar(50),
                Id INT,
				DonViId INT,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
				BieuMauId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
				CauTrucGUID UNIQUEIDENTIFIER,
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				TenDuAn nvarchar(2000),
				[NN_TongSoDuAnHieuLuc] [int] NULL,
				[NN_TongDauTu] [decimal](24, 3) NULL,
				[NN_SoDuAnSXKD] [int] NULL,
				[NN_TongVonThucHien] [decimal](24, 3) NULL,
				[NN_DoanhThu] [decimal](24, 3) NULL,
				[NN_GiaTriXuatKhau] [decimal](24, 3) NULL,
				[NN_GiaTriNhapKhau] [decimal](24, 3) NULL,
				[NN_NopNganSach] [decimal](24, 3) NULL,
				[NN_SoLaoDong] [int] NULL,
				[TN_TongSoDuAnHieuLuc] [int] NULL,
				[TN_TongVonDauTu] [decimal](24, 3) NULL,
				[TN_SoDuAnSXKD] [int] NULL,
				[TN_TongVonThucHien] [decimal](24, 3) NULL,
				[TN_DoanhThu] [decimal](24, 3) NULL,
				[TN_GiaTriXuatKhau] [decimal](24, 3) NULL,
				[TN_GiaTriNhapKhau] [decimal](24, 3) NULL,
				[TN_NopNganSach] [decimal](24, 3) NULL,
				[TN_SoLaoDong] [int] NULL
            );

            INSERT INTO @TableDuLieu
            (
                Id
				,BieuMauId
				,DonViId
				,DuAnId
				,MaDuAn
				,TenDuAn
				,TenKKTKCN
				,KKTKCN_Id
				,KKTKCN_Ma
				,LoaiHinhKKTKCN_Id
				,CauTrucGUID
				,NN_TongSoDuAnHieuLuc
				,NN_TongDauTu
				,NN_SoDuAnSXKD
				,NN_TongVonThucHien
				,NN_DoanhThu
				,NN_GiaTriXuatKhau
				,NN_GiaTriNhapKhau
				,NN_NopNganSach
				,NN_SoLaoDong
				,TN_TongSoDuAnHieuLuc
				,TN_TongVonDauTu
				,TN_SoDuAnSXKD
				,TN_TongVonThucHien
				,TN_DoanhThu
				,TN_GiaTriXuatKhau
				,TN_GiaTriNhapKhau
				,TN_NopNganSach
				,TN_SoLaoDong
				,TieuChiId
				,TenTieuChi

            )
            SELECT
                Id
				,BieuMauId
				,DonViId
				,DuAnId
				,MaDuAn
				,TenDuAn
				,TenKKTKCN
				,KKTKCN_Id
				,KKTKCN_Ma
				,LoaiHinhKKTKCN_Id
				,CauTrucGUID
				,NN_TongSoDuAnHieuLuc
				,NN_TongDauTu
				,NN_SoDuAnSXKD
				,NN_TongVonThucHien
				,NN_DoanhThu
				,NN_GiaTriXuatKhau
				,NN_GiaTriNhapKhau
				,NN_NopNganSach
				,NN_SoLaoDong
				,TN_TongSoDuAnHieuLuc
				,TN_TongVonDauTu
				,TN_SoDuAnSXKD
				,TN_TongVonThucHien
				,TN_DoanhThu
				,TN_GiaTriXuatKhau
				,TN_GiaTriNhapKhau
				,TN_NopNganSach
				,TN_SoLaoDong
				,TieuChiId
				,TenTieuChi
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
			Id INT '$.Id'
			,BieuMauId INT '$.BieuMauId'
			,DonViId INT '$.DonViId'
			,DuAnId INT '$.DuAnId' 
			,MaDuAn nvarchar(50) '$.MaDuAn' 
			,TenDuAn nvarchar(2000) '$.TenDuAn' 
			,TenKKTKCN nvarchar(500) '$.TenKKTKCN' 
			,KKTKCN_Id int '$.KKTKCN_Id' 
			,KKTKCN_Ma nvarchar(50) '$.KKTKCN_Ma' 
			,LoaiHinhKKTKCN_Id nvarchar(50) '$.LoaiHinhKKTKCN_Id' 
			,CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID'
			,NN_TongSoDuAnHieuLuc decimal(24,3) '$.NN_TongSoDuAnHieuLuc'
			,NN_TongDauTu decimal(24,3) '$.NN_TongDauTu'
			,NN_SoDuAnSXKD int '$.NN_SoDuAnSXKD'
			,NN_TongVonThucHien decimal(24,3) '$.NN_TongVonThucHien'
			,NN_DoanhThu decimal(24,3) '$.NN_DoanhThu'
			,NN_GiaTriXuatKhau decimal(24,3) '$.NN_GiaTriXuatKhau'
			,NN_GiaTriNhapKhau decimal(24,3) '$.NN_GiaTriNhapKhau'
			,NN_NopNganSach decimal(24,3) '$.NN_NopNganSach'
			,NN_SoLaoDong decimal(24,3) '$.NN_SoLaoDong'
			,TN_TongSoDuAnHieuLuc decimal(24,3) '$.TN_TongSoDuAnHieuLuc'
			,TN_TongVonDauTu decimal(24,3) '$.TN_TongVonDauTu'
			,TN_SoDuAnSXKD int '$.TN_SoDuAnSXKD'
			,TN_TongVonThucHien decimal(24,3) '$.TN_TongVonThucHien'
			,TN_DoanhThu decimal(24,3) '$.TN_DoanhThu'
			,TN_GiaTriXuatKhau decimal(24,3) '$.TN_GiaTriXuatKhau'
			,TN_GiaTriNhapKhau decimal(24,3) '$.TN_GiaTriNhapKhau'
			,TN_NopNganSach decimal(24,3) '$.TN_NopNganSach'
			,TN_SoLaoDong decimal(24,3) '$.TN_SoLaoDong'
			,TieuChiId int '$.TieuChiId'
			,TenTieuChi nvarchar(2000) '$.TenTieuChi'
            );
            ----------------------------------------------------------
            -- 2) Chuẩn bị nguồn (Src) cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    MaBieuMau      = @maBieuMau,
					DuAnId,
					MaDuAn,
					TenDuAn,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id
                    ,NN_TongSoDuAnHieuLuc
					,NN_TongDauTu
					,NN_SoDuAnSXKD
					,NN_TongVonThucHien
					,NN_DoanhThu
					,NN_GiaTriXuatKhau
					,NN_GiaTriNhapKhau
					,NN_NopNganSach
					,NN_SoLaoDong
					,TN_TongSoDuAnHieuLuc
					,TN_TongVonDauTu
					,TN_SoDuAnSXKD
					,TN_TongVonThucHien
					,TN_DoanhThu
					,TN_GiaTriXuatKhau
					,TN_GiaTriNhapKhau
					,TN_NopNganSach
					,TN_SoLaoDong
					,CauTrucGUID
					,TieuChiId
					,TenTieuChi
					,MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId)
					,BieuMauId
                    ,NguoiCapNhat   = @NguoiDungId
                FROM @TableDuLieu
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            ----------------------------------------------------------
            -- 3) MERGE -> Update | Insert
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau4 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID     = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN            = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id    = S.LoaiHinhKKTKCN_Id,
					T.DuAnId = S.DuAnId,
					T.MaDuAn = S.MaDuAn,
					T.TenDuAn = S.TenDuAn
                    ,T.NN_TongSoDuAnHieuLuc = S.NN_TongSoDuAnHieuLuc
					,T.NN_TongDauTu = S.NN_TongDauTu
					,T.NN_SoDuAnSXKD = S.NN_SoDuAnSXKD
					,T.NN_TongVonThucHien = S.NN_TongVonThucHien
					,T.NN_DoanhThu = S.NN_DoanhThu
					,T.NN_GiaTriXuatKhau = S.NN_GiaTriXuatKhau
					,T.NN_GiaTriNhapKhau = S.NN_GiaTriNhapKhau
					,T.NN_NopNganSach = S.NN_NopNganSach
					,T.NN_SoLaoDong = S.NN_SoLaoDong
					,T.TN_TongSoDuAnHieuLuc = S.TN_TongSoDuAnHieuLuc
					,T.TN_TongVonDauTu = S.TN_TongVonDauTu
					,T.TN_SoDuAnSXKD = S.TN_SoDuAnSXKD
					,T.TN_TongVonThucHien = S.TN_TongVonThucHien
					,T.TN_DoanhThu = S.TN_DoanhThu
					,T.TN_GiaTriXuatKhau = S.TN_GiaTriXuatKhau
					,T.TN_GiaTriNhapKhau = S.TN_GiaTriNhapKhau
					,T.TN_NopNganSach = S.TN_NopNganSach
					,T.TN_SoLaoDong = S.TN_SoLaoDong
                    ,T.BitDaXoa             = 0               -- khôi phục nếu đã xoá
                    ,T.NguoiSua             = S.NguoiCapNhat
                    ,T.NgaySua              = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
				TieuChiId,
				MaTieuChi,
				TenTieuChi,
				DotKeHoach_Id
				,KeHoachId
				,BieuMauId
				,MaBieuMau
				,DonViId
				,DuAnId
				,MaDuAn
				,TenDuAn
				,TenKKTKCN
				,KKTKCN_Id
				,KKTKCN_Ma
				,LoaiHinhKKTKCN_Id
				,CauTrucGUID
				,NN_TongSoDuAnHieuLuc
				,NN_TongDauTu
				,NN_SoDuAnSXKD
				,NN_TongVonThucHien
				,NN_DoanhThu
				,NN_GiaTriXuatKhau
				,NN_GiaTriNhapKhau
				,NN_NopNganSach
				,NN_SoLaoDong
				,TN_TongSoDuAnHieuLuc
				,TN_TongVonDauTu
				,TN_SoDuAnSXKD
				,TN_TongVonThucHien
				,TN_DoanhThu
				,TN_GiaTriXuatKhau
				,TN_GiaTriNhapKhau
				,TN_NopNganSach
				,TN_SoLaoDong
				,NguoiTao
				,NgayTao
				,BitDaXoa
                )
                VALUES
                (
				S.TieuChiId,
				S.MaTieuChi,
				S.TenTieuChi,
				S.DotKeHoach_Id
				,S.KeHoachId
					,S.BieuMauId
					,S.MaBieuMau
					,S.DonViId
					,S.DuAnId
					,S.MaDuAn
					,S.TenDuAn
					,S.TenKKTKCN
					,S.KKTKCN_Id
					,S.KKTKCN_Ma
					,S.LoaiHinhKKTKCN_Id
					,S.CauTrucGUID
					,S.NN_TongSoDuAnHieuLuc
					,S.NN_TongDauTu
					,S.NN_SoDuAnSXKD
					,S.NN_TongVonThucHien
					,S.NN_DoanhThu
					,S.NN_GiaTriXuatKhau
					,S.NN_GiaTriNhapKhau
					,S.NN_NopNganSach
					,S.NN_SoLaoDong
					,S.TN_TongSoDuAnHieuLuc
					,S.TN_TongVonDauTu
					,S.TN_SoDuAnSXKD
					,S.TN_TongVonThucHien
					,S.TN_DoanhThu
					,S.TN_GiaTriXuatKhau
					,S.TN_GiaTriNhapKhau
					,S.TN_NopNganSach
					,S.TN_SoLaoDong
					,S.NguoiCapNhat
					,getdate()
					,0

                );

            ----------------------------------------------------------
            -- 4) ĐÁNH DẤU XÓA MỀM theo CẤU TRÚC BIỂU MẪU (fn_BCDT_GetCauTrucBieuMau)
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau4 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGUID
               AND ISNULL(T.MaBieuMau, @maBieuMau) = CT.MaBieuMau
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM04_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 04
-- =============================================
CREATE      PROCEDURE [dbo].[sp_BCDT_BM04_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
           ct.Style,
           ct.DonViTinh,
		   ct.SoThuTuBieuTieuChi,
           (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   bm.NN_TongSoDuAnHieuLuc,
			bm.NN_TongDauTu,
			bm.NN_SoDuAnSXKD,
			bm.NN_TongVonThucHien,
			bm.NN_DoanhThu,
			bm.NN_GiaTriXuatKhau,
			bm.NN_GiaTriNhapKhau,
			bm.NN_NopNganSach,
			bm.NN_SoLaoDong,
			bm.TN_TongSoDuAnHieuLuc,
			bm.TN_TongVonDauTu,
			bm.TN_SoDuAnSXKD,
			bm.TN_TongVonThucHien,
			bm.TN_DoanhThu,
			bm.TN_GiaTriXuatKhau,
			bm.TN_GiaTriNhapKhau,
			bm.TN_NopNganSach,
			bm.TN_SoLaoDong
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau4 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0
    

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.NN_TongSoDuAnHieuLuc,
			tmp.NN_TongDauTu,
			tmp.NN_SoDuAnSXKD,
			tmp.NN_TongVonThucHien,
			tmp.NN_DoanhThu,
			tmp.NN_GiaTriXuatKhau,
			tmp.NN_GiaTriNhapKhau,
			tmp.NN_NopNganSach,
			tmp.NN_SoLaoDong,
			tmp.TN_TongSoDuAnHieuLuc,
			tmp.TN_TongVonDauTu,
			tmp.TN_SoDuAnSXKD,
			tmp.TN_TongVonThucHien,
			tmp.TN_DoanhThu,
			tmp.TN_GiaTriXuatKhau,
			tmp.TN_GiaTriNhapKhau,
			tmp.TN_NopNganSach,
			tmp.TN_SoLaoDong,
		   da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM05_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 05
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM05_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'05NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
                TinhTrangQuyHoach INT,
                TinhTrangHoatDong INT,
                CongSuatThietKe DECIMAL(24,3),
                CongSuatHoatDong DECIMAL(24,3),
                ChatLuongNuocThai INT,
                ChatLuongNuocThaiSauXL INT,
                TinhTrangLapDat INT,
                ChuaCo_NNguyenNhan NVARCHAR(50),
                ChuaCo_ThoiGianDuKien NVARCHAR(50),
                ChuaCo_GiaiPhapXL NVARCHAR(4000)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				CauTrucGUID,
				MaBieuMau,
				TieuChiId,
				TenTieuChi,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
                TinhTrangQuyHoach,
                TinhTrangHoatDong,
                CongSuatThietKe,
                CongSuatHoatDong,
                ChatLuongNuocThai,
                ChatLuongNuocThaiSauXL,
                TinhTrangLapDat,
                ChuaCo_NNguyenNhan,
                ChuaCo_ThoiGianDuKien,
                ChuaCo_GiaiPhapXL
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
				TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
                TinhTrangQuyHoach INT '$.TinhTrangQuyHoach',
                TinhTrangHoatDong INT '$.TinhTrangHoatDong',
                CongSuatThietKe DECIMAL(24,3) '$.CongSuatThietKe',
                CongSuatHoatDong DECIMAL(24,3) '$.CongSuatHoatDong',
                ChatLuongNuocThai INT '$.ChatLuongNuocThai',
                ChatLuongNuocThaiSauXL INT '$.ChatLuongNuocThaiSauXL',
                TinhTrangLapDat INT '$.TinhTrangLapDat',
                ChuaCo_NNguyenNhan NVARCHAR(50) '$.ChuaCo_NNguyenNhan',
                ChuaCo_ThoiGianDuKien NVARCHAR(50) '$.ChuaCo_ThoiGianDuKien',
                ChuaCo_GiaiPhapXL NVARCHAR(4000) '$.ChuaCo_GiaiPhapXL'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
                    MaBieuMau      = @maBieuMau,
					TieuChiId,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
                    TinhTrangQuyHoach,
                    TinhTrangHoatDong,
                    CongSuatThietKe,
                    CongSuatHoatDong,
                    ChatLuongNuocThai,
                    ChatLuongNuocThaiSauXL,
                    TinhTrangLapDat,
                    ChuaCo_NNguyenNhan,
                    ChuaCo_ThoiGianDuKien,
                    ChuaCo_GiaiPhapXL,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau5 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN              = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id      = S.LoaiHinhKKTKCN_Id,
                    T.TinhTrangQuyHoach      = S.TinhTrangQuyHoach,
                    T.TinhTrangHoatDong      = S.TinhTrangHoatDong,
                    T.CongSuatThietKe        = S.CongSuatThietKe,
                    T.CongSuatHoatDong       = S.CongSuatHoatDong,
                    T.ChatLuongNuocThai      = S.ChatLuongNuocThai,
                    T.ChatLuongNuocThaiSauXL = S.ChatLuongNuocThaiSauXL,
                    T.TinhTrangLapDat        = S.TinhTrangLapDat,
                    T.ChuaCo_NNguyenNhan     = S.ChuaCo_NNguyenNhan,
                    T.ChuaCo_ThoiGianDuKien  = S.ChuaCo_ThoiGianDuKien,
                    T.ChuaCo_GiaiPhapXL      = S.ChuaCo_GiaiPhapXL,
                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, MaBieuMau, TieuChiId, MaTieuChi, TenTieuChi, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    TinhTrangQuyHoach, TinhTrangHoatDong,
                    CongSuatThietKe, CongSuatHoatDong,
                    ChatLuongNuocThai, ChatLuongNuocThaiSauXL,
                    TinhTrangLapDat, ChuaCo_NNguyenNhan,
                    ChuaCo_ThoiGianDuKien, ChuaCo_GiaiPhapXL,
                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.MaBieuMau, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.TinhTrangQuyHoach, S.TinhTrangHoatDong,
                    S.CongSuatThietKe, S.CongSuatHoatDong,
                    S.ChatLuongNuocThai, S.ChatLuongNuocThaiSauXL,
                    S.TinhTrangLapDat, S.ChuaCo_NNguyenNhan,
                    S.ChuaCo_ThoiGianDuKien, S.ChuaCo_GiaiPhapXL,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau5 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM05_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 05
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM05_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
           ct.Style,
           ct.DonViTinh,
		   ct.SoThuTuBieuTieuChi,
           '' AS CongThucTieuChi,
		   ct.ColumnMerge,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
           bm.TinhTrangQuyHoach,
           bm.TinhTrangHoatDong,
           bm.CongSuatThietKe,
           bm.CongSuatHoatDong,
           bm.ChatLuongNuocThai,
           bm.ChatLuongNuocThaiSauXL,
           bm.TinhTrangLapDat,
           bm.ChuaCo_NNguyenNhan,
           bm.ChuaCo_ThoiGianDuKien,
           bm.ChuaCo_GiaiPhapXL
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau5 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0
    

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           tmp.Id,
           tmp.CauTrucGUID,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,
           tmp.TinhTrangQuyHoach,
		   dm.NoiDung AS TinhTrangQuyHoachName,
           tmp.TinhTrangHoatDong,
		   dm2.NoiDung AS TinhTrangHoatDongName,
           tmp.CongSuatThietKe,
           tmp.CongSuatHoatDong,
           tmp.ChatLuongNuocThai,
		   dm3.NoiDung AS ChatLuongNuocThaiName,
           tmp.ChatLuongNuocThaiSauXL,
		   dm4.NoiDung AS ChatLuongNuocThaiSauXLName,
           tmp.TinhTrangLapDat,
		   dm5.NoiDung AS TinhTrangLapDatName,
           tmp.ChuaCo_NNguyenNhan,
           tmp.ChuaCo_ThoiGianDuKien,
           tmp.ChuaCo_GiaiPhapXL
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm ON dm.LoaiDanhMuc = 'TTQH' AND dm.Ma = tmp.TinhTrangQuyHoach
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm2 ON dm2.LoaiDanhMuc = 'TTHD' AND dm2.Ma = tmp.TinhTrangHoatDong
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm3 ON dm3.LoaiDanhMuc = 'CLNTSXLNT' AND dm3.Ma = tmp.ChatLuongNuocThai
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm4 ON dm4.LoaiDanhMuc = 'CLNTSXL' AND dm4.Ma = tmp.ChatLuongNuocThaiSauXL
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm5 ON dm5.LoaiDanhMuc = 'TTLDNT' AND dm5.Ma = tmp.TinhTrangLapDat
	ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM06_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_BCDT_BM06_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN

    -- Thay giá trị này nếu mã biểu mẫu khác
    DECLARE @maBieuMau NVARCHAR(50) = N'06NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1) Parse JSON -> table variable
            ----------------------------------------------------------
            DECLARE @TableDuLieu TABLE
            (
                Id INT,
				DonViId INT,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
				SoThuTu INT,
				BieuMauId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				CauTrucGUID UNIQUEIDENTIFIER,
                TongSoLD INT,
                GioiTinh_Nam INT,
                GioiTinh_Nu INT,
                TD_PhoThong INT,
                TD_SoCap INT,
                TD_TrungCap INT,
                TD_CaoDang INT,
                TD_DaiHoc INT,
                TD_TrenDaiHoc INT,
                TD_Khac INT
            );

            INSERT INTO @TableDuLieu
            (
                Id, KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                TongSoLD, GioiTinh_Nam, GioiTinh_Nu, TD_PhoThong, TD_SoCap,
                TD_TrungCap, TD_CaoDang, TD_DaiHoc, TD_TrenDaiHoc, TD_Khac, CauTrucGUID,
				TieuChiId, TenTieuChi, BieuMauId, SoThuTu, DonViId
            )
            SELECT
                Id,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
                TongSoLD,
                GioiTinh_Nam,
                GioiTinh_Nu,
                TD_PhoThong,
                TD_SoCap,
                TD_TrungCap,
                TD_CaoDang,
                TD_DaiHoc,
                TD_TrenDaiHoc,
                TD_Khac,
				CauTrucGUID,
				TieuChiId,
				TenTieuChi,
				BieuMauId,
				SoThuTu, 
				DonViId
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
                Id INT '$.Id',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
                TongSoLD INT '$.TongSoLD',
                GioiTinh_Nam INT '$.GioiTinh_Nam',
                GioiTinh_Nu INT '$.GioiTinh_Nu',
                TD_PhoThong INT '$.TD_PhoThong',
                TD_SoCap INT '$.TD_SoCap',
                TD_TrungCap INT '$.TD_TrungCap',
                TD_CaoDang INT '$.TD_CaoDang',
                TD_DaiHoc INT '$.TD_DaiHoc',
                TD_TrenDaiHoc INT '$.TD_TrenDaiHoc',
                TD_Khac INT '$.TD_Khac',
                CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi',
                BieuMauId INT '$.BieuMauId',
                SoThuTu INT '$.SoThuTu',
                DonViId INT '$.DonViId'
            );
			SELECT * FROM @TableDuLieu;
            ----------------------------------------------------------
            -- 2) Chuẩn bị nguồn (Src) cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    MaBieuMau      = @maBieuMau,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
                    TongSoLD,
                    GioiTinh_Nam,
                    GioiTinh_Nu,
                    TD_PhoThong,
                    TD_SoCap,
                    TD_TrungCap,
                    TD_CaoDang,
                    TD_DaiHoc,
                    TD_TrenDaiHoc,
                    TD_Khac,
					CauTrucGUID,
					TieuChiId, 
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
					BieuMauId,
					SoThuTu, 
                    NguoiCapNhat   = @NguoiDungId
                FROM @TableDuLieu
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            ----------------------------------------------------------
            -- 3) MERGE -> Update | Insert
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau6 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID     = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN            = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id    = S.LoaiHinhKKTKCN_Id,
                    T.TongSoLD             = S.TongSoLD,
                    T.GioiTinh_Nam         = S.GioiTinh_Nam,
                    T.GioiTinh_Nu          = S.GioiTinh_Nu,
                    T.TD_PhoThong          = S.TD_PhoThong,
                    T.TD_SoCap             = S.TD_SoCap,
                    T.TD_TrungCap          = S.TD_TrungCap,
                    T.TD_CaoDang           = S.TD_CaoDang,
                    T.TD_DaiHoc            = S.TD_DaiHoc,
                    T.TD_TrenDaiHoc        = S.TD_TrenDaiHoc,
                    T.TD_Khac              = S.TD_Khac,
                    T.BitDaXoa             = 0,                -- khôi phục nếu đã xoá
                    T.NguoiSua             = S.NguoiCapNhat,
                    T.NgaySua              = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    BieuMauId, MaBieuMau, TieuChiId, MaTieuChi, TenTieuChi,CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    TongSoLD, GioiTinh_Nam, GioiTinh_Nu,
                    TD_PhoThong, TD_SoCap, TD_TrungCap, TD_CaoDang,
                    TD_DaiHoc, TD_TrenDaiHoc, TD_Khac,
                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES
                (
                    S.BieuMauId, S.MaBieuMau,S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.TongSoLD, S.GioiTinh_Nam, S.GioiTinh_Nu,
                    S.TD_PhoThong, S.TD_SoCap, S.TD_TrungCap, S.TD_CaoDang,
                    S.TD_DaiHoc, S.TD_TrenDaiHoc, S.TD_Khac,
                    S.NguoiCapNhat, GETDATE(), 0
                );

            ----------------------------------------------------------
            -- 4) ĐÁNH DẤU XÓA MỀM theo CẤU TRÚC BIỂU MẪU (fn_BCDT_GetCauTrucBieuMau)
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau6 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGUID
               AND ISNULL(T.MaBieuMau, @maBieuMau) = CT.MaBieuMau
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM06_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 05
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM06_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.[TongSoLD],
           bm.[GioiTinh_Nam],
           bm.[GioiTinh_Nu],
           bm.[TD_PhoThong],
           bm.[TD_SoCap],
           bm.[TD_TrungCap],
           bm.[TD_CaoDang],
           bm.[TD_DaiHoc],
           bm.[TD_TrenDaiHoc],
           bm.[TD_Khac]
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau6 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,
           tmp.[TongSoLD],
           tmp.[GioiTinh_Nam],
           tmp.[GioiTinh_Nu],
           tmp.[TD_PhoThong],
           tmp.[TD_SoCap],
           tmp.[TD_TrungCap],
           tmp.[TD_CaoDang],
           tmp.[TD_DaiHoc],
           tmp.[TD_TrenDaiHoc],
           tmp.[TD_Khac]
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.TieuChiId = tmp.TieuChiId
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM07_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 07
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM07_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'07NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            DECLARE @TableDuLieu TABLE
            (
                Id INT,
                CauTrucGUID UNIQUEIDENTIFIER,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
                DiaDiem NVARCHAR(2000),
                QuyMo DECIMAL(24,3),
                VanBanPhuongAn NVARCHAR(200),
                VanBanPheDuyet NVARCHAR(200),
                VanBanThanhLap NVARCHAR(200),
                QuyMoChapThuan DECIMAL(24,3),
                QuyMoConLai DECIMAL(24,3)
            );

            INSERT INTO @TableDuLieu
            (
                Id, CauTrucGUID, TieuChiId, TenTieuChi, KKTKCN_Id, KKTKCN_Ma, TenKKTKCN,
                LoaiHinhKKTKCN_Id, DiaDiem, QuyMo, VanBanPhuongAn,
                VanBanPheDuyet, VanBanThanhLap, QuyMoChapThuan, QuyMoConLai
            )
            SELECT
                Id,
                CauTrucGUID,
				TieuChiId,
				TenTieuChi,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
                DiaDiem,
                QuyMo,
                VanBanPhuongAn,
                VanBanPheDuyet,
                VanBanThanhLap,
                QuyMoChapThuan,
                QuyMoConLai
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
                Id INT '$.Id',
                CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
				TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
                DiaDiem NVARCHAR(2000) '$.DiaDiem',
                QuyMo DECIMAL(24,3) '$.QuyMo',
                VanBanPhuongAn NVARCHAR(200) '$.VanBanPhuongAn',
                VanBanPheDuyet NVARCHAR(200) '$.VanBanPheDuyet',
                VanBanThanhLap NVARCHAR(200) '$.VanBanThanhLap',
                QuyMoChapThuan DECIMAL(24,3) '$.QuyMoChapThuan',
                QuyMoConLai DECIMAL(24,3) '$.QuyMoConLai'
            );

            ----------------------------------------------------------
            -- 2. Chuẩn bị dữ liệu nguồn cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId      = (SELECT TOP(1) Id FROM dbo.BCDT_DanhMuc_BieuMau WHERE MaBieuMau = @maBieuMau),
                    MaBieuMau      = @maBieuMau,
					TieuChiId,
					TenTieuChi,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
                    CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
                    DiaDiem,
                    QuyMo,
                    VanBanPhuongAn,
                    VanBanPheDuyet,
                    VanBanThanhLap,
                    QuyMoChapThuan,
                    QuyMoConLai,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TableDuLieu
                WHERE ISNULL(TieuChiId, 0) <> 0
            )

            ----------------------------------------------------------
            -- 3. MERGE: Update hoặc Insert mới
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau7 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
                    T.KKTKCN_Id             = S.KKTKCN_Id,
                    T.KKTKCN_Ma             = S.KKTKCN_Ma,
                    T.TenKKTKCN             = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id     = S.LoaiHinhKKTKCN_Id,
                    T.DiaDiem               = S.DiaDiem,
                    T.QuyMo                 = S.QuyMo,
                    T.VanBanPhuongAn        = S.VanBanPhuongAn,
                    T.VanBanPheDuyet        = S.VanBanPheDuyet,
                    T.VanBanThanhLap        = S.VanBanThanhLap,
                    T.QuyMoChapThuan        = S.QuyMoChapThuan,
                    T.QuyMoConLai           = S.QuyMoConLai,
                    T.BitDaXoa              = 0,
                    T.NguoiSua              = S.NguoiCapNhat,
                    T.NgaySua               = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    BieuMauId, TieuChiId,MaTieuChi,TenTieuChi, MaBieuMau, CauTrucGUID,
                    DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    DiaDiem, QuyMo, VanBanPhuongAn, VanBanPheDuyet, VanBanThanhLap,
                    QuyMoChapThuan, QuyMoConLai,
                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES
                (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID,
                    S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.DiaDiem, S.QuyMo, S.VanBanPhuongAn, S.VanBanPheDuyet, S.VanBanThanhLap,
                    S.QuyMoChapThuan, S.QuyMoConLai,
                    S.NguoiCapNhat, GETDATE(), 0
                );

            ----------------------------------------------------------
            -- 4. Đánh dấu xóa mềm nếu cấu trúc bị xóa
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau7 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM07_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 05
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM07_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;
	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.[DiaDiem],
           bm.[QuyMo],
           bm.[VanBanPhuongAn],
           bm.[VanBanPheDuyet],
           bm.[VanBanThanhLap],
           bm.[QuyMoChapThuan],
           bm.[QuyMoConLai]
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau7 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0;

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           tmp.Id,
           tmp.CauTrucGUID,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,
           kcn.DiaChi as DiaDiem,
           vb1.TongDienTich as QuyMo,
           vb1.SoKyHieu + N', ngày ' + FORMAT(vb1.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS VanBanPhuongAn,
           vb5.SoKyHieu + N', ngày ' + FORMAT(vb5.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS VanBanPheDuyet,
           vb2.SoKyHieu + N', ngày ' + FORMAT(vb2.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS VanBanThanhLap,
           tmp.[QuyMoChapThuan],
           tmp.[QuyMoConLai]
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.TieuChiId = tmp.TieuChiId
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.TongDienTich,
	v.KhuPhiThueQuan,
	v.KhuCheXuatCongNghiep,
	v.KhuGiaiTriDuLich,
	v.KhuDoThiDanCu,
	v.KhuHanhChinhKhac,
	v.DatKhac,
	v.NgayBanHanh
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 1
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb1
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.TongDienTich,
	v.KhuPhiThueQuan,
	v.KhuCheXuatCongNghiep,
	v.KhuGiaiTriDuLich,
	v.KhuDoThiDanCu,
	v.KhuHanhChinhKhac,
	v.DatKhac,
	v.NgayBanHanh
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.TongDienTich,
	v.KhuPhiThueQuan,
	v.KhuCheXuatCongNghiep,
	v.KhuGiaiTriDuLich,
	v.KhuDoThiDanCu,
	v.KhuHanhChinhKhac,
	v.DatKhac,
	v.NgayBanHanh
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 5
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb5
	ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM08_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 08
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM08_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'08NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),

                TongDienTich DECIMAL(24,3),
                PhiThueQuan DECIMAL(24,3),
                CheXuat DECIMAL(24,3),
                GiaiTri DECIMAL(24,3),
                DoThi DECIMAL(24,3),
                HanhChinh DECIMAL(24,3),
                Khac DECIMAL(24,3)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				TenTieuChi,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,

                TongDienTich,
				PhiThueQuan,
				CheXuat,
				GiaiTri,
				DoThi,
				HanhChinh,
				Khac
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',

                TongDienTich DECIMAL(24,3) '$.TongDienTich',
				PhiThueQuan DECIMAL(24,3) '$.PhiThueQuan',
				CheXuat DECIMAL(24,3) '$.CheXuat',
				GiaiTri DECIMAL(24,3) '$.GiaiTri',
				DoThi DECIMAL(24,3) '$.DoThi',
				HanhChinh DECIMAL(24,3) '$.HanhChinh',
				Khac DECIMAL(24,3) '$.Khac'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
                    TongDienTich,
					PhiThueQuan,
					CheXuat,
					GiaiTri,
					DoThi,
					HanhChinh,
					Khac,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau8 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN            = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id    = S.LoaiHinhKKTKCN_Id,

                    T.TongDienTich      = S.TongDienTich,
                    T.PhiThueQuan		= S.PhiThueQuan,
                    T.CheXuat			= S.CheXuat,
                    T.GiaiTri			= S.GiaiTri,
                    T.DoThi				= S.DoThi,
                    T.HanhChinh			= S.HanhChinh,
                    T.Khac				= S.Khac,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, MaBieuMau, TieuChiId, MaTieuChi, TenTieuChi, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    TongDienTich,
					PhiThueQuan,
					CheXuat,
					GiaiTri,
					DoThi,
					HanhChinh,
					Khac,
                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.MaBieuMau, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.TongDienTich,
					S.PhiThueQuan,
					S.CheXuat,
					S.GiaiTri,
					S.DoThi,
					S.HanhChinh,
					S.Khac,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau8 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM08_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 08
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM08_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.TongDienTich,
           bm.PhiThueQuan,
           bm.CheXuat,
           bm.GiaiTri,
           bm.DoThi,
           bm.HanhChinh,
           bm.Khac
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau8 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,
		   ISNULL(vb.TongDienTich, tmp.TongDienTich) AS TongDienTich,
		   ISNULL(vb.KhuPhiThueQuan, tmp.PhiThueQuan) AS PhiThueQuan,
		   ISNULL(vb.KhuCheXuatCongNghiep, tmp.CheXuat) AS CheXuat,
		   ISNULL(vb.KhuGiaiTriDuLich, tmp.GiaiTri) AS GiaiTri,
		   ISNULL(vb.KhuDoThiDanCu, tmp.DoThi) AS DoThi,
		   ISNULL(vb.KhuHanhChinhKhac, tmp.HanhChinh) AS HanhChinh,
		   ISNULL(vb.DatKhac, tmp.Khac) AS Khac
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.TieuChiId = tmp.TieuChiId
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.TongDienTich,
	v.KhuPhiThueQuan,
	v.KhuCheXuatCongNghiep,
	v.KhuGiaiTriDuLich,
	v.KhuDoThiDanCu,
	v.KhuHanhChinhKhac,
	v.DatKhac,
	v.NgayBanHanh
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 3
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM09_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 01
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_BM09_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'09NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1. Parse JSON -> Table variable
            ----------------------------------------------------------
            DECLARE @TableKeHoachDuAn TABLE
            (
                Id INT,
                DonViId INT,
                TieuChiId INT,
				TenTieuChi NVARCHAR(2000),
                SoThuTu INT,
                BieuMauId INT,
                CauTrucGUID UNIQUEIDENTIFIER,
				KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
                Ngoai_KCN_Trong_KKT DECIMAL(24,3) NULL,
                KCN_Trong_KKT DECIMAL(24,3) NULL
            );

            INSERT INTO @TableKeHoachDuAn
            (
                Id, DonViId, TieuChiId, TenTieuChi, SoThuTu, BieuMauId, CauTrucGUID, KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                Ngoai_KCN_Trong_KKT, KCN_Trong_KKT
            )
            SELECT
                Id,
                DonViId,
                TieuChiId,
				TenTieuChi,
                SoThuTu,
                BieuMauId,
                CauTrucGUID,
				KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
                Ngoai_KCN_Trong_KKT,
                KCN_Trong_KKT
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
                Id INT '$.Id',               
                DonViId INT '$.DonViId',
                TieuChiId INT '$.TieuChiId',
				TenTieuChi NVARCHAR(2000) '$.TenTieuChi',
                SoThuTu INT '$.SoThuTu',
                BieuMauId INT '$.BieuMauId',
                CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
				KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
                Ngoai_KCN_Trong_KKT DECIMAL(24,3) '$.Ngoai_KCN_Trong_KKT',
                KCN_Trong_KKT DECIMAL(24,3) '$.KCN_Trong_KKT'
            );
            ----------------------------------------------------------
            -- 2. Chuẩn bị dữ liệu nguồn cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
                    MaBieuMau      = @maBieuMau,
                    TieuChiId,
                    MaTieuChi      = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
                    SoThuTu,
                    CauTrucGUID,
					KKTKCN_Id,
					KKTKCN_Ma,
					TenKKTKCN,
					LoaiHinhKKTKCN_Id,
                    Ngoai_KCN_Trong_KKT,
                    KCN_Trong_KKT,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TableKeHoachDuAn
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            ----------------------------------------------------------
            -- 3. MERGE: Update hoặc Insert mới
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau9 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
				AND T.KKTKCN_Id   = S.KKTKCN_Id
            WHEN MATCHED THEN
                UPDATE SET
                    T.TieuChiId         = S.TieuChiId,
                    T.SoThuTu           = S.SoThuTu,
                    T.BieuMauId         = S.BieuMauId,
                    T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
                    T.Ngoai_KCN_Trong_KKT  = S.Ngoai_KCN_Trong_KKT,
                    T.KCN_Trong_KKT       = S.KCN_Trong_KKT,
					T.KKTKCN_Id = S.KKTKCN_Id,
                    T.KKTKCN_Ma       = S.KKTKCN_Ma,
                    T.TenKKTKCN    = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id          = S.LoaiHinhKKTKCN_Id,
                    T.BitDaXoa          = 0,
                    T.NguoiSua          = S.NguoiCapNhat,
                    T.NgaySua           = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    BieuMauId, MaBieuMau, DotKeHoach_Id, KeHoachId, DonViId,
                    TieuChiId, MaTieuChi, TenTieuChi, SoThuTu, CauTrucGUID,
                    Ngoai_KCN_Trong_KKT, KCN_Trong_KKT, KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES
                (
                    S.BieuMauId, S.MaBieuMau, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.SoThuTu, S.CauTrucGUID,
                    S.Ngoai_KCN_Trong_KKT, S.KCN_Trong_KKT, S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.NguoiCapNhat, GETDATE(), 0
                );

            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau9 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId
			  AND T.KKTKCN_Id = (SELECT TOP(1) KKTKCN_Id FROM @TableKeHoachDuAn);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM09_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 09
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_BM09_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50),
	@KKTKCN_Id INT
AS
BEGIN
	declare @KKTKCN_Ma nvarchar(50);
	declare @TenKKTKCN nvarchar(500);
	declare @LoaiHinhKKTKCN_Id nvarchar(50);
	select @KKTKCN_Ma = MaKKTKCN, @TenKKTKCN = TenKKTKCN, @LoaiHinhKKTKCN_Id = LoaiHinhId from BCDT_TieuChi_KKTKCN where id = @KKTKCN_Id and BitDaXoa = 0;
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           CONCAT_WS(' ', ct.SoThuTuHienThi, ct.TenTieuChi) AS TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
           ct.Style,
           ct.DonViTinh,
           (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
           ISNULL(bm.Ngoai_KCN_Trong_KKT, 0) AS Ngoai_KCN_Trong_KKT,
           ISNULL(bm.KCN_Trong_KKT, 0) AS KCN_Trong_KKT,
		   @KKTKCN_Id as KKTKCN_Id,
		   ISNULL(bm.KKTKCN_Ma, @KKTKCN_Ma) AS KKTKCN_Ma,
		   ISNULL(bm.TenKKTKCN, @TenKKTKCN) AS TenKKTKCN,
		   ISNULL(bm.LoaiHinhKKTKCN_Id, @LoaiHinhKKTKCN_Id) AS LoaiHinhKKTKCN_Id
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau9 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
			   AND bm.KKTKCN_Id = @KKTKCN_Id
    WHERE ct.BitDaXoa = 0
    ORDER BY ct.Path;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM10_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 10
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM10_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'10NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				TenTieuChi NVARCHAR(2000),
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),

				QuyetDinhPheDuyet nvarchar(200),
				QuyMo DECIMAL(24,3),
				KPTQ_QuyMo DECIMAL(24,3),
				KPTQ_QuyMoLap DECIMAL(24,3),
				KPTQ_QuyMoXayDung DECIMAL(24,3),
				KCX_QuyMo DECIMAL(24,3),
				KCX_QuyMoLap DECIMAL(24,3),
				KCX_QuyMoXayDung DECIMAL(24,3),
				KCX_QuyMoChoThue DECIMAL(24,3),
				KGT_QuyMo DECIMAL(24,3),
				KGT_QuyMoLap DECIMAL(24,3),
				KGT_QuyMoXayDung DECIMAL(24,3),
				KDT_QuyMo DECIMAL(24,3),
				KDT_QuyMoLap DECIMAL(24,3),
				KDT_QuyMoXayDung DECIMAL(24,3),
				KHC_QuyMo DECIMAL(24,3),
				KHC_QuyMoLap DECIMAL(24,3),
				KHC_QuyMoXayDung DECIMAL(24,3),
				DatKhac DECIMAL(24,3),
				ChuaSuDung DECIMAL(24,3)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				TenTieuChi,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,

                QuyetDinhPheDuyet,
				QuyMo,
				KPTQ_QuyMo,
				KPTQ_QuyMoLap,
				KPTQ_QuyMoXayDung,
				KCX_QuyMo,
				KCX_QuyMoLap,
				KCX_QuyMoXayDung,
				KCX_QuyMoChoThue,
				KGT_QuyMo,
				KGT_QuyMoLap,
				KGT_QuyMoXayDung,
				KDT_QuyMo,
				KDT_QuyMoLap,
				KDT_QuyMoXayDung,
				KHC_QuyMo,
				KHC_QuyMoLap,
				KHC_QuyMoXayDung,
				DatKhac,
				ChuaSuDung
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				TenTieuChi NVARCHAR(2000) '$.TenTieuChi',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',

                QuyetDinhPheDuyet nvarchar(200) '$.QuyetDinhPheDuyet',
				QuyMo DECIMAL(24,3) '$.QuyMo',
				KPTQ_QuyMo DECIMAL(24,3) '$.KPTQ_QuyMo',
				KPTQ_QuyMoLap DECIMAL(24,3) '$.KPTQ_QuyMoLap',
				KPTQ_QuyMoXayDung DECIMAL(24,3) '$.KPTQ_QuyMoXayDung',
				KCX_QuyMo DECIMAL(24,3) '$.KCX_QuyMo',
				KCX_QuyMoLap DECIMAL(24,3) '$.KCX_QuyMoLap',
				KCX_QuyMoXayDung DECIMAL(24,3) '$.KCX_QuyMoXayDung',
				KCX_QuyMoChoThue DECIMAL(24,3) '$.KCX_QuyMoChoThue',
				KGT_QuyMo DECIMAL(24,3) '$.KGT_QuyMo',
				KGT_QuyMoLap DECIMAL(24,3) '$.KGT_QuyMoLap',
				KGT_QuyMoXayDung DECIMAL(24,3) '$.KGT_QuyMoXayDung',
				KDT_QuyMo DECIMAL(24,3) '$.KDT_QuyMo',
				KDT_QuyMoLap DECIMAL(24,3) '$.KDT_QuyMoLap',
				KDT_QuyMoXayDung DECIMAL(24,3) '$.KDT_QuyMoXayDung',
				KHC_QuyMo DECIMAL(24,3) '$.KHC_QuyMo',
				KHC_QuyMoLap DECIMAL(24,3) '$.KHC_QuyMoLap',
				KHC_QuyMoXayDung DECIMAL(24,3) '$.KHC_QuyMoXayDung',
				DatKhac DECIMAL(24,3) '$.DatKhac',
				ChuaSuDung DECIMAL(24,3) '$.ChuaSuDung'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi      = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,

                    QuyetDinhPheDuyet,
					QuyMo,
					KPTQ_QuyMo,
					KPTQ_QuyMoLap,
					KPTQ_QuyMoXayDung,
					KCX_QuyMo,
					KCX_QuyMoLap,
					KCX_QuyMoXayDung,
					KCX_QuyMoChoThue,
					KGT_QuyMo,
					KGT_QuyMoLap,
					KGT_QuyMoXayDung,
					KDT_QuyMo,
					KDT_QuyMoLap,
					KDT_QuyMoXayDung,
					KHC_QuyMo,
					KHC_QuyMoLap,
					KHC_QuyMoXayDung,
					DatKhac,
					ChuaSuDung,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau10 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.KKTKCN_Id              = S.KKTKCN_Id,
					T.KKTKCN_Ma              = S.KKTKCN_Ma,
                    T.TenKKTKCN              = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id      = S.LoaiHinhKKTKCN_Id,
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,

                    T.QuyetDinhPheDuyet = S.QuyetDinhPheDuyet,
					T.QuyMo = S.QuyMo,
					T.KPTQ_QuyMo = S.KPTQ_QuyMo,
					T.KPTQ_QuyMoLap = S.KPTQ_QuyMoLap,
					T.KPTQ_QuyMoXayDung = S.KPTQ_QuyMoXayDung,
					T.KCX_QuyMo = S.KCX_QuyMo,
					T.KCX_QuyMoLap = S.KCX_QuyMoLap,
					T.KCX_QuyMoXayDung = S.KCX_QuyMoXayDung,
					T.KCX_QuyMoChoThue = S.KCX_QuyMoChoThue,
					T.KGT_QuyMo = S.KGT_QuyMo,
					T.KGT_QuyMoLap = S.KGT_QuyMoLap,
					T.KGT_QuyMoXayDung = S.KGT_QuyMoXayDung,
					T.KDT_QuyMo = S.KDT_QuyMo,
					T.KDT_QuyMoLap = S.KDT_QuyMoLap,
					T.KDT_QuyMoXayDung = S.KDT_QuyMoXayDung,
					T.KHC_QuyMo = S.KHC_QuyMo,
					T.KHC_QuyMoLap = S.KHC_QuyMoLap,
					T.KHC_QuyMoXayDung = S.KHC_QuyMoXayDung,
					T.DatKhac = S.DatKhac,
					T.ChuaSuDung = S.ChuaSuDung,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, MaBieuMau, TieuChiId, MaTieuChi, TenTieuChi, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    
					QuyetDinhPheDuyet,
					QuyMo,
					KPTQ_QuyMo,
					KPTQ_QuyMoLap,
					KPTQ_QuyMoXayDung,
					KCX_QuyMo,
					KCX_QuyMoLap,
					KCX_QuyMoXayDung,
					KCX_QuyMoChoThue,
					KGT_QuyMo,
					KGT_QuyMoLap,
					KGT_QuyMoXayDung,
					KDT_QuyMo,
					KDT_QuyMoLap,
					KDT_QuyMoXayDung,
					KHC_QuyMo,
					KHC_QuyMoLap,
					KHC_QuyMoXayDung,
					DatKhac,
					ChuaSuDung,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.MaBieuMau, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.QuyetDinhPheDuyet,
					S.QuyMo,
					S.KPTQ_QuyMo,
					S.KPTQ_QuyMoLap,
					S.KPTQ_QuyMoXayDung,
					S.KCX_QuyMo,
					S.KCX_QuyMoLap,
					S.KCX_QuyMoXayDung,
					S.KCX_QuyMoChoThue,
					S.KGT_QuyMo,
					S.KGT_QuyMoLap,
					S.KGT_QuyMoXayDung,
					S.KDT_QuyMo,
					S.KDT_QuyMoLap,
					S.KDT_QuyMoXayDung,
					S.KHC_QuyMo,
					S.KHC_QuyMoLap,
					S.KHC_QuyMoXayDung,
					S.DatKhac,
					S.ChuaSuDung,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau10 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM10_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 10
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM10_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.QuyetDinhPheDuyet,
			bm.QuyMo,
			bm.KPTQ_QuyMo,
			bm.KPTQ_QuyMoLap,
			bm.KPTQ_QuyMoXayDung,
			bm.KCX_QuyMo,
			bm.KCX_QuyMoLap,
			bm.KCX_QuyMoXayDung,
			bm.KCX_QuyMoChoThue,
			bm.KGT_QuyMo,
			bm.KGT_QuyMoLap,
			bm.KGT_QuyMoXayDung,
			bm.KDT_QuyMo,
			bm.KDT_QuyMoLap,
			bm.KDT_QuyMoXayDung,
			bm.KHC_QuyMo,
			bm.KHC_QuyMoLap,
			bm.KHC_QuyMoXayDung,
			bm.DatKhac,
			bm.ChuaSuDung
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau10 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   vb.SoKyHieu + N', ngày ' + FORMAT(vb.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS QuyetDinhPheDuyet,
		   vb.TongDienTich AS QuyMo,
		   ISNULL(vb.KhuPhiThueQuan, tmp.KPTQ_QuyMo) AS KPTQ_QuyMo,
		   ISNULL(vb.KhuCheXuatCongNghiep, tmp.KCX_QuyMo) AS KCX_QuyMo,
		   ISNULL(vb.KhuGiaiTriDuLich, tmp.KGT_QuyMo) AS KGT_QuyMo,
		   ISNULL(vb.KhuDoThiDanCu, tmp.KDT_QuyMo) AS KDT_QuyMo,
		   ISNULL(vb.KhuHanhChinhKhac, tmp.KHC_QuyMo) AS KHC_QuyMo,
		   ISNULL(vb.DatKhac, tmp.DatKhac) AS DatKhac,
			tmp.KPTQ_QuyMoLap,
			tmp.KPTQ_QuyMoXayDung,
			tmp.KCX_QuyMoLap,
			tmp.KCX_QuyMoXayDung,
			tmp.KCX_QuyMoChoThue,
			tmp.KGT_QuyMoLap,
			tmp.KGT_QuyMoXayDung,
			tmp.KDT_QuyMoLap,
			tmp.KDT_QuyMoXayDung,
			tmp.KHC_QuyMoLap,
			tmp.KHC_QuyMoXayDung,
			tmp.ChuaSuDung
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.TieuChiId = tmp.TieuChiId
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.TongDienTich,
	v.KhuPhiThueQuan,
	v.KhuCheXuatCongNghiep,
	v.KhuGiaiTriDuLich,
	v.KhuDoThiDanCu,
	v.KhuHanhChinhKhac,
	v.DatKhac,
	v.NgayBanHanh
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 3
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM11_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 11
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM11_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'11NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				DuAnId INT,
				MaDuAn nvarchar(50),
				TenDuAn nvarchar(2000),
				TenTieuChi nvarchar(2000),

				DiaDiem nvarchar(2000),
				VanBanThanhLap nvarchar(200),
				TenNhaDauTu nvarchar(200),
				QuocTichNhaDauTu nvarchar(200),
				TinhTrang int,
				QuyMoQuyHoach decimal(24, 3),
				QuyMoThanhLap decimal(24, 3),
				QuyMoHoatDong decimal(24, 3),
				NN_VonDauTuDangKy decimal(24, 3),
				NN_VonDauTu decimal(24, 3),
				TN_VonDauTuDangKy decimal(24, 3),
				TN_VonDauTu decimal(24, 3),
				SXKD_DoanhThu decimal(24, 3),
				SXKD_XuatKhau decimal(24, 3),
				SXKD_NhapKhau decimal(24, 3),
				SXKD_NopNganSach decimal(24, 3)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
				DuAnId,
				MaDuAn,
				TenDuAn,
				TenTieuChi,

				DiaDiem,
				VanBanThanhLap,
				TenNhaDauTu,
				QuocTichNhaDauTu,
				TinhTrang,
				QuyMoQuyHoach,
				QuyMoThanhLap,
				QuyMoHoatDong,
				NN_VonDauTuDangKy,
				NN_VonDauTu,
				TN_VonDauTuDangKy,
				TN_VonDauTu,
				SXKD_DoanhThu,
				SXKD_XuatKhau,
				SXKD_NhapKhau,
				SXKD_NopNganSach
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
				DuAnId INT '$.DuAnId', 
				MaDuAn nvarchar(50) '$.MaDuAn', 
				TenDuAn nvarchar(2000) '$.TenDuAn', 
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 
				DiaDiem nvarchar(2000) '$.DiaDiem',
				VanBanThanhLap nvarchar(200) '$.VanBanThanhLap',
				TenNhaDauTu nvarchar(200) '$.TenNhaDauTu',
				QuocTichNhaDauTu nvarchar(200) '$.QuocTichNhaDauTu',
				TinhTrang int '$.TinhTrang',
				QuyMoQuyHoach decimal(24, 3) '$.QuyMoQuyHoach',
				QuyMoThanhLap decimal(24, 3) '$.QuyMoThanhLap',
				QuyMoHoatDong decimal(24, 3) '$.QuyMoHoatDong',
				NN_VonDauTuDangKy decimal(24, 3) '$.NN_VonDauTuDangKy',
				NN_VonDauTu decimal(24, 3) '$.NN_VonDauTu',
				TN_VonDauTuDangKy decimal(24, 3) '$.TN_VonDauTuDangKy',
				TN_VonDauTu decimal(24, 3) '$.TN_VonDauTu',
				SXKD_DoanhThu decimal(24, 3) '$.SXKD_DoanhThu',
				SXKD_XuatKhau decimal(24, 3) '$.SXKD_XuatKhau',
				SXKD_NhapKhau decimal(24, 3) '$.SXKD_NhapKhau',
				SXKD_NopNganSach decimal(24, 3) '$.SXKD_NopNganSach'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi      = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
					DuAnId,
					MaDuAn,
					TenDuAn,

					DiaDiem,
					VanBanThanhLap,
					TenNhaDauTu,
					QuocTichNhaDauTu,
					TinhTrang,
					QuyMoQuyHoach,
					QuyMoThanhLap,
					QuyMoHoatDong,
					NN_VonDauTuDangKy,
					NN_VonDauTu,
					TN_VonDauTuDangKy,
					TN_VonDauTu,
					SXKD_DoanhThu,
					SXKD_XuatKhau,
					SXKD_NhapKhau,
					SXKD_NopNganSach,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau11 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id              = S.KKTKCN_Id,
					T.KKTKCN_Ma              = S.KKTKCN_Ma,
                    T.TenKKTKCN              = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id      = S.LoaiHinhKKTKCN_Id,
					T.DuAnId					= S.DuAnId,
					T.MaDuAn					= S.MaDuAn,
					T.TenDuAn					= S.TenDuAn, 

                    T.DiaDiem = S.DiaDiem,
					T.VanBanThanhLap = S.VanBanThanhLap,
					T.TenNhaDauTu = S.TenNhaDauTu,
					T.QuocTichNhaDauTu = S.QuocTichNhaDauTu,
					T.TinhTrang = S.TinhTrang,
					T.QuyMoQuyHoach = S.QuyMoQuyHoach,
					T.QuyMoThanhLap = S.QuyMoThanhLap,
					T.QuyMoHoatDong = S.QuyMoHoatDong,
					T.NN_VonDauTuDangKy = S.NN_VonDauTuDangKy,
					T.NN_VonDauTu = S.NN_VonDauTu,
					T.TN_VonDauTuDangKy = S.TN_VonDauTuDangKy,
					T.TN_VonDauTu = S.TN_VonDauTu,
					T.SXKD_DoanhThu = S.SXKD_DoanhThu,
					T.SXKD_XuatKhau = S.SXKD_XuatKhau,
					T.SXKD_NhapKhau = S.SXKD_NhapKhau,
					T.SXKD_NopNganSach = S.SXKD_NopNganSach,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, TieuChiId, MaTieuChi, TenTieuChi, MaBieuMau, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,DuAnId ,MaDuAn, TenDuAn,
                    DiaDiem,
					VanBanThanhLap,
					TenNhaDauTu,
					QuocTichNhaDauTu,
					TinhTrang,
					QuyMoQuyHoach,
					QuyMoThanhLap,
					QuyMoHoatDong,
					NN_VonDauTuDangKy,
					NN_VonDauTu,
					TN_VonDauTuDangKy,
					TN_VonDauTu,
					SXKD_DoanhThu,
					SXKD_XuatKhau,
					SXKD_NhapKhau,
					SXKD_NopNganSach,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,S.DuAnId ,S.MaDuAn, TenDuAn,
                    S.DiaDiem,
					S.VanBanThanhLap,
					S.TenNhaDauTu,
					S.QuocTichNhaDauTu,
					S.TinhTrang,
					S.QuyMoQuyHoach,
					S.QuyMoThanhLap,
					S.QuyMoHoatDong,
					S.NN_VonDauTuDangKy,
					S.NN_VonDauTu,
					S.TN_VonDauTuDangKy,
					S.TN_VonDauTu,
					S.SXKD_DoanhThu,
					S.SXKD_XuatKhau,
					S.SXKD_NhapKhau,
					S.SXKD_NopNganSach,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau11 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM11_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 11
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM11_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
			bm.DiaDiem,
			bm.VanBanThanhLap,
			bm.TenNhaDauTu,
			bm.QuocTichNhaDauTu,
			bm.TinhTrang,
			bm.QuyMoQuyHoach,
			bm.QuyMoThanhLap,
			bm.QuyMoHoatDong,
			bm.NN_VonDauTuDangKy,
			bm.NN_VonDauTu,
			bm.TN_VonDauTuDangKy,
			bm.TN_VonDauTu,
			bm.SXKD_DoanhThu,
			bm.SXKD_XuatKhau,
			bm.SXKD_NhapKhau,
			bm.SXKD_NopNganSach
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau11 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   dvhc.TenDonVi as DiaDiem,
		   vb2.SoKyHieu + N' ngày ' + FORMAT(vb2.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS VanBanThanhLap,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichNhaDauTu,
		   dm.NoiDung as TinhTrangName,
		   tmp.TinhTrang,
		   vbKHU.TongDienTich as QuyMoQuyHoach,
		   vb2.DienTichThanhLap as QuyMoThanhLap,
		   tmp.QuyMoHoatDong,
		   vb2.VonDauTuNuocNgoai as NN_VonDauTuDangKy,
		   tmp.NN_VonDauTu,
		   vb2.VonDauTuTrongNuoc as TN_VonDauTuDangKy,
		   tmp.TN_VonDauTu,
			tmp.SXKD_DoanhThu,
			tmp.SXKD_XuatKhau,
			tmp.SXKD_NhapKhau,
			tmp.SXKD_NopNganSach
		   
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	left join dbo.BCDT_DanhMuc_DonViHanhChinh dvhc on dvhc.MaDonVi = da.DiaChi_Tinh
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm ON dm.LoaiDanhMuc = 'DA_TT' AND dm.Ma = tmp.TinhTrang
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.VonDauTuNuocNgoai,
	v.VonDauTuTrongNuoc,
	v.DienTichThanhLap,
	v.DienTichCNDV,
	v.DienTichQuyHoach
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.TongDienTich
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 3
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vbKHU
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM12_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 12
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM12_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'12NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),

				VanBanThanhLap nvarchar(200),
				VanBanPheDuyet nvarchar(200),
				QuyMo_DatThanhLap decimal(24, 3),
				QuyMo_DatCNDV decimal(24, 3),
				QuyMo_DatCN decimal(24, 3),
				NN_TongSoDuAn int,
				NN_VonDauTu_DangKy decimal(24, 3),
				NN_DuAnSXKD int,
				NN_VonDauTu_ThucHien decimal(24, 3),
				NN_DoanhThu decimal(24, 3),
				NN_XuatKhau decimal(24, 3),
				NN_NhapKhau decimal(24, 3),
				NN_NopNganSach decimal(24, 3),
				NN_LaoDong int,
				TN_TongSoDuAn int,
				TN_VonDauTu_DangKy decimal(24, 3),
				TN_DuAnSXKD int,
				TN_VonDauTu_ThucHien decimal(24, 3),
				TN_DoanhThu decimal(24, 3),
				TN_XuatKhau decimal(24, 3),
				TN_NhapKhau decimal(24, 3),
				TN_NopNganSach decimal(24, 3),
				TN_LaoDong int,
				XLNT_TinhTrang int,
				XLNT_CongSuat_ThietKe int,
				XLNT_CongSuat_HoatDong int
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				TenTieuChi,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,

				VanBanThanhLap,
				VanBanPheDuyet,
				QuyMo_DatThanhLap,
				QuyMo_DatCNDV,
				QuyMo_DatCN,
				NN_TongSoDuAn,
				NN_VonDauTu_DangKy,
				NN_DuAnSXKD,
				NN_VonDauTu_ThucHien,
				NN_DoanhThu,
				NN_XuatKhau,
				NN_NhapKhau,
				NN_NopNganSach,
				NN_LaoDong,
				TN_TongSoDuAn,
				TN_VonDauTu_DangKy,
				TN_DuAnSXKD,
				TN_VonDauTu_ThucHien,
				TN_DoanhThu,
				TN_XuatKhau,
				TN_NhapKhau,
				TN_NopNganSach,
				TN_LaoDong,
				XLNT_TinhTrang,
				XLNT_CongSuat_ThietKe,
				XLNT_CongSuat_HoatDong
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
				
				VanBanThanhLap nvarchar(200) '$.VanBanThanhLap',
				VanBanPheDuyet nvarchar(200) '$.VanBanPheDuyet',
				QuyMo_DatThanhLap decimal(24, 3) '$.QuyMo_DatThanhLap',
				QuyMo_DatCNDV decimal(24, 3) '$.QuyMo_DatCNDV',
				QuyMo_DatCN decimal(24, 3) '$.QuyMo_DatCN',
				NN_TongSoDuAn int '$.NN_TongSoDuAn',
				NN_VonDauTu_DangKy decimal(24, 3) '$.NN_VonDauTu_DangKy',
				NN_DuAnSXKD int '$.NN_DuAnSXKD',
				NN_VonDauTu_ThucHien decimal(24, 3) '$.NN_VonDauTu_ThucHien',
				NN_DoanhThu decimal(24, 3) '$.NN_DoanhThu',
				NN_XuatKhau decimal(24, 3) '$.NN_XuatKhau',
				NN_NhapKhau decimal(24, 3) '$.NN_NhapKhau',
				NN_NopNganSach decimal(24, 3) '$.NN_NopNganSach',
				NN_LaoDong int '$.NN_LaoDong',
				TN_TongSoDuAn int '$.TN_TongSoDuAn',
				TN_VonDauTu_DangKy decimal(24, 3) '$.TN_VonDauTu_DangKy',
				TN_DuAnSXKD int '$.TN_DuAnSXKD',
				TN_VonDauTu_ThucHien decimal(24, 3) '$.TN_VonDauTu_ThucHien',
				TN_DoanhThu decimal(24, 3) '$.TN_DoanhThu',
				TN_XuatKhau decimal(24, 3) '$.TN_XuatKhau',
				TN_NhapKhau decimal(24, 3) '$.TN_NhapKhau',
				TN_NopNganSach decimal(24, 3) '$.TN_NopNganSach',
				TN_LaoDong int '$.TN_LaoDong',
				XLNT_TinhTrang int '$.XLNT_TinhTrang',
				XLNT_CongSuat_ThietKe int '$.XLNT_CongSuat_ThietKe',
				XLNT_CongSuat_HoatDong int '$.XLNT_CongSuat_HoatDong'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi      = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,

					VanBanThanhLap,
					VanBanPheDuyet,
					QuyMo_DatThanhLap,
					QuyMo_DatCNDV,
					QuyMo_DatCN,
					NN_TongSoDuAn,
					NN_VonDauTu_DangKy,
					NN_DuAnSXKD,
					NN_VonDauTu_ThucHien,
					NN_DoanhThu,
					NN_XuatKhau,
					NN_NhapKhau,
					NN_NopNganSach,
					NN_LaoDong,
					TN_TongSoDuAn,
					TN_VonDauTu_DangKy,
					TN_DuAnSXKD,
					TN_VonDauTu_ThucHien,
					TN_DoanhThu,
					TN_XuatKhau,
					TN_NhapKhau,
					TN_NopNganSach,
					TN_LaoDong,
					XLNT_TinhTrang,
					XLNT_CongSuat_ThietKe,
					XLNT_CongSuat_HoatDong,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau12 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id              = S.KKTKCN_Id,
					T.KKTKCN_Ma              = S.KKTKCN_Ma,
                    T.TenKKTKCN              = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id      = S.LoaiHinhKKTKCN_Id,

                    T.VanBanThanhLap = S.LoaiHinhKKTKCN_Id,
					T.VanBanPheDuyet = S.VanBanPheDuyet,
					T.QuyMo_DatThanhLap = S.QuyMo_DatThanhLap,
					T.QuyMo_DatCNDV = S.QuyMo_DatCNDV,
					T.QuyMo_DatCN = S.QuyMo_DatCN,
					T.NN_TongSoDuAn = S.NN_TongSoDuAn,
					T.NN_VonDauTu_DangKy = S.NN_VonDauTu_DangKy,
					T.NN_DuAnSXKD = S.NN_DuAnSXKD,
					T.NN_VonDauTu_ThucHien = S.NN_VonDauTu_ThucHien,
					T.NN_DoanhThu = S.NN_DoanhThu,
					T.NN_XuatKhau = S.NN_XuatKhau,
					T.NN_NhapKhau = S.NN_NhapKhau,
					T.NN_NopNganSach = S.NN_NopNganSach,
					T.NN_LaoDong = S.NN_LaoDong,
					T.TN_TongSoDuAn = S.TN_TongSoDuAn,
					T.TN_VonDauTu_DangKy = S.TN_VonDauTu_DangKy,
					T.TN_DuAnSXKD = S.TN_DuAnSXKD,
					T.TN_VonDauTu_ThucHien = S.TN_VonDauTu_ThucHien,
					T.TN_DoanhThu = S.TN_DoanhThu,
					T.TN_XuatKhau = S.TN_XuatKhau,
					T.TN_NhapKhau = S.TN_NhapKhau,
					T.TN_NopNganSach = S.TN_NopNganSach,
					T.TN_LaoDong = S.TN_LaoDong,
					T.XLNT_TinhTrang = S.XLNT_TinhTrang,
					T.XLNT_CongSuat_ThietKe = S.XLNT_CongSuat_ThietKe,
					T.XLNT_CongSuat_HoatDong = S.XLNT_CongSuat_HoatDong,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, TieuChiId, MaTieuChi, TenTieuChi, MaBieuMau, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,
                    VanBanThanhLap,
					VanBanPheDuyet,
					QuyMo_DatThanhLap,
					QuyMo_DatCNDV,
					QuyMo_DatCN,
					NN_TongSoDuAn,
					NN_VonDauTu_DangKy,
					NN_DuAnSXKD,
					NN_VonDauTu_ThucHien,
					NN_DoanhThu,
					NN_XuatKhau,
					NN_NhapKhau,
					NN_NopNganSach,
					NN_LaoDong,
					TN_TongSoDuAn,
					TN_VonDauTu_DangKy,
					TN_DuAnSXKD,
					TN_VonDauTu_ThucHien,
					TN_DoanhThu,
					TN_XuatKhau,
					TN_NhapKhau,
					TN_NopNganSach,
					TN_LaoDong,
					XLNT_TinhTrang,
					XLNT_CongSuat_ThietKe,
					XLNT_CongSuat_HoatDong,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,
                    S.VanBanThanhLap,
					S.VanBanPheDuyet,
					S.QuyMo_DatThanhLap,
					S.QuyMo_DatCNDV,
					S.QuyMo_DatCN,
					S.NN_TongSoDuAn,
					S.NN_VonDauTu_DangKy,
					S.NN_DuAnSXKD,
					S.NN_VonDauTu_ThucHien,
					S.NN_DoanhThu,
					S.NN_XuatKhau,
					S.NN_NhapKhau,
					S.NN_NopNganSach,
					S.NN_LaoDong,
					S.TN_TongSoDuAn,
					S.TN_VonDauTu_DangKy,
					S.TN_DuAnSXKD,
					S.TN_VonDauTu_ThucHien,
					S.TN_DoanhThu,
					S.TN_XuatKhau,
					S.TN_NhapKhau,
					S.TN_NopNganSach,
					S.TN_LaoDong,
					S.XLNT_TinhTrang,
					S.XLNT_CongSuat_ThietKe,
					S.XLNT_CongSuat_HoatDong,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau12 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM12_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 12
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM12_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
			bm.VanBanThanhLap,
			bm.VanBanPheDuyet,
			bm.QuyMo_DatThanhLap,
			bm.QuyMo_DatCNDV,
			bm.QuyMo_DatCN,
			bm.NN_TongSoDuAn,
			bm.NN_VonDauTu_DangKy,
			bm.NN_DuAnSXKD,
			bm.NN_VonDauTu_ThucHien,
			bm.NN_DoanhThu,
			bm.NN_XuatKhau,
			bm.NN_NhapKhau,
			bm.NN_NopNganSach,
			bm.NN_LaoDong,
			bm.TN_TongSoDuAn,
			bm.TN_VonDauTu_DangKy,
			bm.TN_DuAnSXKD,
			bm.TN_VonDauTu_ThucHien,
			bm.TN_DoanhThu,
			bm.TN_XuatKhau,
			bm.TN_NhapKhau,
			bm.TN_NopNganSach,
			bm.TN_LaoDong,
			bm.XLNT_TinhTrang,
			bm.XLNT_CongSuat_ThietKe,
			bm.XLNT_CongSuat_HoatDong
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau12 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   vb2.SoKyHieu + N' ngày ' + FORMAT(vb2.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS VanBanThanhLap,
		   vb4.SoKyHieu + N' ngày ' + FORMAT(vb4.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') AS VanBanPheDuyet,
		   vb2.DienTichThanhLap as QuyMo_DatThanhLap,
		   vb2.DienTichCongNghiepDv as QuyMo_DatCNDV,

		   tmp.QuyMo_DatCN,
			tmp.NN_TongSoDuAn,
			tmp.NN_VonDauTu_DangKy,
			tmp.NN_DuAnSXKD,
			tmp.NN_VonDauTu_ThucHien,
			tmp.NN_DoanhThu,
			tmp.NN_XuatKhau,
			tmp.NN_NhapKhau,
			tmp.NN_NopNganSach,
			tmp.NN_LaoDong,
			tmp.TN_TongSoDuAn,
			tmp.TN_VonDauTu_DangKy,
			tmp.TN_DuAnSXKD,
			tmp.TN_VonDauTu_ThucHien,
			tmp.TN_DoanhThu,
			tmp.TN_XuatKhau,
			tmp.TN_NhapKhau,
			tmp.TN_NopNganSach,
			tmp.TN_LaoDong,
			tmp.XLNT_TinhTrang,
			tmp.XLNT_CongSuat_ThietKe,
			tmp.XLNT_CongSuat_HoatDong,

		   dm.NoiDung as XLNT_TinhTrangName
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm ON dm.LoaiDanhMuc = 'TTHD' AND dm.Ma = tmp.XLNT_TinhTrang
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.DienTichThanhLap,
	v.DienTichCongNghiepDv
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh
    FROM BCDT_TieuChi_KKTKCN_VanBan v
    WHERE v.KKTKCN_Id = kcn.Id
        AND v.LoaiVanBan = 4
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb4
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM13_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 13
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM13_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'13NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
				DuAnId INT,
				MaDuAn nvarchar(50),
				TenDuAn nvarchar(2000),
				KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				TenTieuChi nvarchar(2000),
				TinhTrangId int,
				QuyMo decimal(24, 3),
				NganhNghe nvarchar(500),
				NN_VonDangKy decimal(24, 3),
				NN_VonDauTu_ThucHien decimal(24, 3),
				NN_DoanhThu decimal(24, 3),
				NN_XuatKhau decimal(24, 3),
				NN_NhapKhau decimal(24, 3),
				NN_NopNganSach decimal(24, 3),
				NN_LaoDong int,
				TN_VonDangKy decimal(24, 3),
				TN_VonDauTu_ThucHien decimal(24, 3),
				TN_DoanhThu decimal(24, 3),
				TN_XuatKhau decimal(24, 3),
				TN_NhapKhau decimal(24, 3),
				TN_NopNganSach decimal(24, 3),
				TN_LaoDong int
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
				DuAnId,
				MaDuAn,
				TenDuAn,
				KKTKCN_Id,
				KKTKCN_Ma,
				TenKKTKCN,
				LoaiHinhKKTKCN_Id,
				TenTieuChi,

                TinhTrangId,
				QuyMo,
				NganhNghe,
				NN_VonDangKy,
				NN_VonDauTu_ThucHien,
				NN_DoanhThu,
				NN_XuatKhau,
				NN_NhapKhau,
				NN_NopNganSach,
				NN_LaoDong,
				TN_VonDangKy,
				TN_VonDauTu_ThucHien,
				TN_DoanhThu,
				TN_XuatKhau,
				TN_NhapKhau,
				TN_NopNganSach,
				TN_LaoDong
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
				DuAnId INT '$.DuAnId', 
				MaDuAn nvarchar(50) '$.MaDuAn', 
				TenDuAn nvarchar(2000) '$.TenDuAn', 
				KKTKCN_Id int '$.KKTKCN_Id', 
				KKTKCN_Ma nvarchar(50) '$.KKTKCN_Ma',
				TenKKTKCN nvarchar(500) '$.TenKKTKCN',
				LoaiHinhKKTKCN_Id nvarchar(50) '$.LoaiHinhKKTKCN_Id', 
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 

                TinhTrangId int '$.TinhTrangId',
				QuyMo decimal(24, 3) '$.QuyMo',
				NganhNghe nvarchar(500) '$.NganhNghe',
				NN_VonDangKy decimal(24, 3) '$.NN_VonDangKy',
				NN_VonDauTu_ThucHien decimal(24, 3) '$.NN_VonDauTu_ThucHien',
				NN_DoanhThu decimal(24, 3) '$.NN_DoanhThu',
				NN_XuatKhau decimal(24, 3) '$.NN_XuatKhau',
				NN_NhapKhau decimal(24, 3) '$.NN_NhapKhau',
				NN_NopNganSach decimal(24, 3) '$.NN_NopNganSach',
				NN_LaoDong int '$.NN_LaoDong',
				TN_VonDangKy decimal(24, 3) '$.TN_VonDangKy',
				TN_VonDauTu_ThucHien decimal(24, 3) '$.TN_VonDauTu_ThucHien',
				TN_DoanhThu decimal(24, 3) '$.TN_DoanhThu',
				TN_XuatKhau decimal(24, 3) '$.TN_XuatKhau',
				TN_NhapKhau decimal(24, 3) '$.TN_NhapKhau',
				TN_NopNganSach decimal(24, 3) '$.TN_NopNganSach',
				TN_LaoDong int '$.TN_LaoDong'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
					DuAnId,
					MaDuAn,
					TenDuAn,
					KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
					TenTieuChi,

                    TinhTrangId,
					QuyMo,
					NganhNghe,
					NN_VonDangKy,
					NN_VonDauTu_ThucHien,
					NN_DoanhThu,
					NN_XuatKhau,
					NN_NhapKhau,
					NN_NopNganSach,
					NN_LaoDong,
					TN_VonDangKy,
					TN_VonDauTu_ThucHien,
					TN_DoanhThu,
					TN_XuatKhau,
					TN_NhapKhau,
					TN_NopNganSach,
					TN_LaoDong,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau13 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.DuAnId					= S.DuAnId,
					T.MaDuAn					= S.MaDuAn,
					T.TenDuAn					= S.TenDuAn, 
					T.KKTKCN_Id            = S.KKTKCN_Id,
                    T.KKTKCN_Ma            = S.KKTKCN_Ma,
                    T.TenKKTKCN            = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id    = S.LoaiHinhKKTKCN_Id,
                    T.TinhTrangId = S.TinhTrangId,
					T.QuyMo = S.QuyMo,
					T.NganhNghe = S.NganhNghe,
					T.NN_VonDangKy = S.NN_VonDangKy,
					T.NN_VonDauTu_ThucHien = S.NN_VonDauTu_ThucHien,
					T.NN_DoanhThu = S.NN_DoanhThu,
					T.NN_XuatKhau = S.NN_XuatKhau,
					T.NN_NhapKhau = S.NN_NhapKhau,
					T.NN_NopNganSach = S.NN_NopNganSach,
					T.NN_LaoDong = S.NN_LaoDong,
					T.TN_VonDangKy = S.TN_VonDangKy,
					T.TN_VonDauTu_ThucHien = S.TN_VonDauTu_ThucHien,
					T.TN_DoanhThu = S.TN_DoanhThu,
					T.TN_XuatKhau = S.TN_XuatKhau,
					T.TN_NhapKhau = S.TN_NhapKhau,
					T.TN_NopNganSach = S.TN_NopNganSach,
					T.TN_LaoDong = S.TN_LaoDong,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, TieuChiId, MaTieuChi, TenTieuChi, MaBieuMau, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    DuAnId ,MaDuAn, TenDuAn,
					TenKKTKCN,
					KKTKCN_Id,
					KKTKCN_Ma,
					LoaiHinhKKTKCN_Id,
                    TinhTrangId,
					QuyMo,
					NganhNghe,
					NN_VonDangKy,
					NN_VonDauTu_ThucHien,
					NN_DoanhThu,
					NN_XuatKhau,
					NN_NhapKhau,
					NN_NopNganSach,
					NN_LaoDong,
					TN_VonDangKy,
					TN_VonDauTu_ThucHien,
					TN_DoanhThu,
					TN_XuatKhau,
					TN_NhapKhau,
					TN_NopNganSach,
					TN_LaoDong,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.DuAnId ,S.MaDuAn ,S.TenDuAn,
					S.TenKKTKCN,
					S.KKTKCN_Id,
					S.KKTKCN_Ma,
					S.LoaiHinhKKTKCN_Id,
                    S.TinhTrangId,
					S.QuyMo,
					S.NganhNghe,
					S.NN_VonDangKy,
					S.NN_VonDauTu_ThucHien,
					S.NN_DoanhThu,
					S.NN_XuatKhau,
					S.NN_NhapKhau,
					S.NN_NopNganSach,
					S.NN_LaoDong,
					S.TN_VonDangKy,
					S.TN_VonDauTu_ThucHien,
					S.TN_DoanhThu,
					S.TN_XuatKhau,
					S.TN_NhapKhau,
					S.TN_NopNganSach,
					S.TN_LaoDong,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau13 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM13_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 13
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM13_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.TinhTrangId,
			bm.QuyMo,
			bm.NganhNghe,
			bm.NN_VonDangKy,
			bm.NN_VonDauTu_ThucHien,
			bm.NN_DoanhThu,
			bm.NN_XuatKhau,
			bm.NN_NhapKhau,
			bm.NN_NopNganSach,
			bm.NN_LaoDong,
			bm.TN_VonDangKy,
			bm.TN_VonDauTu_ThucHien,
			bm.TN_DoanhThu,
			bm.TN_XuatKhau,
			bm.TN_NhapKhau,
			bm.TN_NopNganSach,
			bm.TN_LaoDong
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau13 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
		   kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,
		   dm.NoiDung as TinhTrangName,
		   vb2.DienTichThucHien as QuyMo,
		   STUFF((SELECT ', ' + q.NoiDung FROM BCDT_DanhMuc_DungChung q WHERE q.LoaiDanhMuc = 'NGANHNGHE' and ',' + da.NganhNghe + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS NganhNghe,
		   vb2.VonDauTuNuocNgoai as NN_VonDangKy,
		   vb2.VonDauTuTrongNuoc as TN_VonDangKy,
		   tmp.NN_VonDauTu_ThucHien,
		   tmp.TinhTrangId,
			tmp.NN_DoanhThu,
			tmp.NN_XuatKhau,
			tmp.NN_NhapKhau,
			tmp.NN_NopNganSach,
			tmp.NN_LaoDong,
			tmp.TN_VonDauTu_ThucHien,
			tmp.TN_DoanhThu,
			tmp.TN_XuatKhau,
			tmp.TN_NhapKhau,
			tmp.TN_NopNganSach,
			tmp.TN_LaoDong
		   
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	LEFT JOIN dbo.BCDT_DanhMuc_DungChung dm ON dm.LoaiDanhMuc = 'DA_TT' AND dm.Ma = tmp.TinhTrangId
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.VonDauTuNuocNgoai,
	v.VonDauTuTrongNuoc,
	v.DienTichThanhLap,
	v.DienTichCNDV,
	v.DienTichThucHien
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM14_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create   PROCEDURE [dbo].[sp_BCDT_BM14_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN

    -- Thay giá trị này nếu mã biểu mẫu khác
    DECLARE @maBieuMau NVARCHAR(50) = N'14NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1) Parse JSON -> table variable
            ----------------------------------------------------------
            DECLARE @TableDuLieu TABLE
            (
                Id INT,
				DonViId INT,
				TieuChiId INT,
				TenTieuChi nvarchar(2000),
				SoThuTu INT,
				BieuMauId INT,
                NhaDauTu_Id INT,
                NhaDauTu_Ma NVARCHAR(50),
                TenNhaDauTu NVARCHAR(500),
				CauTrucGUID UNIQUEIDENTIFIER,


				TK_DuAn_CapMoi int,
				TK_DuAn_TangVon int,
				TK_DuAn_GiamVon int,
				TK_DuAn_ThuHoi int,
				TK_TongVon_CapMoi decimal(24, 3),
				TK_TongVon_TangVon decimal(24, 3),
				TK_TongVon_GiamVon decimal(24, 3),
				TK_TongVon_ThuHoi decimal(24, 3),
				LK_DuAn_TrongKCN int,
				LK_DuAn_VenBien int,
				LK_DuAn_CuaKhau int,
				LK_TongVonDK_TrongKCN decimal(24, 3),
				LK_TongVonDK_VenBien decimal(24, 3),
				LK_TongVonDK_CuaKhau decimal(24, 3),
				LK_TongVonTH_TrongKCN decimal(24, 3),
				LK_TongVonTH_VenBien decimal(24, 3),
				LK_TongVonTH_CuaKhau decimal(24, 3)
            );

            INSERT INTO @TableDuLieu
            (
                Id, NhaDauTu_Id, NhaDauTu_Ma, TenNhaDauTu,
                TK_DuAn_CapMoi,
				TK_DuAn_TangVon,
				TK_DuAn_GiamVon,
				TK_DuAn_ThuHoi,
				TK_TongVon_CapMoi,
				TK_TongVon_TangVon,
				TK_TongVon_GiamVon,
				TK_TongVon_ThuHoi,
				LK_DuAn_TrongKCN,
				LK_DuAn_VenBien,
				LK_DuAn_CuaKhau,
				LK_TongVonDK_TrongKCN,
				LK_TongVonDK_VenBien,
				LK_TongVonDK_CuaKhau,
				LK_TongVonTH_TrongKCN,
				LK_TongVonTH_VenBien,
				LK_TongVonTH_CuaKhau,
				CauTrucGUID,
				TieuChiId, TenTieuChi, BieuMauId, SoThuTu, DonViId
            )
            SELECT
                Id,
                NhaDauTu_Id,
                NhaDauTu_Ma,
                TenNhaDauTu,

				TK_DuAn_CapMoi,
				TK_DuAn_TangVon,
				TK_DuAn_GiamVon,
				TK_DuAn_ThuHoi,
				TK_TongVon_CapMoi,
				TK_TongVon_TangVon,
				TK_TongVon_GiamVon,
				TK_TongVon_ThuHoi,
				LK_DuAn_TrongKCN,
				LK_DuAn_VenBien,
				LK_DuAn_CuaKhau,
				LK_TongVonDK_TrongKCN,
				LK_TongVonDK_VenBien,
				LK_TongVonDK_CuaKhau,
				LK_TongVonTH_TrongKCN,
				LK_TongVonTH_VenBien,
				LK_TongVonTH_CuaKhau,

				CauTrucGUID,
				TieuChiId,
				TenTieuChi,
				BieuMauId,
				SoThuTu, 
				DonViId
            FROM OPENJSON(@JsonDuAn)
            WITH
            (
                Id INT '$.Id',
				NhaDauTu_Id int '$.NhaDauTu_Id',
				NhaDauTu_Ma nvarchar(50) '$.NhaDauTu_Ma',
				TenNhaDauTu nvarchar(500) '$.TenNhaDauTu',

				TK_DuAn_CapMoi int '$.TK_DuAn_CapMoi',
				TK_DuAn_TangVon int '$.TK_DuAn_TangVon',
				TK_DuAn_GiamVon int '$.TK_DuAn_GiamVon',
				TK_DuAn_ThuHoi int '$.TK_DuAn_ThuHoi',
				TK_TongVon_CapMoi decimal(24, 3) '$.TK_TongVon_CapMoi',
				TK_TongVon_TangVon decimal(24, 3) '$.TK_TongVon_TangVon',
				TK_TongVon_GiamVon decimal(24, 3) '$.TK_TongVon_GiamVon',
				TK_TongVon_ThuHoi decimal(24, 3) '$.TK_TongVon_ThuHoi',
				LK_DuAn_TrongKCN int '$.LK_DuAn_TrongKCN',
				LK_DuAn_VenBien int '$.LK_DuAn_VenBien',
				LK_DuAn_CuaKhau int '$.LK_DuAn_CuaKhau',
				LK_TongVonDK_TrongKCN decimal(24, 3) '$.LK_TongVonDK_TrongKCN',
				LK_TongVonDK_VenBien decimal(24, 3) '$.LK_TongVonDK_VenBien',
				LK_TongVonDK_CuaKhau decimal(24, 3) '$.LK_TongVonDK_CuaKhau',
				LK_TongVonTH_TrongKCN decimal(24, 3) '$.LK_TongVonTH_TrongKCN',
				LK_TongVonTH_VenBien decimal(24, 3) '$.LK_TongVonTH_VenBien',
				LK_TongVonTH_CuaKhau decimal(24, 3) '$.LK_TongVonTH_CuaKhau',

                CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                TieuChiId INT '$.TieuChiId',
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 
                BieuMauId INT '$.BieuMauId',
                SoThuTu INT '$.SoThuTu',
                DonViId INT '$.DonViId'
            );
			SELECT * FROM @TableDuLieu;
            ----------------------------------------------------------
            -- 2) Chuẩn bị nguồn (Src) cho MERGE
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    MaBieuMau      = @maBieuMau,
                    NhaDauTu_Id,
                    NhaDauTu_Ma,
                    TenNhaDauTu,

					TK_DuAn_CapMoi,
					TK_DuAn_TangVon,
					TK_DuAn_GiamVon,
					TK_DuAn_ThuHoi,
					TK_TongVon_CapMoi,
					TK_TongVon_TangVon,
					TK_TongVon_GiamVon,
					TK_TongVon_ThuHoi,
					LK_DuAn_TrongKCN,
					LK_DuAn_VenBien,
					LK_DuAn_CuaKhau,
					LK_TongVonDK_TrongKCN,
					LK_TongVonDK_VenBien,
					LK_TongVonDK_CuaKhau,
					LK_TongVonTH_TrongKCN,
					LK_TongVonTH_VenBien,
					LK_TongVonTH_CuaKhau,

					CauTrucGUID,
					TieuChiId, 
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
					TenTieuChi,
					BieuMauId,
					SoThuTu, 
                    NguoiCapNhat   = @NguoiDungId
                FROM @TableDuLieu
                WHERE ISNULL(BieuMauId,0) <> 0 AND ISNULL(TieuChiId,0) <> 0
            )

            ----------------------------------------------------------
            -- 3) MERGE -> Update | Insert
            ----------------------------------------------------------
            MERGE dbo.BCDT_DuLieu_BieuMau14 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID     = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.NhaDauTu_Id              = S.NhaDauTu_Id,
					T.NhaDauTu_Ma              = S.NhaDauTu_Ma,
                    T.TenNhaDauTu              = S.TenNhaDauTu,
                   
					T.TK_DuAn_CapMoi = S.TK_DuAn_CapMoi,
					T.TK_DuAn_TangVon = S.TK_DuAn_TangVon,
					T.TK_DuAn_GiamVon = S.TK_DuAn_GiamVon,
					T.TK_DuAn_ThuHoi = S.TK_DuAn_ThuHoi,
					T.TK_TongVon_CapMoi = S.TK_TongVon_CapMoi,
					T.TK_TongVon_TangVon = S.TK_TongVon_TangVon,
					T.TK_TongVon_GiamVon = S.TK_TongVon_GiamVon,
					T.TK_TongVon_ThuHoi = S.TK_TongVon_ThuHoi,
					T.LK_DuAn_TrongKCN = S.LK_DuAn_TrongKCN,
					T.LK_DuAn_VenBien = S.LK_DuAn_VenBien,
					T.LK_DuAn_CuaKhau = S.LK_DuAn_CuaKhau,
					T.LK_TongVonDK_TrongKCN = S.LK_TongVonDK_TrongKCN,
					T.LK_TongVonDK_VenBien = S.LK_TongVonDK_VenBien,
					T.LK_TongVonDK_CuaKhau = S.LK_TongVonDK_CuaKhau,
					T.LK_TongVonTH_TrongKCN = S.LK_TongVonTH_TrongKCN,
					T.LK_TongVonTH_VenBien = S.LK_TongVonTH_VenBien,
					T.LK_TongVonTH_CuaKhau = S.LK_TongVonTH_CuaKhau,

                    T.BitDaXoa             = 0,                -- khôi phục nếu đã xoá
                    T.NguoiSua             = S.NguoiCapNhat,
                    T.NgaySua              = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                    BieuMauId, MaBieuMau, TieuChiId, MaTieuChi, TenTieuChi, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    NhaDauTu_Id, NhaDauTu_Ma, TenNhaDauTu,

                    TK_DuAn_CapMoi,
					TK_DuAn_TangVon,
					TK_DuAn_GiamVon,
					TK_DuAn_ThuHoi,
					TK_TongVon_CapMoi,
					TK_TongVon_TangVon,
					TK_TongVon_GiamVon,
					TK_TongVon_ThuHoi,
					LK_DuAn_TrongKCN,
					LK_DuAn_VenBien,
					LK_DuAn_CuaKhau,
					LK_TongVonDK_TrongKCN,
					LK_TongVonDK_VenBien,
					LK_TongVonDK_CuaKhau,
					LK_TongVonTH_TrongKCN,
					LK_TongVonTH_VenBien,
					LK_TongVonTH_CuaKhau,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES
                (
                    S.BieuMauId, S.MaBieuMau, S.TieuChiId, S.MaTieuChi, S.TenTieuChi,S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.NhaDauTu_Id, S.NhaDauTu_Ma, S.TenNhaDauTu,
                    S.TK_DuAn_CapMoi,
					S.TK_DuAn_TangVon,
					S.TK_DuAn_GiamVon,
					S.TK_DuAn_ThuHoi,
					S.TK_TongVon_CapMoi,
					S.TK_TongVon_TangVon,
					S.TK_TongVon_GiamVon,
					S.TK_TongVon_ThuHoi,
					S.LK_DuAn_TrongKCN,
					S.LK_DuAn_VenBien,
					S.LK_DuAn_CuaKhau,
					S.LK_TongVonDK_TrongKCN,
					S.LK_TongVonDK_VenBien,
					S.LK_TongVonDK_CuaKhau,
					S.LK_TongVonTH_TrongKCN,
					S.LK_TongVonTH_VenBien,
					S.LK_TongVonTH_CuaKhau,
                    S.NguoiCapNhat, GETDATE(), 0
                );

            ----------------------------------------------------------
            -- 4) ĐÁNH DẤU XÓA MỀM theo CẤU TRÚC BIỂU MẪU (fn_BCDT_GetCauTrucBieuMau)
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau14 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGUID = CT.CauTrucGUID
               AND ISNULL(T.MaBieuMau, @maBieuMau) = CT.MaBieuMau
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM14_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 14
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM14_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.NhaDauTu_Id,
			bm.NhaDauTu_Ma,
			bm.TenNhaDauTu,
			bm.TK_DuAn_CapMoi,
			bm.TK_DuAn_TangVon,
			bm.TK_DuAn_GiamVon,
			bm.TK_DuAn_ThuHoi,
			bm.TK_TongVon_CapMoi,
			bm.TK_TongVon_TangVon,
			bm.TK_TongVon_GiamVon,
			bm.TK_TongVon_ThuHoi,
			bm.LK_DuAn_TrongKCN,
			bm.LK_DuAn_VenBien,
			bm.LK_DuAn_CuaKhau,
			bm.LK_TongVonDK_TrongKCN,
			bm.LK_TongVonDK_VenBien,
			bm.LK_TongVonDK_CuaKhau,
			bm.LK_TongVonTH_TrongKCN,
			bm.LK_TongVonTH_VenBien,
			bm.LK_TongVonTH_CuaKhau
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau14 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
		   ndt.Id AS NhaDauTu_Id,
		   ndt.Ma AS NhaDauTu_Ma,
		   ndt.Ten AS TenNhaDauTu,
           tmp.TK_DuAn_CapMoi,
			tmp.TK_DuAn_TangVon,
			tmp.TK_DuAn_GiamVon,
			tmp.TK_DuAn_ThuHoi,
			tmp.TK_TongVon_CapMoi,
			tmp.TK_TongVon_TangVon,
			tmp.TK_TongVon_GiamVon,
			tmp.TK_TongVon_ThuHoi,
			tmp.LK_DuAn_TrongKCN,
			tmp.LK_DuAn_VenBien,
			tmp.LK_DuAn_CuaKhau,
			tmp.LK_TongVonDK_TrongKCN,
			tmp.LK_TongVonDK_VenBien,
			tmp.LK_TongVonDK_CuaKhau,
			tmp.LK_TongVonTH_TrongKCN,
			tmp.LK_TongVonTH_VenBien,
			tmp.LK_TongVonTH_CuaKhau
	FROM #TempData tmp
	LEFT JOIN dbo.BCDT_TieuChi_NhaDauTu ndt ON ndt.TieuChiId = tmp.TieuChiId
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM15_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 15
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM15_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'15NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				DuAnId INT,
				MaDuAn nvarchar(50),
				TenDuAn nvarchar(2000),
				TenTieuChi nvarchar(2000),

				KKTKCN nvarchar(50),
				SoVanBan nvarchar(200),
				NgayVanBan datetime,
				NhaDauTu nvarchar(200),
				VonDieuLe_Tang decimal(24, 3),
				VonDieuLe_Giam decimal(24, 3),
				VonDauTu_Tang decimal(24, 3),
				VonDauTu_Giam decimal(24, 3),
				QuyMo_Tang decimal(24, 3),
				QuyMo_Giam decimal(24, 3)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
				DuAnId,
				MaDuAn,
				TenDuAn,
				TenTieuChi,

                KKTKCN,
				SoVanBan,
				NgayVanBan,
				NhaDauTu,
				VonDieuLe_Tang,
				VonDieuLe_Giam,
				VonDauTu_Tang,
				VonDauTu_Giam,
				QuyMo_Tang,
				QuyMo_Giam
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
				DuAnId INT '$.DuAnId', 
				MaDuAn nvarchar(50) '$.MaDuAn', 
				TenDuAn nvarchar(2000) '$.TenDuAn', 
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 

                KKTKCN nvarchar(50) '$.KKTKCN',
				SoVanBan nvarchar(200) '$.SoVanBan',
				NgayVanBan datetime '$.NgayVanBan',
				NhaDauTu nvarchar(200) '$.NhaDauTu',
				VonDieuLe_Tang decimal(24, 3) '$.VonDieuLe_Tang',
				VonDieuLe_Giam decimal(24, 3) '$.VonDieuLe_Giam',
				VonDauTu_Tang decimal(24, 3) '$.VonDauTu_Tang',
				VonDauTu_Giam decimal(24, 3) '$.VonDauTu_Giam',
				QuyMo_Tang decimal(24, 3) '$.QuyMo_Tang',
				QuyMo_Giam decimal(24, 3)'$.QuyMo_Giam'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
					DuAnId,
					MaDuAn,
					TenDuAn,
					TenTieuChi,

                    KKTKCN,
					SoVanBan,
					NgayVanBan,
					NhaDauTu,
					VonDieuLe_Tang,
					VonDieuLe_Giam,
					VonDauTu_Tang,
					VonDauTu_Giam,
					QuyMo_Tang,
					QuyMo_Giam,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau15 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id              = S.KKTKCN_Id,
					T.KKTKCN_Ma              = S.KKTKCN_Ma,
                    T.TenKKTKCN              = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id      = S.LoaiHinhKKTKCN_Id,
					T.DuAnId					= S.DuAnId,
					T.MaDuAn					= S.MaDuAn,
					T.TenDuAn					= S.TenDuAn,

                    T.KKTKCN = S.KKTKCN,
					T.SoVanBan = S.SoVanBan,
					T.NgayVanBan = S.NgayVanBan,
					T.NhaDauTu = S.NhaDauTu,
					T.VonDieuLe_Tang = S.VonDieuLe_Tang,
					T.VonDieuLe_Giam = S.VonDieuLe_Giam,
					T.VonDauTu_Tang = S.VonDauTu_Tang,
					T.VonDauTu_Giam = S.VonDauTu_Giam,
					T.QuyMo_Tang = S.QuyMo_Tang,
					T.QuyMo_Giam = S.QuyMo_Giam,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, TieuChiId, MaTieuChi, TenTieuChi, MaBieuMau, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,DuAnId ,MaDuAn, TenDuAn,
                    KKTKCN,
					SoVanBan,
					NgayVanBan,
					NhaDauTu,
					VonDieuLe_Tang,
					VonDieuLe_Giam,
					VonDauTu_Tang,
					VonDauTu_Giam,
					QuyMo_Tang,
					QuyMo_Giam,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,S.DuAnId ,S.MaDuAn ,S.TenDuAn,
                    S.KKTKCN,
					S.SoVanBan,
					S.NgayVanBan,
					S.NhaDauTu,
					S.VonDieuLe_Tang,
					S.VonDieuLe_Giam,
					S.VonDauTu_Tang,
					S.VonDauTu_Giam,
					S.QuyMo_Tang,
					S.QuyMo_Giam,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau15 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM15_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 15
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM15_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.KKTKCN,
			bm.SoVanBan,
			bm.NgayVanBan,
			bm.NhaDauTu,
			bm.VonDieuLe_Tang,
			bm.VonDieuLe_Giam,
			bm.VonDauTu_Tang,
			bm.VonDauTu_Giam,
			bm.QuyMo_Tang,
			bm.QuyMo_Giam
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau15 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   CASE 
		     WHEN da.LoaiDuAn IN (1, 2) THEN N'KKT'
		     WHEN da.LoaiDuAn IN (3, 4) THEN N'KCN'
		     ELSE N''
		   END AS KKTKCN,
		   vb2.SoKyHieu as SoVanBan,
		   vb2.NgayBanHanh as NgayVanBan,
		   da.TenNhaDauTu as NhaDauTu,
		   tmp.VonDieuLe_Tang,
			tmp.VonDieuLe_Giam,
			tmp.VonDauTu_Tang,
			tmp.VonDauTu_Giam,
			tmp.QuyMo_Tang,
			tmp.QuyMo_Giam

	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh BETWEEN @thoiGianTu AND @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM16_CapNhatDuLieu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Cập nhật dữ liệu biểu mẫu 16
-- =============================================
create     PROCEDURE [dbo].[sp_BCDT_BM16_CapNhatDuLieu]
    @donViId INT,
    @keHoachId INT,
    @dotKeHoachId INT,
    @JsonDuAn NVARCHAR(MAX),
    @NguoiDungId INT
AS
BEGIN
    DECLARE @maBieuMau NVARCHAR(50) = N'16NQLKKT';

    BEGIN TRANSACTION;
    BEGIN TRY

        IF ISNULL(@JsonDuAn, '') <> '' AND ISNULL(@donViId, 0) <> 0
        BEGIN
            ----------------------------------------------------------
            -- 1️⃣ Parse JSON vào table tạm
            ----------------------------------------------------------
            DECLARE @TblKKTKCN TABLE
            (
                Id INT,
                BieuMauId INT,
				TieuChiId INT,
				CauTrucGUID UNIQUEIDENTIFIER,
                MaBieuMau NVARCHAR(50),
                DotKeHoach_Id INT,
                KeHoachId INT,
                DonViId INT,
                KKTKCN_Id INT,
                KKTKCN_Ma NVARCHAR(50),
                TenKKTKCN NVARCHAR(500),
                LoaiHinhKKTKCN_Id NVARCHAR(50),
				DuAnId INT,
				MaDuAn nvarchar(50),
				TenDuAn nvarchar(2000),
				TenTieuChi nvarchar(2000),

				SoVanBan nvarchar(200),
				TenNhaDauTu nvarchar(200),
				QuocTichDauTu nvarchar(200),
				NN_VonDauTu decimal(24, 3),
				TN_VonDauTu decimal(24, 3),
				SoVanBan_ThuHoi nvarchar(2000)
            );

            INSERT INTO @TblKKTKCN
            SELECT
                Id,
                BieuMauId,
				TieuChiId,
				CauTrucGUID,
                MaBieuMau,
                DotKeHoach_Id,
                KeHoachId,
                DonViId,
                KKTKCN_Id,
                KKTKCN_Ma,
                TenKKTKCN,
                LoaiHinhKKTKCN_Id,
				DuAnId,
				MaDuAn,
				TenDuAn,
				TenTieuChi,

                SoVanBan,
				TenNhaDauTu,
				QuocTichDauTu,
				NN_VonDauTu,
				TN_VonDauTu,
				SoVanBan_ThuHoi
            FROM OPENJSON(@JsonDuAn)
            WITH (
                Id INT '$.Id',
                BieuMauId INT '$.BieuMauId',
				TieuChiId INT '$.TieuChiId',
				CauTrucGUID UNIQUEIDENTIFIER '$.CauTrucGUID',
                MaBieuMau NVARCHAR(50) '$.MaBieuMau',
                DotKeHoach_Id INT '$.DotKeHoach_Id',
                KeHoachId INT '$.KeHoachId',
                DonViId INT '$.DonViId',
                KKTKCN_Id INT '$.KKTKCN_Id',
                KKTKCN_Ma NVARCHAR(50) '$.KKTKCN_Ma',
                TenKKTKCN NVARCHAR(500) '$.TenKKTKCN',
                LoaiHinhKKTKCN_Id NVARCHAR(50) '$.LoaiHinhKKTKCN_Id',
				DuAnId INT '$.DuAnId', 
				MaDuAn nvarchar(50) '$.MaDuAn', 
				TenDuAn nvarchar(2000) '$.TenDuAn', 
				TenTieuChi nvarchar(2000) '$.TenTieuChi', 

                SoVanBan nvarchar(200) '$.SoVanBan',
				TenNhaDauTu nvarchar(200) '$.TenNhaDauTu',
				QuocTichDauTu nvarchar(200) '$.QuocTichDauTu',
				NN_VonDauTu decimal(24, 3) '$.NN_VonDauTu',
				TN_VonDauTu decimal(24, 3) '$.TN_VonDauTu',
				SoVanBan_ThuHoi nvarchar(2000) '$.SoVanBan_ThuHoi'
            );

            ----------------------------------------------------------
            -- 2️⃣ MERGE dữ liệu vào bảng chính
            ----------------------------------------------------------
            WITH Src AS
            (
                SELECT
                    DonViId        = @donViId,
                    KeHoachId      = @keHoachId,
                    DotKeHoach_Id  = @dotKeHoachId,
                    BieuMauId,
					TieuChiId,
					MaTieuChi = (SELECT TOP(1) MaTieuChi FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = TieuChiId),
                    MaBieuMau      = @maBieuMau,
					CauTrucGUID,
                    KKTKCN_Id,
                    KKTKCN_Ma,
                    TenKKTKCN,
                    LoaiHinhKKTKCN_Id,
					DuAnId,
					MaDuAn,
					TenDuAn,
					TenTieuChi,

                    SoVanBan,
					TenNhaDauTu,
					QuocTichDauTu,
					NN_VonDauTu,
					TN_VonDauTu,
					SoVanBan_ThuHoi,
                    NguoiCapNhat   = @NguoiDungId
                FROM @TblKKTKCN
                WHERE ISNULL(TieuChiId,0) <> 0
            )

            MERGE dbo.BCDT_DuLieu_BieuMau16 AS T
            USING Src AS S
                ON  T.DonViId       = S.DonViId
                AND T.KeHoachId     = S.KeHoachId
                AND T.DotKeHoach_Id = S.DotKeHoach_Id
                AND T.CauTrucGUID   = S.CauTrucGUID
            WHEN MATCHED THEN
                UPDATE SET
					T.TieuChiId         = S.TieuChiId,
					T.MaTieuChi         = S.MaTieuChi,
					T.TenTieuChi		= S.TenTieuChi,
					T.KKTKCN_Id              = S.KKTKCN_Id,
					T.KKTKCN_Ma              = S.KKTKCN_Ma,
                    T.TenKKTKCN              = S.TenKKTKCN,
                    T.LoaiHinhKKTKCN_Id      = S.LoaiHinhKKTKCN_Id,
					T.DuAnId					= S.DuAnId,
					T.MaDuAn					= S.MaDuAn,
					T.TenDuAn					= S.TenDuAn,

                    T.SoVanBan = S.SoVanBan,
					T.TenNhaDauTu = S.TenNhaDauTu,
					T.QuocTichDauTu = S.QuocTichDauTu,
					T.NN_VonDauTu = S.NN_VonDauTu,
					T.TN_VonDauTu = S.TN_VonDauTu,
					T.SoVanBan_ThuHoi = S.SoVanBan_ThuHoi,

                    T.BitDaXoa               = 0,
                    T.NguoiSua               = S.NguoiCapNhat,
                    T.NgaySua                = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (
                    BieuMauId, TieuChiId, MaTieuChi, TenTieuChi, MaBieuMau, CauTrucGUID, DotKeHoach_Id, KeHoachId, DonViId,
                    KKTKCN_Id, KKTKCN_Ma, TenKKTKCN, LoaiHinhKKTKCN_Id,DuAnId ,MaDuAn, TenDuAn,
                    SoVanBan,
					TenNhaDauTu,
					QuocTichDauTu,
					NN_VonDauTu,
					TN_VonDauTu,
					SoVanBan_ThuHoi,

                    NguoiTao, NgayTao, BitDaXoa
                )
                VALUES (
                    S.BieuMauId, S.TieuChiId, S.MaTieuChi, S.TenTieuChi, S.MaBieuMau, S.CauTrucGUID, S.DotKeHoach_Id, S.KeHoachId, S.DonViId,
                    S.KKTKCN_Id, S.KKTKCN_Ma, S.TenKKTKCN, S.LoaiHinhKKTKCN_Id,S.DuAnId ,S.MaDuAn ,S.TenDuAn,
                    S.SoVanBan,
					S.TenNhaDauTu,
					S.QuocTichDauTu,
					S.NN_VonDauTu,
					S.TN_VonDauTu,
					S.SoVanBan_ThuHoi,
                    S.NguoiCapNhat, GETDATE(), 0
                );
            ----------------------------------------------------------
            -- 4. Đánh dấu xóa logic (BitDaXoa = 1) nếu tiêu chí bị xóa trong cấu trúc
            ----------------------------------------------------------
            UPDATE T
            SET
                T.BitDaXoa = 1,
                T.NguoiSua = @NguoiDungId,
                T.NgaySua  = GETDATE()
            FROM dbo.BCDT_DuLieu_BieuMau16 T
            JOIN dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) CT
                ON T.CauTrucGuid = CT.CauTrucGuid
            WHERE CT.BitDaXoa = 1
              AND T.DonViId   = @donViId
              AND T.KeHoachId = @keHoachId
              AND T.DotKeHoach_Id = @dotKeHoachId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX);
        SET @ErrorMessage = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_BM16_GetDuLieuNhap]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description: lấy thông tin biểu nhập 16
-- =============================================
CREATE     PROCEDURE [dbo].[sp_BCDT_BM16_GetDuLieuNhap]
    @donViId INT,
    @keHoachId INT,
    @maBieuMau NVARCHAR(50)
AS
BEGIN
	DROP TABLE IF EXISTS #TempData;

	DECLARE @thoiGianTu DATE;
	DECLARE @thoiGianDen DATE;

	SELECT @thoiGianTu = ThoiGianTu, @thoiGianDen = ThoiGianDen FROM dbo.fn_GetThoiGianTheoKeHoach(@keHoachId);
    -- Lấy thông tin đơn vị nhập biểu
    SELECT ct.DonViId,
           ct.KeHoachId,
           ct.MaBieuMau,
           ct.BieuMauId,
           ct.MaTieuChi,
           ct.TieuChiId,
           ct.TenTieuChi,
           ct.Path,
           ct.SoThuTu,
           ct.SoThuTuHienThi,
		   ct.SoThuTuBieuTieuChi,
           ct.Style,
           ct.DonViTinh,
           ISNULL(bm.Id, 0) AS Id,
           ISNULL(bm.CauTrucGUID, ct.CauTrucGUID) AS CauTrucGUID,
		   (
               SELECT bct.CauTrucGUID,
                      bct.LoaiCongThuc,
                      bct.CongThuc,
                      bct.ViTri,
                      bct.SheetName
               FROM dbo.BCDT_CauTruc_BieuMau_CongThuc bct
               WHERE bct.CauTrucGUID = ct.CauTrucGUID
                     AND bct.IsActive = 1
               FOR JSON AUTO
           ) AS CongThucTieuChi,
		   ct.ColumnMerge,
           bm.SoVanBan,
			bm.TenNhaDauTu,
			bm.QuocTichDauTu,
			bm.NN_VonDauTu,
			bm.TN_VonDauTu,
			bm.SoVanBan_ThuHoi
	INTO #TempData
    FROM dbo.fn_BCDT_GetCauTrucBieuMau(@donViId, @keHoachId, @maBieuMau) ct
        LEFT JOIN dbo.BCDT_DuLieu_BieuMau16 bm
            ON bm.CauTrucGUID = ct.CauTrucGUID
               AND bm.BitDaXoa = 0
               AND bm.DonViId = @donViId
               AND bm.KeHoachId = @keHoachId
               AND bm.MaBieuMau = @maBieuMau
    WHERE ct.BitDaXoa = 0

	SELECT 
		   tmp.DonViId,
           tmp.KeHoachId,
           tmp.MaBieuMau,
           tmp.BieuMauId,
           tmp.MaTieuChi,
           tmp.TieuChiId,
           tmp.TenTieuChi,
           tmp.Path,
           tmp.SoThuTu,
           tmp.SoThuTuHienThi,
		   tmp.SoThuTuBieuTieuChi,
           tmp.Style,
           tmp.DonViTinh,
           tmp.Id,
           tmp.CauTrucGUID,
		   tmp.CongThucTieuChi,
		   tmp.ColumnMerge,
           da.Id as DuAnId,
		   da.MaDuAn,
		   da.TenDuAn,
           kcn.LoaiHinhId AS LoaiHinhKKTKCN_Id,
		   kcn.Id AS KKTKCN_Id,
		   kcn.MaKKTKCN AS KKTKCN_Ma,
		   kcn.TenKKTKCN AS TenKKTKCN,

		   vb2.SoKyHieu + N' ngày ' + FORMAT(vb2.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as SoVanBan,
		   da.TenNhaDauTu,
		   STUFF((SELECT ',' + q.TenVN FROM BCDT_DanhMuc_QuocGia q WHERE ',' + da.QuocTichDauTu + ',' LIKE '%,' + q.Ma + ',%' FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '') AS QuocTichDauTu,
		   vb2.VonDauTuNuocNgoai as NN_VonDauTu,
		   vb2.VonDauTuTrongNuoc as TN_VonDauTu,
		   vb3.SoKyHieu + N' ngày ' + FORMAT(vb3.NgayBanHanh, 'dd/MM/yyyy', 'vi-VN') as SoVanBan_ThuHoi
	FROM #TempData tmp
	left join dbo.BCDT_TieuChi_DuAn da on da.TieuChiId = tmp.TieuChiId
	LEFT JOIN dbo.BCDT_TieuChi_KKTKCN kcn ON kcn.Id = da.KKTKCN_Id
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh,
	v.VonDauTuNuocNgoai,
	v.VonDauTuTrongNuoc
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 2
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb2
	OUTER APPLY (
    SELECT TOP 1 
	v.Id, 
	v.SoKyHieu,
	v.NgayBanHanh
    FROM BCDT_TieuChi_DuAn_VanBan v
    WHERE v.DuAnId = da.Id
        AND v.LoaiVanBan = 3
        AND v.NgayBanHanh <= @thoiGianDen
		AND v.BitDaXoa = 0
    ORDER BY v.NgayBanHanh DESC
	) vb3
    ORDER BY tmp.SoThuTuBieuTieuChi, tmp.Path;

END;
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_BMTH_Config_Upsert]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*============================================================================
  Stored Procedure : dbo.SP_BCDT_BMTH_Config_Upsert
  Mục đích         : Nạp/cập nhật cấu hình cho hệ BMTH (Biểu Mẫu Tổng Hợp) vào 4 bảng:
                     - BCDT_BMTH_BieuNguon_Alias   : Danh mục alias → nguồn dữ liệu
                     - BCDT_BMTH_ColumnMap         : Khai báo cột đầu ra (C..T) và chế độ render
                     - BCDT_BMTH_ColumnMap_Term    : Các hạng tử (terms) góp số cho từng cột
                     - BCDT_BMTH_ColumnExpr        : Công thức hậu xử lý giữa các cột (EXPR)

  Phạm vi/Assumption:
    - Các bảng cấu hình trên đã tồn tại.
    - Quy ước cột Excel: ký hiệu A..Z.. (dùng SYSNAME), Map theo (TongHopBieuMauId, ExcelCol).
    - Alias nguồn phải tồn tại và ở trạng thái IsActive=1 trước khi gán Term.

  Tham số:
    @TongHopBieuMauId INT           -- Id biểu tổng hợp trong BCDT_DanhMuc_BieuMau
    @AliasesJson  NVARCHAR(MAX)=NULL
       • Mảng các object (tuỳ chọn). Nếu truyền vào sẽ MERGE vào BCDT_BMTH_BieuNguon_Alias.
         Mẫu phần tử:
         {
           "Alias":"BM3",
           "BieuMauId":3,
           "TableName":"BCDT_DuLieu_BieuMau3",
           "ValueColumn":"TongCong",       -- mặc định 'TongCong' nếu null
           "IsActive":1                    -- mặc định 1 nếu null
         }
    @ColumnsJson  NVARCHAR(MAX)      -- BẮT BUỘC. Mảng object cấu hình cột đầu ra.
       • Mẫu phần tử:
         {
           "ExcelCol":"C",                   -- bắt buộc
           "RenderMode":"VALUE|EXPR",        -- mặc định 'VALUE'
           "RoundDigits":0,                  -- mặc định 0
           "IsActive":1,                     -- mặc định 1
           "SortOrder":1                     -- mặc định 9999
         }
       • SP sẽ INSERT vào BCDT_BMTH_ColumnMap theo thứ tự SortOrder.
    @TermsJson    NVARCHAR(MAX)      -- BẮT BUỘC. Mảng object hạng tử cho từng cột.
       • Mẫu phần tử (ít nhất phải có OutCol, Alias, và 1 trong 2: ExcelRow hoặc DataColumnName):
         {
           "OutCol":"C",                      -- bắt buộc, phải tồn tại trong ColumnsJson
           "Alias":"BM3",                     -- bắt buộc, alias phải tồn tại & IsActive=1
           "ExcelRow":8,                      -- selector 1 (tuỳ chọn)
           "DataColumnName":"TongCong",       -- selector 2 (tuỳ chọn)
           "AggFn":"SUM|AVG|MIN|MAX|COUNT",   -- mặc định 'SUM'
           "Weight":1,                        -- mặc định 1
           "Scale":1,                         -- mặc định 1
           "UnitScopeMode":"ALL|LIST|EXCLUDE",-- tuỳ chọn
           "UnitIdsJson":"[1,2,3]",           -- tuỳ chọn (JSON array)
           "ThuTu":1                          -- mặc định 9999
         }
       • SP map Term → MapId theo (TongHopBieuMauId, OutCol) đã tạo ở bước Columns.
    @ExprJson     NVARCHAR(MAX)=NULL -- Tuỳ chọn. Công thức hậu xử lý giữa các cột.
       • Hỗ trợ 2 dạng:
         (A) MẢNG OBJECT:
             [
               { "ExcelCol":"G","ExprText":"F/E","RoundDigits":0,"IsActive":1 },
               { "ExcelCol":"H","ExprText":"C+D","RoundDigits":0,"IsActive":1 }
             ]
         (B) OBJECT MAP:
             { "G":"F/E", "H":"C+D" }
       • SP tự nhận diện mảng qua JSON_VALUE(@ExprJson,'$[0].ExcelCol') IS NOT NULL;
         nếu không, coi như dạng object map.
       • Mỗi ExcelCol trong ExprJson phải tồn tại trong ColumnsJson (đã insert).

    @PurgeOld     BIT=1              -- 1: Xoá toàn bộ cấu hình cũ của biểu trước khi nạp mới
    @UserId       INT=-1             -- Dự phòng lưu audit (chưa dùng phiên bản này)

  Kiểm tra/Hợp lệ hoá (Validation):
    - Tồn tại các bảng cấu hình BMTH.
    - @ColumnsJson & @TermsJson phải là JSON hợp lệ (ISJSON=1).
    - ColumnsJson: mọi phần tử phải có ExcelCol khác NULL.
    - TermsJson:
        + Mọi phần tử phải có OutCol, Alias, và (ExcelRow OR DataColumnName).
        + OutCol phải tồn tại trong ColumnsJson đã nạp.
        + Alias phải tồn tại trong BCDT_BMTH_BieuNguon_Alias và IsActive=1.
    - ExprJson (nếu có): mọi ExcelCol phải tồn tại trong ColumnsJson.
    - Vi phạm sẽ RAISERROR với thông điệp chi tiết và ROLLBACK.

  Trình tự xử lý:
    1) (Tuỳ chọn) MERGE @AliasesJson → BCDT_BMTH_BieuNguon_Alias.
    2) Nếu @PurgeOld=1:
         - Xoá Term theo MapId của biểu → Xoá Expr của biểu → Xoá ColumnMap của biểu.
    3) Parse @ColumnsJson → insert BCDT_BMTH_ColumnMap (ORDER BY SortOrder).
       Lưu lại (MapId, ExcelCol) vào tạm #MapIds.
    4) Parse @TermsJson → validate OutCol/Alias/selector → insert BCDT_BMTH_ColumnMap_Term,
       map theo #MapIds; ORDER BY OutCol, ThuTu.
    5) Parse @ExprJson (nếu có):
         - Nếu dạng mảng: OPENJSON ... WITH (ExcelCol, ExprText, RoundDigits, IsActive)
         - Nếu dạng object: OPENJSON (@ExprJson) trả (key=ExcelCol, value=ExprText)
         - Validate ExcelCol có trong #MapIds → insert BCDT_BMTH_ColumnExpr.
    6) COMMIT TRAN; nếu lỗi → CATCH ROLLBACK và RAISERROR 'Lỗi nạp cấu hình BMTH: %s'.

  Kết quả trả về:
    - 1 resultset thống kê:
        ColumnCount : số dòng trong BCDT_BMTH_ColumnMap cho @TongHopBieuMauId
        TermCount   : số dòng trong BCDT_BMTH_ColumnMap_Term (join theo MapId) cho biểu
        ExprCount   : số dòng trong BCDT_BMTH_ColumnExpr cho biểu

  Lỗi thường gặp & thông điệp:
    - 'Thiếu bảng cấu hình BMTH.'                                  : Bảng đích chưa được tạo.
    - '@ColumnsJson và @TermsJson phải là JSON hợp lệ.'            : JSON không đúng định dạng.
    - 'ColumnsJson thiếu ExcelCol.'                                 : Phần tử Columns thiếu ExcelCol.
    - 'TermsJson thiếu OutCol/Alias hoặc selector.'                 : Thiếu OutCol/Alias/ExcelRow/DataColumnName.
    - 'TermsJson tham chiếu OutCol không có trong ColumnsJson.'     : OutCol không được khai báo ở Columns.
    - 'Alias trong TermsJson chưa có hoặc không active.'            : Alias chưa tồn tại/IsActive=0.
    - 'ExprJson tham chiếu ExcelCol không có trong ColumnsJson.'    : ExcelCol ở ExprJson chưa có ở Columns.
    - Chung: 'Lỗi nạp cấu hình BMTH: %s'                            : Bao lỗi chi tiết từ TRY...CATCH.

  Hiệu năng & an toàn:
    - Toàn bộ thao tác chạy trong TRANSACTION; lỗi sẽ ROLLBACK.
    - Dùng bảng tạm/biến bảng và #MapIds để map nhanh OutCol → MapId.
    - Không thay đổi/đụng chạm bảng dữ liệu nguồn; chỉ ghi vào 4 bảng cấu hình.

  Ví dụ gọi nhanh:
    EXEC dbo.SP_BCDT_BMTH_Config_Upsert
      @TongHopBieuMauId=22,
      @AliasesJson  = N'[{"Alias":"BM3","BieuMauId":3,"TableName":"BCDT_DuLieu_BieuMau3","ValueColumn":"TongCong","IsActive":1}]',
      @ColumnsJson  = N'[{"ExcelCol":"C","RenderMode":"VALUE","SortOrder":1}]',
      @TermsJson    = N'[{"OutCol":"C","Alias":"BM3","DataColumnName":"TongCong","AggFn":"SUM"}]',
      @ExprJson     = N'{"G":"F/E"}',
      @PurgeOld     = 1,
      @UserId       = -1;

  Phiên bản:
    - v1.0 (2025-10-23): Khởi tạo.
    - v1.1 (2025-10-30): Hỗ trợ ExprJson ở cả 2 dạng (mảng/object); validate chặt chẽ hơn.
	- v1.2 (2025-10-31): Bổ sung TermFiltersJson (đọc & lưu).
============================================================================*/
CREATE   PROCEDURE [dbo].[SP_BCDT_BMTH_Config_Upsert]
(
    @TongHopBieuMauId INT,
    @AliasesJson  NVARCHAR(MAX) = NULL,
    @ColumnsJson  NVARCHAR(MAX),
    @TermsJson    NVARCHAR(MAX),
    @ExprJson     NVARCHAR(MAX) = NULL,
    @PurgeOld     BIT = 1,
    @UserId       INT = -1
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id=OBJECT_ID('dbo.BCDT_BMTH_BieuNguon_Alias') AND type='U')
       OR NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id=OBJECT_ID('dbo.BCDT_BMTH_ColumnMap') AND type='U')
       OR NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id=OBJECT_ID('dbo.BCDT_BMTH_ColumnMap_Term') AND type='U')
       OR NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id=OBJECT_ID('dbo.BCDT_BMTH_ColumnExpr') AND type='U')
    BEGIN
        RAISERROR(N'Thiếu bảng cấu hình BMTH.',16,1); RETURN;
    END

    IF ISJSON(@ColumnsJson) <> 1 OR ISJSON(@TermsJson) <> 1
    BEGIN
        RAISERROR(N'@ColumnsJson và @TermsJson phải là JSON hợp lệ.',16,1); RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        /* 1) Upsert alias nguồn (nếu có) */
        IF ISJSON(@AliasesJson)=1
        BEGIN
            ;WITH A AS (
              SELECT
                TRY_CONVERT(SYSNAME, JSON_VALUE(value,'$.Alias'))       AS Alias,
                TRY_CONVERT(INT,    JSON_VALUE(value,'$.BieuMauId'))    AS BieuMauId,
                TRY_CONVERT(SYSNAME,JSON_VALUE(value,'$.TableName'))    AS TableName,
                COALESCE(TRY_CONVERT(SYSNAME,JSON_VALUE(value,'$.ValueColumn')),N'TongCong') AS ValueColumn,
                COALESCE(TRY_CONVERT(BIT,    JSON_VALUE(value,'$.IsActive')),1) AS IsActive
              FROM OPENJSON(@AliasesJson)
            )
            MERGE dbo.BCDT_BMTH_BieuNguon_Alias AS T
            USING A AS S
            ON T.Alias=S.Alias
            WHEN MATCHED THEN UPDATE
              SET T.BieuMauId=S.BieuMauId, T.TableName=S.TableName, T.ValueColumn=S.ValueColumn, T.IsActive=S.IsActive
            WHEN NOT MATCHED THEN INSERT(Alias,BieuMauId,TableName,ValueColumn,IsActive)
              VALUES(S.Alias,S.BieuMauId,S.TableName,S.ValueColumn,S.IsActive);
        END

        /* 2) Xoá cấu hình cũ của biểu (nếu chọn) */
        IF @PurgeOld=1
        BEGIN
            DELETE t
            FROM dbo.BCDT_BMTH_ColumnMap_Term t
            JOIN dbo.BCDT_BMTH_ColumnMap m ON m.Id=t.MapId
            WHERE m.TongHopBieuMauId=@TongHopBieuMauId;

            DELETE FROM dbo.BCDT_BMTH_ColumnExpr WHERE TongHopBieuMauId=@TongHopBieuMauId;
            DELETE FROM dbo.BCDT_BMTH_ColumnMap WHERE TongHopBieuMauId=@TongHopBieuMauId;
        END

        /* 3) Insert ColumnMap */
        DECLARE @ColTemp TABLE(ExcelCol SYSNAME, RenderMode NVARCHAR(20), RoundDigits INT, IsActive BIT, SortOrder INT);
        INSERT INTO @ColTemp
        SELECT
          TRY_CONVERT(SYSNAME, JSON_VALUE(value,'$.ExcelCol')),
          UPPER(COALESCE(TRY_CONVERT(NVARCHAR(20),JSON_VALUE(value,'$.RenderMode')),'VALUE')),
          COALESCE(TRY_CONVERT(INT, JSON_VALUE(value,'$.RoundDigits')),0),
          COALESCE(TRY_CONVERT(BIT, JSON_VALUE(value,'$.IsActive')),1),
          COALESCE(TRY_CONVERT(INT, JSON_VALUE(value,'$.SortOrder')),9999)
        FROM OPENJSON(@ColumnsJson);

        IF EXISTS(SELECT 1 FROM @ColTemp WHERE ExcelCol IS NULL)
        BEGIN RAISERROR(N'ColumnsJson thiếu ExcelCol.',16,1); ROLLBACK; RETURN; END

        INSERT INTO dbo.BCDT_BMTH_ColumnMap(TongHopBieuMauId,ExcelCol,RenderMode,RoundDigits,IsActive)
        SELECT @TongHopBieuMauId, ExcelCol, RenderMode, RoundDigits, IsActive
        FROM @ColTemp ORDER BY SortOrder;

        IF OBJECT_ID('tempdb..#MapIds') IS NOT NULL DROP TABLE #MapIds;
        SELECT Id AS MapId, ExcelCol INTO #MapIds
        FROM dbo.BCDT_BMTH_ColumnMap WHERE TongHopBieuMauId=@TongHopBieuMauId;

        /* 4) Insert Terms (đã bổ sung TermFiltersJson) */
        DECLARE @TermTemp TABLE(
          OutCol SYSNAME, 
          Alias SYSNAME, 
          ExcelRow INT NULL, 
          DataColumnName SYSNAME NULL,
          AggFn NVARCHAR(10), 
          Weight DECIMAL(18,6), 
          Scale DECIMAL(18,6),
          UnitScopeMode NVARCHAR(10) NULL, 
          UnitIdsJson NVARCHAR(MAX) NULL, 
          ThuTu INT,
          TermFiltersJson NVARCHAR(MAX) NULL,
		  BTieuChiScopeMode NVARCHAR(MAX) NULL,
		  BieuTieuChiIdsJson NVARCHAR(MAX) NULL,
		  CriteriaCode NVARCHAR(MAX) NULL,
		  CriteriaScope NVARCHAR(MAX) NULL,
		  CriteriaIndex INT NULL,
		  CriteriaPickMode NVARCHAR(MAX) NULL,
		  DistinctOn NVARCHAR(MAX) NULL
        );

        INSERT INTO @TermTemp
        SELECT
          TRY_CONVERT(SYSNAME, JSON_VALUE(value,'$.OutCol')),
          TRY_CONVERT(SYSNAME, JSON_VALUE(value,'$.Alias')),
          TRY_CONVERT(INT,     JSON_VALUE(value,'$.ExcelRow')),
          TRY_CONVERT(SYSNAME, JSON_VALUE(value,'$.DataColumnName')),
          UPPER(COALESCE(TRY_CONVERT(NVARCHAR(10), JSON_VALUE(value,'$.AggFn')),'SUM')),
          COALESCE(TRY_CONVERT(DECIMAL(18,6), JSON_VALUE(value,'$.Weight')),1),
          COALESCE(TRY_CONVERT(DECIMAL(18,6), JSON_VALUE(value,'$.Scale')),1),
          NULLIF(UPPER(TRY_CONVERT(NVARCHAR(10), JSON_VALUE(value,'$.UnitScopeMode'))),''),
          JSON_VALUE(value,'$.UnitIdsJson'),
          COALESCE(TRY_CONVERT(INT, JSON_VALUE(value,'$.ThuTu')),9999),
          JSON_QUERY(value,'$.TermFiltersJson'),
		  JSON_VALUE(value,'$.BTieuChiScopeMode'),
		  JSON_QUERY(value,'$.BieuTieuChiIdsJson'),
		  JSON_VALUE(value,'$.CriteriaCode'),
		  JSON_VALUE(value,'$.CriteriaScope'),
		  COALESCE(TRY_CONVERT(INT, JSON_VALUE(value,'$.CriteriaIndex')),1),
		  JSON_VALUE(value,'$.CriteriaPickMode'),
		  JSON_VALUE(value,'$.DistinctOn')
        FROM OPENJSON(@TermsJson);

        -- Validate tối thiểu
        IF EXISTS (SELECT 1 FROM @TermTemp WHERE OutCol IS NULL OR Alias IS NULL OR (ExcelRow IS NULL AND DataColumnName IS NULL))
        BEGIN RAISERROR(N'TermsJson thiếu OutCol/Alias hoặc selector.',16,1); ROLLBACK; RETURN; END

        IF EXISTS (SELECT 1 FROM @TermTemp WHERE TermFiltersJson IS NOT NULL AND ISJSON(TermFiltersJson) <> 1)
        BEGIN RAISERROR(N'TermFiltersJson phải là JSON hợp lệ.',16,1); ROLLBACK; RETURN; END

        IF EXISTS (
          SELECT 1 FROM @TermTemp t
          WHERE NOT EXISTS(SELECT 1 FROM #MapIds m WHERE m.ExcelCol=t.OutCol)
        )
        BEGIN RAISERROR(N'TermsJson tham chiếu OutCol không có trong ColumnsJson.',16,1); ROLLBACK; RETURN; END

        IF EXISTS (
          SELECT 1 FROM @TermTemp t
          WHERE NOT EXISTS(SELECT 1 FROM dbo.BCDT_BMTH_BieuNguon_Alias a WHERE a.Alias=t.Alias AND a.IsActive=1)
        )
        BEGIN RAISERROR(N'Alias trong TermsJson chưa có hoặc không active.',16,1); ROLLBACK; RETURN; END

        INSERT INTO dbo.BCDT_BMTH_ColumnMap_Term
          (MapId,ThuTu,Alias,DataColumnName,ExcelRow,AggFn,Weight,Scale,UnitScopeMode,UnitIdsJson,IsActive,TermFiltersJson,BTieuChiScopeMode,BieuTieuChiIdsJson,CriteriaCode,CriteriaScope,CriteriaIndex,CriteriaPickMode,DistinctOn)
        SELECT m.MapId,t.ThuTu,t.Alias,t.DataColumnName,t.ExcelRow,t.AggFn,t.Weight,t.Scale,t.UnitScopeMode,t.UnitIdsJson,1,t.TermFiltersJson,t.BTieuChiScopeMode,t.BieuTieuChiIdsJson,t.CriteriaCode,t.CriteriaScope,t.CriteriaIndex,t.CriteriaPickMode,t.DistinctOn
        FROM @TermTemp t 
        JOIN #MapIds m ON m.ExcelCol=t.OutCol
        ORDER BY t.OutCol,t.ThuTu;

        /* 5) Insert ColumnExpr (nếu có) */
        IF ISJSON(@ExprJson)=1
        BEGIN
            DECLARE @ExprTemp TABLE(ExcelCol SYSNAME, ExprText NVARCHAR(MAX), RoundDigits INT, IsActive BIT);

            -- Dạng mảng object
            IF JSON_VALUE(@ExprJson,'$[0].ExcelCol') IS NOT NULL
            BEGIN
                INSERT INTO @ExprTemp(ExcelCol,ExprText,RoundDigits,IsActive)
                SELECT ExcelCol, ExprText, COALESCE(RoundDigits,0), COALESCE(IsActive,1)
                FROM OPENJSON(@ExprJson)
                WITH (
                    ExcelCol    SYSNAME        '$.ExcelCol',
                    ExprText    NVARCHAR(MAX)  '$.ExprText',
                    RoundDigits INT            '$.RoundDigits',
                    IsActive    BIT            '$.IsActive'
                );
            END
            ELSE
            BEGIN
                -- Dạng object map: {"G":"F/E", "H":"(C+D)/E", ...}
                INSERT INTO @ExprTemp(ExcelCol,ExprText,RoundDigits,IsActive)
                SELECT TRY_CONVERT(SYSNAME,[key]),
                       TRY_CONVERT(NVARCHAR(MAX),value),
                       0, 1
                FROM OPENJSON(@ExprJson);
            END

            IF EXISTS (
              SELECT 1 FROM @ExprTemp e
              WHERE NOT EXISTS (SELECT 1 FROM #MapIds m WHERE m.ExcelCol=e.ExcelCol)
            )
            BEGIN RAISERROR(N'ExprJson tham chiếu ExcelCol không có trong ColumnsJson.',16,1); ROLLBACK; RETURN; END

            INSERT INTO dbo.BCDT_BMTH_ColumnExpr(TongHopBieuMauId,ExcelCol,ExprText,RoundDigits,IsActive)
            SELECT @TongHopBieuMauId,e.ExcelCol,e.ExprText,e.RoundDigits,e.IsActive FROM @ExprTemp e;
        END

        COMMIT;

        SELECT
          (SELECT COUNT(*) FROM dbo.BCDT_BMTH_ColumnMap m WHERE m.TongHopBieuMauId=@TongHopBieuMauId) AS ColumnCount,
          (SELECT COUNT(*) FROM dbo.BCDT_BMTH_ColumnMap_Term t JOIN dbo.BCDT_BMTH_ColumnMap m ON m.Id=t.MapId WHERE m.TongHopBieuMauId=@TongHopBieuMauId) AS TermCount,
          (SELECT COUNT(*) FROM dbo.BCDT_BMTH_ColumnExpr e WHERE e.TongHopBieuMauId=@TongHopBieuMauId) AS ExprCount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        DECLARE @msg NVARCHAR(4000)=ERROR_MESSAGE();
        RAISERROR(N'Lỗi nạp cấu hình BMTH: %s',16,1,@msg);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_BMTH_ExecTerm]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_BCDT_BMTH_ExecTerm]
(
    @Tbl               SYSNAME,            -- 'BCD...3' hoặc 'dbo.BCD...3' đều được
    @IsRowPath         BIT,                -- 1 = ROW path (xài @ValueCol); 0 = DATA path (xài @DataCol)
    @ValueCol          SYSNAME   = NULL,   -- ví dụ 'GiaTri' (ROW path)
    @DataCol           SYSNAME   = NULL,   -- ví dụ 'H' hay tên cột dữ liệu (DATA path)

    @Dim               INT,
    @OutCol            SYSNAME,
    @DonVi             INT,
    @KH                INT,
    @ExcelRow          INT        = NULL,
    @AggFn             NVARCHAR(10),
    @W                 DECIMAL(18,6),
    @S                 DECIMAL(18,6),

    @TermFiltersJson   NVARCHAR(MAX) = NULL,
    @DistinctOn        NVARCHAR(MAX) = NULL
)
AS
BEGIN
  SET NOCOUNT ON;

  /* 0) Xây FROM an toàn (hỗ trợ @Tbl có/không có schema) */
  DECLARE @FromTable NVARCHAR(300);
  IF CHARINDEX(N'.', @Tbl) > 0
      SET @FromTable = QUOTENAME(PARSENAME(@Tbl,2)) + N'.' + QUOTENAME(PARSENAME(@Tbl,1));
  ELSE
      SET @FromTable = N'[dbo].' + QUOTENAME(@Tbl);

  /* 1) Chọn cột đếm DISTINCT (Mode: 0=không distinct, 1=distinct một/nhiều cột) */
  DECLARE @Mode TINYINT =
    CASE
      WHEN @DistinctOn IS NULL OR @DistinctOn = N'' THEN 0
      WHEN ISJSON(@DistinctOn)=1 THEN 1
      ELSE 1
    END;

  DECLARE @ValCol SYSNAME = CASE WHEN @IsRowPath=1 THEN @ValueCol ELSE @DataCol END;
  IF @ValCol IS NULL AND @Mode=0
  BEGIN
    RAISERROR(N'Missing value/data column.',16,1); RETURN;
  END;

  /* 2) Build danh sách cột DISTINCT (hỗ trợ string hoặc JSON array) */
  DECLARE @ColsList NVARCHAR(MAX) = NULL;
  IF @Mode=1
  BEGIN
    IF ISJSON(@DistinctOn)=1
    BEGIN
      SELECT @ColsList =
        STRING_AGG(N'src.' + QUOTENAME(JSON_VALUE(v.value,'$')), N',')
      FROM OPENJSON(@DistinctOn) v;
    END
    ELSE
    BEGIN
      -- Chuỗi đơn 'KKTKCN_Id' hoặc 'ColA,ColB'
      ;WITH x AS
      (
        SELECT LTRIM(RTRIM(value)) AS c
        FROM STRING_SPLIT(@DistinctOn, N',')
      )
      SELECT @ColsList = STRING_AGG(N'src.' + QUOTENAME(c), N',')
      FROM x WHERE NULLIF(c,N'') IS NOT NULL;
    END
    IF NULLIF(@ColsList,N'') IS NULL
    BEGIN
      RAISERROR(N'DistinctOn is empty.',16,1); RETURN;
    END
  END

  --PRINT @TermFiltersJson

  /* 3) Predicate từ JSON filter */
  DECLARE @Pred NVARCHAR(MAX) = COALESCE(dbo.fn_BCDT_BuildTermPredicate(N'src', @TermFiltersJson), N'');

  --PRINT @Pred

  /* 4) Áp dụng RowScope (nếu caller có tạo) */
  DECLARE @JoinScope NVARCHAR(MAX) = N'';
  DECLARE @WhereScope NVARCHAR(MAX) = N'';
  IF OBJECT_ID('tempdb..#BMTH_RowScope_GUID') IS NOT NULL
  BEGIN
    SET @JoinScope  += N'
      LEFT JOIN #BMTH_RowScope_GUID g
             ON g.DimId = @DimOut AND g.DonViId = src.DonViId
            AND g.KeHoachId = src.KeHoachId AND g.CauTrucGUID = src.CauTrucGUID';
    SET @WhereScope += N' AND g.DimId IS NOT NULL';
  END
  IF OBJECT_ID('tempdb..#BMTH_RowScope_TieuChi') IS NOT NULL
  BEGIN
    SET @JoinScope  += N'
      LEFT JOIN #BMTH_RowScope_TieuChi t
             ON t.DimId = @DimOut AND t.DonViId = src.DonViId
            AND t.KeHoachId = src.KeHoachId AND t.TieuChiId = src.TieuChiId';
    SET @WhereScope += N' AND t.DimId IS NOT NULL';
  END

  /* 5) Dựng SELECT cho 3 trường hợp */
  DECLARE @SelectExpr NVARCHAR(MAX);

  IF @Mode=1
  BEGIN
    SET @SelectExpr = N'
      SELECT @DimOut, @OutColOut, COUNT(DISTINCT ' + @ColsList + N') * @WOut * @SOut
      FROM ' + @FromTable + N' src
      LEFT JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel cel
        ON cel.CauTrucGUID=src.CauTrucGUID AND cel.DonViId=src.DonViId AND cel.KeHoachId=src.KeHoachId
      ' + @JoinScope + N'
      WHERE src.DonViId=@DonViOut
        AND src.KeHoachId=@KHOut
        AND ISNULL(src.BitDaXoa,0)=0' +
        CASE WHEN @ExcelRow IS NULL THEN N'' ELSE N' AND cel.ExcelRow=@ExcelRowOut' END +
        @WhereScope + N'
      ' + @Pred;
  END
  ELSE
  BEGIN
    SET @SelectExpr = N'
      SELECT @DimOut, @OutColOut,
             (CASE UPPER(@AggFnOut)
                WHEN N''AVG''   THEN AVG(COALESCE(CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@ValCol) + N'),0.0))
                WHEN N''MIN''   THEN MIN(COALESCE(CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@ValCol) + N'),0.0))
                WHEN N''MAX''   THEN MAX(COALESCE(CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@ValCol) + N'),0.0))
                WHEN N''COUNT'' THEN COUNT(1)
                ELSE SUM(COALESCE(CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@ValCol) + N'),0.0))
              END) * @WOut * @SOut
      FROM ' + @FromTable + N' src
      LEFT JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel cel
        ON cel.CauTrucGUID=src.CauTrucGUID AND cel.DonViId=src.DonViId AND cel.KeHoachId=src.KeHoachId
      ' + @JoinScope + N'
      WHERE src.DonViId=@DonViOut
        AND src.KeHoachId=@KHOut
        AND ISNULL(src.BitDaXoa,0)=0' +
        CASE WHEN @ExcelRow IS NULL THEN N'' ELSE N' AND cel.ExcelRow=@ExcelRowOut' END +
        @WhereScope + N'
      ' + @Pred;
  END

  --PRINT @SelectExpr

  /* 6) Ghi vào #Base */
  DECLARE @SQL NVARCHAR(MAX) = N'INSERT INTO #Base(DimId,OutCol,Val) ' + @SelectExpr + N';';

  EXEC sp_executesql
    @SQL,
    N'@DimOut INT,@OutColOut SYSNAME,@DonViOut INT,@KHOut INT,@ExcelRowOut INT,@AggFnOut NVARCHAR(10),@WOut DECIMAL(18,6),@SOut DECIMAL(18,6)',
    @DimOut=@Dim, @OutColOut=@OutCol, @DonViOut=@DonVi, @KHOut=@KH, @ExcelRowOut=@ExcelRow,
    @AggFnOut=@AggFn, @WOut=@W, @SOut=@S;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_BMTH_RenderNarrow]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*============================================================================
  STORED PROCEDURE: dbo.SP_BCDT_BMTH_RenderNarrow (v1.1 - 2025-10-29)
  Purpose  : Tính toàn bộ VALUE + dựng EXPR ở dạng dùng chung (narrow).
  Contract : Caller đã chuẩn bị #UnitSet(DimId INT, DonViId INT PRIMARY KEY(DimId,DonViId))
  Output   : #Agg_Narrow(DimId, OutCol, SumVal)
             #ValueCols(Col)
             #ExprBuilt(ExcelCol, ExprSql)

  Update v1.1:
  - TÁCH NHỎ query string động (SET ... += ...) để tránh lỗi NVARCHAR literal quá dài.
  - Thống nhất xử lý ScopeClean ở cả hai nhánh (coalesce về 'SAME_PARENT' nếu rỗng).
============================================================================*/
CREATE   PROCEDURE [dbo].[SP_BCDT_BMTH_RenderNarrow]
(
    @TongHopBieuMauId INT,
    @NgayBatDauInt    INT,
    @NgayKetThucInt   INT,
    @KeHoachPickMode  NVARCHAR(10) = N'SUM' -- SUM | LATEST
)
AS
BEGIN
    SET NOCOUNT ON;

	IF @NgayBatDauInt IS NULL OR @NgayKetThucInt IS NULL OR @NgayBatDauInt > @NgayKetThucInt
	BEGIN
		RAISERROR(N'Kỳ báo cáo không hợp lệ.', 16, 1);
		RETURN;
	END;

	IF NOT EXISTS (
		SELECT 1 FROM dbo.BCDT_BMTH_ColumnMap
		WHERE TongHopBieuMauId=@TongHopBieuMauId AND IsActive=1
	)
	BEGIN
		RAISERROR(N'Chưa có cấu hình cột cho BMTH %d.', 16, 1, @TongHopBieuMauId);
		RETURN;
	END;

	--Trạng thái kế hoạch, biểu mẫu đã tiếp nhận để được tổng hợp
	DECLARE @TrangThai INT = 1007;

    /* 0) Bảo vệ đầu vào */
    IF OBJECT_ID('tempdb..#UnitSet') IS NULL
    BEGIN
        CREATE TABLE #UnitSet(
            DimId   INT     NOT NULL,
            DonViId INT     NOT NULL,
            CONSTRAINT PK_UnitSet PRIMARY KEY (DimId, DonViId)
        );
    END;

    /* 1) Đọc ColumnMap & Term */
    IF OBJECT_ID('tempdb..#Map') IS NOT NULL DROP TABLE #Map;
    CREATE TABLE #Map(MapId INT PRIMARY KEY, OutCol SYSNAME, RenderMode NVARCHAR(20), RoundDigits INT NULL);

    INSERT INTO #Map
    SELECT Id, ExcelCol, RenderMode, RoundDigits
    FROM dbo.BCDT_BMTH_ColumnMap
    WHERE TongHopBieuMauId=@TongHopBieuMauId AND IsActive=1;

    IF NOT EXISTS (SELECT 1 FROM #Map)
    BEGIN RAISERROR(N'Không có cấu hình cột cho BMTH %d.',16,1,@TongHopBieuMauId); RETURN; END

    IF OBJECT_ID('tempdb..#Term') IS NOT NULL DROP TABLE #Term;
    CREATE TABLE #Term(
      MapId INT, OutCol SYSNAME, Alias SYSNAME, DataColumnName SYSNAME NULL, ExcelRow INT NULL,
      AggFn NVARCHAR(10), Weight DECIMAL(18,6), Scale DECIMAL(18,6),
      UnitScopeMode NVARCHAR(10) NULL, UnitIdsJson NVARCHAR(MAX) NULL,
      CriteriaCode NVARCHAR(100) NULL,
      CriteriaScope NVARCHAR(200) NULL,
      CriteriaIndex INT NULL,
      CriteriaPickMode NVARCHAR(10) NULL,  -- INDEX | ALL
      BTieuChiScopeMode NVARCHAR(10) NULL, -- ALL | LIST | EXCLUDE
      BieuTieuChiIdsJson NVARCHAR(MAX) NULL,
	  TermFiltersJson NVARCHAR(MAX) NULL,
	  DistinctOn NVARCHAR(MAX) NULL
    );

    INSERT INTO #Term
    SELECT t.MapId, m.OutCol, t.Alias, t.DataColumnName, t.ExcelRow,
           UPPER(t.AggFn), COALESCE(t.Weight,1), COALESCE(t.Scale,1),
           NULLIF(UPPER(t.UnitScopeMode),''), t.UnitIdsJson,
           NULLIF(t.CriteriaCode,''), NULLIF(UPPER(t.CriteriaScope),''), NULLIF(t.CriteriaIndex,0),
           COALESCE(NULLIF(UPPER(t.CriteriaPickMode),N''), N'INDEX'),
           NULLIF(UPPER(t.BTieuChiScopeMode),''), t.BieuTieuChiIdsJson,
		   NULLIF(t.TermFiltersJson,N''),
		   NULLIF(t.DistinctOn,N'')
    FROM dbo.BCDT_BMTH_ColumnMap_Term t
    JOIN #Map m ON m.MapId=t.MapId
    WHERE t.IsActive=1;

	CREATE INDEX IX_Term_Alias_DataCol
	  ON #Term(Alias, DataColumnName)
	  INCLUDE(OutCol, AggFn, ExcelRow, UnitScopeMode, UnitIdsJson,
			  CriteriaCode, CriteriaScope, CriteriaIndex, CriteriaPickMode,
			  BTieuChiScopeMode, BieuTieuChiIdsJson, TermFiltersJson, DistinctOn);

    IF NOT EXISTS (SELECT 1 FROM #Term)
    BEGIN RAISERROR(N'Không có term cho BMTH %d.',16,1,@TongHopBieuMauId); RETURN; END

    /* 2) Alias nguồn */
    IF OBJECT_ID('tempdb..#Alias') IS NOT NULL DROP TABLE #Alias;
    CREATE TABLE #Alias(Alias SYSNAME PRIMARY KEY, BieuMauId INT, TableName SYSNAME, ValueColumn SYSNAME);

    INSERT INTO #Alias
    SELECT a.Alias, a.BieuMauId, a.TableName, a.ValueColumn
    FROM dbo.BCDT_BMTH_BieuNguon_Alias a
    WHERE a.IsActive=1 AND a.Alias IN (SELECT DISTINCT Alias FROM #Term);



    /* 3) KeHoach pick */
    IF OBJECT_ID('tempdb..#PickKH') IS NOT NULL DROP TABLE #PickKH;
    CREATE TABLE #PickKH(DonViId INT PRIMARY KEY, KeHoachId INT);

    IF UPPER(@KeHoachPickMode)=N'LATEST'
	BEGIN
		;WITH Pick AS (
			SELECT
				k.DonViId,
				k.Id AS KeHoachId,
				ROW_NUMBER() OVER (
					PARTITION BY k.DonViId
					ORDER BY d.NgayKetThucInt DESC, k.Id DESC
				) AS rn
			FROM dbo.BCDT_KeHoach k
			JOIN dbo.BCDT_KeHoach_Dot d ON k.DotId=d.Id AND d.BitDaXoa=0
			WHERE k.BitDaXoa=0
			  AND d.NgayBatDauInt = @NgayBatDauInt --chuyen tu trong khoang thanh bang chinh xac
			  AND d.NgayKetThucInt = @NgayKetThucInt
			  AND k.DonViId IN (SELECT DonViId FROM #UnitSet)
		)
		INSERT INTO #PickKH(DonViId, KeHoachId)
		SELECT DonViId, KeHoachId FROM Pick WHERE rn=1;
	END

    /* 4) Base narrow */
    IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base;
    CREATE TABLE #Base(DimId INT, OutCol SYSNAME, Val DECIMAL(38,6));

    DECLARE @alias SYSNAME,@bmId INT,@tbl SYSNAME,@valcol SYSNAME;
    DECLARE @sqlRow  NVARCHAR(MAX) = N'', @sqlData NVARCHAR(MAX) = N'';

	-- Row-scope tùy chọn (nếu caller tạo #BMTH_RowScope_* thì bật)
	DECLARE @hasScopeGuid BIT = CASE WHEN OBJECT_ID('tempdb..#BMTH_RowScope_GUID')     IS NOT NULL THEN 1 ELSE 0 END;
	DECLARE @hasScopeTC   BIT = CASE WHEN OBJECT_ID('tempdb..#BMTH_RowScope_TieuChi') IS NOT NULL THEN 1 ELSE 0 END;
	DECLARE @hasDimBind   BIT = CASE WHEN OBJECT_ID('tempdb..#DimBind')               IS NOT NULL THEN 1 ELSE 0 END;

	-- Hàng đợi per-term special cho ROW path
	IF OBJECT_ID('tempdb..#U_Row') IS NOT NULL DROP TABLE #U_Row;
	CREATE TABLE #U_Row
	(
	  OutCol          SYSNAME,
	  AggFn           NVARCHAR(10),
	  Weight          DECIMAL(18,6),
	  Scale           DECIMAL(18,6),
	  DimId           INT,
	  DonViId         INT,
	  KeHoachId       INT,
	  ExcelRow        INT NULL,
	  TermFiltersJson NVARCHAR(MAX) NULL,
	  DistinctOn      NVARCHAR(MAX) NULL
	);

	-- Hàng đợi per-term special cho DATA path
	IF OBJECT_ID('tempdb..#U_Data') IS NOT NULL DROP TABLE #U_Data;
	CREATE TABLE #U_Data
	(
	  OutCol          SYSNAME,
	  DataColumnName  SYSNAME,
	  AggFn           NVARCHAR(10),
	  Weight          DECIMAL(18,6),
	  Scale           DECIMAL(18,6),
	  DimId           INT,
	  DonViId         INT,
	  KeHoachId       INT,
	  ExcelRow        INT NULL,
	  TermFiltersJson NVARCHAR(MAX) NULL,
	  DistinctOn      NVARCHAR(MAX) NULL
	);

    DECLARE curA CURSOR LOCAL FAST_FORWARD FOR
        SELECT Alias,BieuMauId,TableName,ValueColumn FROM #Alias;
    OPEN curA; FETCH NEXT FROM curA INTO @alias,@bmId,@tbl,@valcol;
    WHILE @@FETCH_STATUS=0
    BEGIN
        DECLARE @hasExcelRowOnly BIT =
        CASE WHEN EXISTS (
            SELECT 1 FROM #Term
            WHERE Alias=@alias
              AND DataColumnName IS NULL
              AND (ExcelRow IS NOT NULL OR CriteriaCode IS NOT NULL OR BTieuChiScopeMode IS NOT NULL)
        ) THEN 1 ELSE 0 END;

        /* 4.1) Term KHÔNG có DataColumnName (ExcelRow/Criteria/BTC Id) */
        IF @hasExcelRowOnly=1
        BEGIN
            SET @sqlRow  = CAST(N'' AS NVARCHAR(MAX));
            SET @sqlRow += N'
            ;WITH TermX AS (
              SELECT DISTINCT
                t.OutCol, t.ExcelRow, t.AggFn, t.Weight, t.Scale, t.UnitScopeMode, t.UnitIdsJson,
                t.CriteriaCode, t.CriteriaScope, t.CriteriaIndex, t.CriteriaPickMode,
                t.BTieuChiScopeMode, t.BieuTieuChiIdsJson,t.TermFiltersJson,t.DistinctOn
              FROM #Term t
              WHERE t.Alias=@alias
                AND t.DataColumnName IS NULL
                AND (t.ExcelRow IS NOT NULL OR t.CriteriaCode IS NOT NULL OR t.BTieuChiScopeMode IS NOT NULL)
            ),';
			SET @sqlRow += N'
			KH_TH AS (
			  SELECT th.KeHoachId
			  FROM dbo.BCDT_KeHoach_TongHop th
			  WHERE th.BieuMauId = @bmId
				AND th.TrangThai = @TrangThai
			),';
            SET @sqlRow += N'
			KH AS (
			  SELECT DISTINCT c.DonViId, c.Id AS KeHoachId
			  FROM dbo.BCDT_KeHoach c
			  JOIN dbo.BCDT_KeHoach_Dot d ON c.DotId=d.Id AND d.BitDaXoa=0
			  JOIN KH_TH th ON th.KeHoachId = c.Id
			  WHERE c.BitDaXoa=0
				AND d.NgayBatDauInt = @NgayBatDauInt
				AND d.NgayKetThucInt = @NgayKetThucInt
				AND @KeHoachPickMode=N''SUM''
			  UNION ALL
			  SELECT DISTINCT pk.DonViId, pk.KeHoachId
			  FROM #PickKH pk
			  JOIN KH_TH th ON th.KeHoachId = pk.KeHoachId
			  WHERE @KeHoachPickMode=N''LATEST''
			),';
            SET @sqlRow += N'
            U0 AS (
              SELECT tx.*, u.DimId, u.DonViId
              FROM TermX tx
              JOIN #UnitSet u ON 1=1
              WHERE (tx.UnitScopeMode IS NULL)
                 OR (tx.UnitScopeMode = N''ALL'')
                 OR (tx.UnitScopeMode = N''LIST''    AND ISJSON(tx.UnitIdsJson)=1 AND EXISTS (SELECT 1 FROM OPENJSON(tx.UnitIdsJson) j WHERE TRY_CONVERT(INT,j.value)=u.DonViId))
                 OR (tx.UnitScopeMode = N''EXCLUDE'' AND (ISJSON(tx.UnitIdsJson)<>1 OR NOT EXISTS (SELECT 1 FROM OPENJSON(tx.UnitIdsJson) j WHERE TRY_CONVERT(INT,j.value)=u.DonViId)))
            ),';
            SET @sqlRow += N'
            U1 AS (
              SELECT
                u.OutCol, u.AggFn, u.Weight, u.Scale, u.UnitScopeMode, u.UnitIdsJson,
                u.DimId, u.DonViId, u.CriteriaPickMode,
                u.CriteriaCode, u.CriteriaScope, u.ExcelRow, u.CriteriaIndex,
                CASE WHEN u.CriteriaScope LIKE N''BY_PARENT_CODE:%'' THEN N''BY_PARENT_CODE''
                     ELSE COALESCE(NULLIF(u.CriteriaScope,N''''),N''SAME_PARENT'') END AS ScopeClean,
                CASE WHEN u.CriteriaScope LIKE N''BY_PARENT_CODE:%'' 
                     THEN SUBSTRING(u.CriteriaScope, LEN(N''BY_PARENT_CODE:'')+1, 4000) ELSE NULL END AS ParentCodeInToken,
                u.BTieuChiScopeMode, u.BieuTieuChiIdsJson,
				u.TermFiltersJson,
				u.DistinctOn
              FROM U0 u
            ),';
            SET @sqlRow += N'
            UFilter AS (
              SELECT
                u1.OutCol, u1.AggFn, u1.Weight, u1.Scale,
                u1.DimId, u1.DonViId, u1.CriteriaPickMode,
                k.KeHoachId,
                CASE
                  WHEN u1.BTieuChiScopeMode IS NOT NULL THEN u1.ExcelRow
                  WHEN u1.CriteriaCode IS NULL THEN u1.ExcelRow
                  WHEN u1.CriteriaPickMode = N''INDEX'' THEN
                    dbo.fn_BCDT_ResolveTieuChiRow_ByIndex(
                      @bmId, u1.DonViId, k.KeHoachId, u1.CriteriaCode,
                      NULL, COALESCE(NULLIF(u1.ScopeClean,N''''),N''SAME_PARENT''), COALESCE(NULLIF(u1.CriteriaIndex,0),1), u1.ParentCodeInToken
                    )
                  ELSE NULL
                END AS ExcelRow,
                u1.CriteriaCode, u1.CriteriaScope,
                u1.BTieuChiScopeMode, u1.BieuTieuChiIdsJson,
				u1.TermFiltersJson,
				u1.DistinctOn
              FROM U1 u1
              JOIN KH k ON k.DonViId = u1.DonViId
            ),';
            SET @sqlRow += N'
            Cel AS (
              SELECT DISTINCT CauTrucGUID, DonViId, KeHoachId, ExcelRow
              FROM dbo.BCDT_CauTruc_BieuMau_ViTriExcel
              WHERE BieuMauId = ';
            SET @sqlRow += CAST(@bmId AS NVARCHAR(20));
            SET @sqlRow += N'
            ),';
            SET @sqlRow += N'
            CelCrit AS (
              SELECT DISTINCT vt.DonViId, vt.KeHoachId, vt.ExcelRow, uf.OutCol, uf.CriteriaCode,
                     COALESCE(uf.CriteriaScope,N''ANY'') AS CriteriaScope, uf.CriteriaPickMode
              FROM UFilter uf
              JOIN KH k ON k.DonViId=uf.DonViId
              JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel vt
                ON vt.BieuMauId=';
            SET @sqlRow += CAST(@bmId AS NVARCHAR(20));
            SET @sqlRow += N'
               AND vt.DonViId=k.DonViId AND vt.KeHoachId=k.KeHoachId
              JOIN dbo.BCDT_CauTruc_BieuMau tc ON tc.CauTrucGUID=vt.CauTrucGUID
              WHERE uf.CriteriaPickMode=N''ALL'' AND uf.CriteriaCode IS NOT NULL
                AND COALESCE(uf.CriteriaScope,N''ANY'') IN (N''ANY'', N'''')
                AND tc.MaTieuChi=uf.CriteriaCode
            ),';
            SET @sqlRow += N'
            CelCritBTC AS (
              SELECT DISTINCT vt.DonViId, vt.KeHoachId, vt.ExcelRow, uf.OutCol
              FROM UFilter uf
              JOIN KH k ON k.DonViId=uf.DonViId
              JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel vt
                ON vt.BieuMauId=';
            SET @sqlRow += CAST(@bmId AS NVARCHAR(20));
            SET @sqlRow += N'
               AND vt.DonViId=k.DonViId AND vt.KeHoachId=k.KeHoachId
              JOIN dbo.BCDT_CauTruc_BieuMau tc ON tc.CauTrucGUID=vt.CauTrucGUID
              WHERE uf.BTieuChiScopeMode IS NOT NULL
                      AND (
                            UPPER(uf.BTieuChiScopeMode)=N''ALL''
                         OR (
                              ISJSON(uf.BieuTieuChiIdsJson)=1
                              AND 
                              (
                                (UPPER(uf.BTieuChiScopeMode)=N''LIST'' AND EXISTS (SELECT 1 FROM OPENJSON(uf.BieuTieuChiIdsJson) j WHERE TRY_CONVERT(INT,j.value)=tc.BieuTieuChiId))
                                OR 
                                (UPPER(uf.BTieuChiScopeMode)=N''EXCLUDE'' AND NOT EXISTS (SELECT 1 FROM OPENJSON(uf.BieuTieuChiIdsJson) j WHERE TRY_CONVERT(INT,j.value)=tc.BieuTieuChiId))
                              )
                            )
                          )
            ),';
            SET @sqlRow += N'
            UFilterExp AS (
              SELECT u.OutCol,u.AggFn,u.Weight,u.Scale,u.DimId,u.DonViId,
                     COALESCE(u.ExcelRow, cc.ExcelRow, cb.ExcelRow) AS ExcelRow,
                     COALESCE(u.KeHoachId, cc.KeHoachId, cb.KeHoachId) AS KeHoachId,
					 u.TermFiltersJson,
					 u.DistinctOn
              FROM UFilter u
              LEFT JOIN CelCrit cc
                     ON u.BTieuChiScopeMode IS NULL
                    AND u.CriteriaPickMode = N''ALL''
                    AND cc.OutCol       = u.OutCol
                    AND cc.DonViId      = u.DonViId
                    AND cc.CriteriaCode = u.CriteriaCode
                    AND cc.CriteriaScope= COALESCE(u.CriteriaScope, N''ANY'')
                    AND cc.KeHoachId    = u.KeHoachId
              LEFT JOIN CelCritBTC cb
                     ON u.BTieuChiScopeMode IS NOT NULL
                    AND cb.OutCol   = u.OutCol
                    AND cb.DonViId  = u.DonViId
                    AND cb.KeHoachId= u.KeHoachId
              WHERE
                (
                  u.BTieuChiScopeMode IS NULL AND
                  (
                    (u.CriteriaCode IS NOT NULL AND (
                       (u.CriteriaPickMode=N''INDEX'' AND u.ExcelRow IS NOT NULL) OR
                       (u.CriteriaPickMode=N''ALL''   AND cc.ExcelRow IS NOT NULL)
                    ))
                    OR (u.CriteriaCode IS NULL)
                  )
                )
                OR
                (
                  u.BTieuChiScopeMode IS NOT NULL
                  AND (u.ExcelRow IS NOT NULL OR cb.ExcelRow IS NOT NULL)
                )
            )';
		   SET @sqlRow += N'			
			 SELECT 
			   OutCol, AggFn, Weight, Scale, DimId, DonViId, ExcelRow, KeHoachId, TermFiltersJson, DistinctOn
			 INTO #UFE
			 FROM UFilterExp;';

           SET @sqlRow += N'
			INSERT INTO #Base(DimId,OutCol,Val)
            SELECT u.DimId, u.OutCol,
                   (CASE u.AggFn
					 WHEN N''AVG''   THEN AVG(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6),src.' + QUOTENAME(@valcol) + N'), 0),0.0))
					 WHEN N''MIN''   THEN MIN(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6),src.' + QUOTENAME(@valcol) + N'), 0),0.0))
					 WHEN N''MAX''   THEN MAX(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6),src.' + QUOTENAME(@valcol) + N'), 0),0.0))
					 WHEN N''COUNT'' THEN COUNT(1)
					 ELSE SUM(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6),src.' + QUOTENAME(@valcol) + N'), 0),0.0))
					END) * u.Weight * u.Scale
			FROM #UFE u
			LEFT JOIN dbo.' + QUOTENAME(@tbl) + N' src
				   ON src.DonViId = u.DonViId
				  AND src.KeHoachId = u.KeHoachId
				  AND src.BitDaXoa = 0
			LEFT JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel cel
				   ON cel.CauTrucGUID = src.CauTrucGUID
				  AND cel.DonViId = src.DonViId
				  AND cel.KeHoachId = src.KeHoachId
				  AND (u.ExcelRow IS NULL OR cel.ExcelRow = u.ExcelRow)';
			IF @hasScopeGuid = 1
			  SET @sqlRow += N'
				LEFT JOIN #BMTH_RowScope_GUID g
					   ON g.DimId      = u.DimId
					  AND g.DonViId    = src.DonViId
					  AND g.KeHoachId  = src.KeHoachId
					  AND g.CauTrucGUID= src.CauTrucGUID';

			IF @hasScopeTC = 1
			  SET @sqlRow += N'
				LEFT JOIN #BMTH_RowScope_TieuChi t
					   ON t.DimId     = u.DimId
					  AND t.DonViId   = src.DonViId
					  AND t.KeHoachId = src.KeHoachId
					  AND t.TieuChiId = src.TieuChiId';

			IF @hasDimBind = 1
			  SET @sqlRow += N'
				LEFT JOIN #DimBind db
					   ON db.DimId = u.DimId
					  AND src.KKTKCN_Id = db.DimValueInt';

			SET @sqlRow += N'
				WHERE (u.ExcelRow IS NULL OR cel.CauTrucGUID IS NOT NULL)' +
				CASE WHEN @hasScopeGuid = 1 THEN N' AND g.DimId IS NOT NULL' ELSE N'' END +
				CASE WHEN @hasScopeTC   = 1 THEN N' AND t.DimId IS NOT NULL' ELSE N'' END +
				CASE WHEN @hasDimBind   = 1 THEN N' AND db.DimId IS NOT NULL' ELSE N'' END +
				N'
				AND (u.DistinctOn IS NULL)
				AND (u.TermFiltersJson IS NULL OR u.TermFiltersJson = N'''')' +
				N'
				GROUP BY u.DimId, u.OutCol, u.AggFn, u.Weight, u.Scale;';
			--SET @sqlRow += N' OPTION(RECOMPILE);';

			SET @sqlRow += N'
				/* ===== ROW path — collect per-term special into #U_Row ===== */
				INSERT INTO #U_Row(OutCol, AggFn, Weight, Scale, DimId, DonViId, KeHoachId, ExcelRow, TermFiltersJson, DistinctOn)
				SELECT u.OutCol, u.AggFn, u.Weight, u.Scale,
					   u.DimId, u.DonViId, u.KeHoachId, u.ExcelRow,
					   u.TermFiltersJson, u.DistinctOn
				FROM #UFE u
				WHERE (u.DistinctOn IS NOT NULL)
				   OR (u.TermFiltersJson IS NOT NULL AND u.TermFiltersJson<>N'''');

				DROP TABLE #UFE;';

			--EXEC dbo.SP_BCDT_PrintMax N'--DEBUG @sqlRow START';
			--EXEC dbo.SP_BCDT_PrintMax @sqlRow;
			--EXEC dbo.SP_BCDT_PrintMax N'--DEBUG @sqlRow END';

			BEGIN TRY
            EXEC sp_executesql
                  @sqlRow,
                  N'@alias SYSNAME,@NgayBatDauInt INT,@NgayKetThucInt INT,@KeHoachPickMode NVARCHAR(10),@bmId INT,@TrangThai INT',
                  @alias,@NgayBatDauInt,@NgayKetThucInt,@KeHoachPickMode,@bmId,@TrangThai;
			END TRY
			BEGIN CATCH
				DECLARE @Err NVARCHAR(4000) =
					N'SP_BCDT_BMTH_RenderNarrow @sqlRow error: ' + ERROR_MESSAGE()
					+ N'; Alias=' + ISNULL(@alias,N'NULL')
					+ N'; BieuMauId=' + CAST(ISNULL(@bmId,0) AS NVARCHAR(10));

				RAISERROR(@Err, 16, 1);
				RETURN;
			END CATCH;

			--select * from #U_Row;

			-- Thực thi các term đặc biệt của ROW path qua helper
			DECLARE curU CURSOR LOCAL FAST_FORWARD FOR
			  SELECT OutCol, AggFn, DimId, DonViId, KeHoachId, ExcelRow, Weight, Scale, TermFiltersJson, DistinctOn
			  FROM #U_Row;

			OPEN curU;
			DECLARE
			  @OutCol_r SYSNAME, @AggFn_r NVARCHAR(10),
			  @Dim_r INT, @DonVi_r INT, @KH_r INT, @ExcelRow_r INT,
			  @W_r DECIMAL(18,6), @S_r DECIMAL(18,6),
			  @Json_r NVARCHAR(MAX), @Distinct_r NVARCHAR(MAX);

			FETCH NEXT FROM curU INTO @OutCol_r,@AggFn_r,@Dim_r,@DonVi_r,@KH_r,@ExcelRow_r,@W_r,@S_r,@Json_r,@Distinct_r;
			WHILE @@FETCH_STATUS=0
			BEGIN
			  EXEC dbo.SP_BCDT_BMTH_ExecTerm
				   @Tbl=@tbl,
				   @IsRowPath=1,
				   @ValueCol=@valcol,
				   @DataCol=NULL,
				   @Dim=@Dim_r,
				   @OutCol=@OutCol_r,
				   @DonVi=@DonVi_r,
				   @KH=@KH_r,
				   @ExcelRow=@ExcelRow_r,
				   @AggFn=@AggFn_r,
				   @W=@W_r,
				   @S=@S_r,
				   @TermFiltersJson=@Json_r,
				   @DistinctOn=@Distinct_r;

			  FETCH NEXT FROM curU INTO @OutCol_r,@AggFn_r,@Dim_r,@DonVi_r,@KH_r,@ExcelRow_r,@W_r,@S_r,@Json_r,@Distinct_r;
			END
			CLOSE curU; DEALLOCATE curU;

			TRUNCATE TABLE #U_Row;  -- dọn sạch cho alias tiếp theo

        END

        /* 4.2) Term CÓ DataColumnName (đúng cột + có thể kết hợp lọc dòng) */
        DECLARE @col SYSNAME;
        DECLARE curC CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT DataColumnName FROM #Term WHERE Alias=@alias AND DataColumnName IS NOT NULL;
        OPEN curC; FETCH NEXT FROM curC INTO @col;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @sqlData = CAST(N'' AS NVARCHAR(MAX));
            SET @sqlData += N'
            ;WITH TermC AS (
              SELECT DISTINCT
                t.OutCol, t.DataColumnName, t.ExcelRow,
                t.AggFn, t.Weight, t.Scale, t.UnitScopeMode, t.UnitIdsJson,
                t.CriteriaCode, t.CriteriaScope, t.CriteriaIndex, t.CriteriaPickMode,
                t.BTieuChiScopeMode, t.BieuTieuChiIdsJson,
				t.TermFiltersJson, t.DistinctOn
              FROM #Term t
              WHERE t.Alias=@alias AND t.DataColumnName=@DataColumnName
            ),';
            SET @sqlData += N'
            U0 AS (
              SELECT tc.*, u.DimId, u.DonViId
              FROM TermC tc
              JOIN #UnitSet u ON 1=1
              WHERE (tc.UnitScopeMode IS NULL)
                 OR (tc.UnitScopeMode = N''ALL'')
                 OR (tc.UnitScopeMode = N''LIST''    AND ISJSON(tc.UnitIdsJson)=1 AND EXISTS (SELECT 1 FROM OPENJSON(tc.UnitIdsJson) j WHERE TRY_CONVERT(INT,j.value)=u.DonViId))
                 OR (tc.UnitScopeMode = N''EXCLUDE'' AND (ISJSON(tc.UnitIdsJson)<>1 OR NOT EXISTS (SELECT 1 FROM OPENJSON(tc.UnitIdsJson) j WHERE TRY_CONVERT(INT,j.value)=u.DonViId)))
            ),';
			SET @sqlData += N'
			KH_TH AS (
			  SELECT th.KeHoachId
			  FROM dbo.BCDT_KeHoach_TongHop th
			  WHERE th.BieuMauId = @bmId
				AND th.TrangThai = @TrangThai
			),';
            SET @sqlData += N'
			KH AS (
			  SELECT DISTINCT c.DonViId, c.Id AS KeHoachId
			  FROM dbo.BCDT_KeHoach c
			  JOIN dbo.BCDT_KeHoach_Dot d ON c.DotId=d.Id AND d.BitDaXoa=0
			  JOIN KH_TH th ON th.KeHoachId = c.Id
			  WHERE c.BitDaXoa=0
				AND d.NgayBatDauInt = @NgayBatDauInt
				AND d.NgayKetThucInt = @NgayKetThucInt
				AND @KeHoachPickMode=N''SUM''
			  UNION ALL
			  SELECT DISTINCT pk.DonViId, pk.KeHoachId
			  FROM #PickKH pk
			  JOIN KH_TH th ON th.KeHoachId = pk.KeHoachId
			  WHERE @KeHoachPickMode=N''LATEST''
			),';
            SET @sqlData += N'
            U1 AS (
              SELECT
                u.OutCol, u.DataColumnName, u.AggFn, u.Weight, u.Scale, u.UnitScopeMode, u.UnitIdsJson,
                u.DimId, u.DonViId, u.CriteriaPickMode,
                u.CriteriaCode, u.CriteriaScope, u.ExcelRow, u.CriteriaIndex,
                CASE WHEN u.CriteriaScope LIKE N''BY_PARENT_CODE:%'' THEN N''BY_PARENT_CODE''
                     ELSE COALESCE(NULLIF(u.CriteriaScope,N''''),N''SAME_PARENT'') END AS ScopeClean,
                CASE WHEN u.CriteriaScope LIKE N''BY_PARENT_CODE:%''
                     THEN SUBSTRING(u.CriteriaScope, LEN(N''BY_PARENT_CODE:'')+1, 4000) ELSE NULL END AS ParentCodeInToken,
                u.BTieuChiScopeMode, u.BieuTieuChiIdsJson,
				u.TermFiltersJson, u.DistinctOn
              FROM U0 u
            ),';
            SET @sqlData += N'
            UFilter AS (
              SELECT
                u1.OutCol, u1.DataColumnName, u1.AggFn, u1.Weight, u1.Scale,
                u1.DimId, u1.DonViId, u1.CriteriaPickMode,
                k.KeHoachId,
                CASE
                  WHEN u1.BTieuChiScopeMode IS NOT NULL THEN u1.ExcelRow
                  WHEN u1.CriteriaCode IS NULL THEN u1.ExcelRow
                  WHEN u1.CriteriaPickMode = N''INDEX'' THEN
                    dbo.fn_BCDT_ResolveTieuChiRow_ByIndex(
                      @bmId, u1.DonViId, k.KeHoachId, u1.CriteriaCode,
                      NULL, COALESCE(NULLIF(u1.ScopeClean,N''''),N''SAME_PARENT''),
                      COALESCE(NULLIF(u1.CriteriaIndex,0),1), u1.ParentCodeInToken
                    )
                  ELSE NULL
                END AS ExcelRow,
                u1.CriteriaCode, u1.CriteriaScope,
                u1.BTieuChiScopeMode, u1.BieuTieuChiIdsJson,
				u1.TermFiltersJson, u1.DistinctOn
              FROM U1 u1
              JOIN KH k ON k.DonViId = u1.DonViId
            ),';
            SET @sqlData += N'
            Cel AS (
              SELECT DISTINCT CauTrucGUID, DonViId, KeHoachId, ExcelRow
              FROM dbo.BCDT_CauTruc_BieuMau_ViTriExcel
              WHERE BieuMauId = ';
            SET @sqlData += CAST(@bmId AS NVARCHAR(20));
            SET @sqlData += N'
            ),';
            SET @sqlData += N'
            CelCrit AS (
              SELECT DISTINCT vt.DonViId, vt.KeHoachId, vt.ExcelRow, uf.OutCol, uf.CriteriaCode,
                     COALESCE(uf.CriteriaScope,N''ANY'') AS CriteriaScope, uf.CriteriaPickMode
              FROM UFilter uf
              JOIN KH k ON k.DonViId=uf.DonViId
              JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel vt
                ON vt.BieuMauId = ';
            SET @sqlData += CAST(@bmId AS NVARCHAR(20));
            SET @sqlData += N'
               AND vt.DonViId=k.DonViId AND vt.KeHoachId=k.KeHoachId
              JOIN dbo.BCDT_CauTruc_BieuMau tc ON tc.CauTrucGUID=vt.CauTrucGUID
              WHERE uf.CriteriaPickMode=N''ALL'' AND uf.CriteriaCode IS NOT NULL
                AND COALESCE(uf.CriteriaScope,N''ANY'') IN (N''ANY'', N'''')
                AND tc.MaTieuChi=uf.CriteriaCode
            ),';
            SET @sqlData += N'
            CelCritBTC AS (
              SELECT DISTINCT vt.DonViId, vt.KeHoachId, vt.ExcelRow, uf.OutCol
              FROM UFilter uf
              JOIN KH k ON k.DonViId=uf.DonViId
              JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel vt
                ON vt.BieuMauId = ';
            SET @sqlData += CAST(@bmId AS NVARCHAR(20));
            SET @sqlData += N'
               AND vt.DonViId=k.DonViId AND vt.KeHoachId=k.KeHoachId
              JOIN dbo.BCDT_CauTruc_BieuMau tc ON tc.CauTrucGUID=vt.CauTrucGUID
              WHERE uf.BTieuChiScopeMode IS NOT NULL
                AND (
                     UPPER(uf.BTieuChiScopeMode)=N''ALL''
                  OR (ISJSON(uf.BieuTieuChiIdsJson)=1 AND
                       ((UPPER(uf.BTieuChiScopeMode)=N''LIST''    AND EXISTS (SELECT 1 FROM OPENJSON(uf.BieuTieuChiIdsJson) j WHERE TRY_CONVERT(INT,j.value)=tc.BieuTieuChiId))
                     OR (UPPER(uf.BTieuChiScopeMode)=N''EXCLUDE'' AND NOT EXISTS (SELECT 1 FROM OPENJSON(uf.BieuTieuChiIdsJson) j WHERE TRY_CONVERT(INT,j.value)=tc.BieuTieuChiId))
                       )
                   )
                )
			)';
            SET @sqlData += N'
            ,UFilterExp AS (
              SELECT u.OutCol,u.DataColumnName,u.AggFn,u.Weight,u.Scale,u.DimId,u.DonViId,
                     COALESCE(u.ExcelRow, cc.ExcelRow, cb.ExcelRow) AS ExcelRow,
                     COALESCE(u.KeHoachId, cc.KeHoachId, cb.KeHoachId) AS KeHoachId,
					 u.TermFiltersJson,u.DistinctOn
              FROM UFilter u
              LEFT JOIN CelCrit cc
                     ON u.BTieuChiScopeMode IS NULL
                    AND u.CriteriaPickMode = N''ALL''
                    AND cc.OutCol       = u.OutCol
                    AND cc.DonViId      = u.DonViId
                    AND cc.CriteriaCode = u.CriteriaCode
                    AND cc.CriteriaScope= COALESCE(u.CriteriaScope,N''ANY'')
                    AND cc.KeHoachId    = u.KeHoachId
              LEFT JOIN CelCritBTC cb
                     ON u.BTieuChiScopeMode IS NOT NULL
                    AND cb.OutCol   = u.OutCol
                    AND cb.DonViId  = u.DonViId
                    AND cb.KeHoachId= u.KeHoachId
              WHERE
                (
                  u.BTieuChiScopeMode IS NULL AND
                  (
                    (u.CriteriaCode IS NOT NULL AND (
                       (u.CriteriaPickMode = N''INDEX'' AND u.ExcelRow IS NOT NULL) OR
                       (u.CriteriaPickMode = N''ALL''   AND cc.ExcelRow IS NOT NULL)
                    ))
                    OR (u.CriteriaCode IS NULL)
                  )
                )
                OR
                (
                  u.BTieuChiScopeMode IS NOT NULL
                  AND (u.ExcelRow IS NOT NULL OR cb.ExcelRow IS NOT NULL)
                )
            )';
			SET @sqlData += N'			
			 SELECT 
			   OutCol, DataColumnName, AggFn, Weight, Scale, DimId, DonViId, ExcelRow, KeHoachId, TermFiltersJson, DistinctOn
			 INTO #UFE
			 FROM UFilterExp;';

            SET @sqlData += N'
            INSERT INTO #Base(DimId,OutCol,Val)
            SELECT
              u.DimId,
              u.OutCol,
              (CASE u.AggFn
					 WHEN N''AVG''   THEN AVG(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6),src.' + QUOTENAME(@col) + N'), 0),0.0))
					 WHEN N''MIN''   THEN MIN(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@col) + N'), 0),0.0))
					 WHEN N''MAX''   THEN MAX(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@col) + N'), 0),0.0))
					 WHEN N''COUNT'' THEN COUNT(1)
					 ELSE SUM(COALESCE(NULLIF(TRY_CONVERT(DECIMAL(38,6), src.' + QUOTENAME(@col) + N'), 0),0.0))
			   END) * u.Weight * u.Scale
            FROM #UFE u
            LEFT JOIN dbo.' + QUOTENAME(@tbl) + N' src
                   ON src.DonViId=u.DonViId AND src.KeHoachId=u.KeHoachId AND src.BitDaXoa=0
            LEFT JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel cel
                   ON cel.CauTrucGUID=src.CauTrucGUID AND cel.DonViId=src.DonViId AND cel.KeHoachId=src.KeHoachId
                  AND (u.ExcelRow IS NULL OR cel.ExcelRow=u.ExcelRow)';
			IF @hasScopeGuid = 1
			  SET @sqlData += N'
				LEFT JOIN #BMTH_RowScope_GUID g
					   ON g.DimId      = u.DimId
					  AND g.DonViId    = src.DonViId
					  AND g.KeHoachId  = src.KeHoachId
					  AND g.CauTrucGUID= src.CauTrucGUID';

			IF @hasScopeTC = 1
			  SET @sqlData += N'
				LEFT JOIN #BMTH_RowScope_TieuChi t
					   ON t.DimId     = u.DimId
					  AND t.DonViId   = src.DonViId
					  AND t.KeHoachId = src.KeHoachId
					  AND t.TieuChiId = src.TieuChiId';

			IF @hasDimBind = 1
			  SET @sqlData += N'
				LEFT JOIN #DimBind db
					   ON db.DimId = u.DimId
					  AND src.KKTKCN_Id = db.DimValueInt';

            SET @sqlData += N'
				WHERE (u.ExcelRow IS NULL OR cel.CauTrucGUID IS NOT NULL)' +
				CASE WHEN @hasScopeGuid = 1 THEN N' AND g.DimId IS NOT NULL' ELSE N'' END +
				CASE WHEN @hasScopeTC   = 1 THEN N' AND t.DimId IS NOT NULL' ELSE N'' END +
				CASE WHEN @hasDimBind   = 1 THEN N' AND db.DimId IS NOT NULL' ELSE N'' END +
				N'
				AND (u.DistinctOn IS NULL)
				AND (u.TermFiltersJson IS NULL OR u.TermFiltersJson = N'''')' +
				N'
				GROUP BY u.DimId, u.OutCol, u.AggFn, u.Weight, u.Scale;';
			--SET @sqlRow += N' OPTION(RECOMPILE);';

			SET @sqlData += N'
				/* ===== DATA path — collect per-term special into #U_Data ===== */
				INSERT INTO #U_Data(OutCol, DataColumnName, AggFn, Weight, Scale, DimId, DonViId, KeHoachId, ExcelRow, TermFiltersJson, DistinctOn)
				SELECT u.OutCol, u.DataColumnName, u.AggFn, u.Weight, u.Scale,
					   u.DimId, u.DonViId, u.KeHoachId, u.ExcelRow,
					   u.TermFiltersJson, u.DistinctOn
				FROM #UFE u
				WHERE (u.DistinctOn IS NOT NULL)
				   OR (u.TermFiltersJson IS NOT NULL AND u.TermFiltersJson<>N'''');
				DROP TABLE #UFE;';

			--IF(@alias = 'BM4')
			--BEGIN
			--	EXEC dbo.SP_BCDT_PrintMax N'--DEBUG @sqlData START';
			--	EXEC dbo.SP_BCDT_PrintMax @sqlData ;
			--	EXEC dbo.SP_BCDT_PrintMax N'--DEBUG @sqlData END' ;
			--END

			BEGIN TRY
            EXEC sp_executesql @sqlData,
                  N'@alias SYSNAME,@DataColumnName SYSNAME,@NgayBatDauInt INT,@NgayKetThucInt INT,@KeHoachPickMode NVARCHAR(10),@bmId INT,@TrangThai INT',
                  @alias,@col,@NgayBatDauInt,@NgayKetThucInt,@KeHoachPickMode,@bmId,@TrangThai;
			END TRY
			BEGIN CATCH
				DECLARE @Err2 NVARCHAR(4000) =
					N'SP_BCDT_BMTH_RenderNarrow @sqlData error: ' + ERROR_MESSAGE()
					+ N'; Alias=' + ISNULL(@alias,N'NULL')
					+ N'; BieuMauId=' + CAST(ISNULL(@bmId,0) AS NVARCHAR(10))
					+ N'; COl=' + ISNULL(@col,N'NULL')
				RAISERROR(@Err2, 16, 1);
				RETURN;
			END CATCH;			

			--select * from #U_Data;

			-- Thực thi các term đặc biệt của DATA path qua helper
			DECLARE curU2 CURSOR LOCAL FAST_FORWARD FOR
			  SELECT OutCol, DataColumnName, AggFn, DimId, DonViId, KeHoachId, ExcelRow, Weight, Scale, TermFiltersJson, DistinctOn
			  FROM #U_Data;

			OPEN curU2;
			DECLARE
			  @OutCol_d SYSNAME, @DataCol_d SYSNAME, @AggFn_d NVARCHAR(10),
			  @Dim_d INT, @DonVi_d INT, @KH_d INT, @ExcelRow_d INT,
			  @W_d DECIMAL(18,6), @S_d DECIMAL(18,6),
			  @Json_d NVARCHAR(MAX), @Distinct_d NVARCHAR(MAX);

			FETCH NEXT FROM curU2 INTO @OutCol_d,@DataCol_d,@AggFn_d,@Dim_d,@DonVi_d,@KH_d,@ExcelRow_d,@W_d,@S_d,@Json_d,@Distinct_d;
			WHILE @@FETCH_STATUS=0
			BEGIN
			  EXEC dbo.SP_BCDT_BMTH_ExecTerm
				   @Tbl=@tbl,
				   @IsRowPath=0,
				   @ValueCol=NULL,
				   @DataCol=@DataCol_d,
				   @Dim=@Dim_d,
				   @OutCol=@OutCol_d,
				   @DonVi=@DonVi_d,
				   @KH=@KH_d,
				   @ExcelRow=@ExcelRow_d,
				   @AggFn=@AggFn_d,
				   @W=@W_d,
				   @S=@S_d,
				   @TermFiltersJson=@Json_d,
				   @DistinctOn=@Distinct_d;

			  FETCH NEXT FROM curU2 INTO @OutCol_d,@DataCol_d,@AggFn_d,@Dim_d,@DonVi_d,@KH_d,@ExcelRow_d,@W_d,@S_d,@Json_d,@Distinct_d;
			END
			CLOSE curU2; DEALLOCATE curU2;

			TRUNCATE TABLE #U_Data; -- dọn sạch cho DataColumn kế tiếp


            FETCH NEXT FROM curC INTO @col;
        END
        CLOSE curC; DEALLOCATE curC;

        FETCH NEXT FROM curA INTO @alias,@bmId,@tbl,@valcol;
    END
    CLOSE curA; DEALLOCATE curA;

	CREATE INDEX IX_Base_OutCol_Dim
		ON #Base(OutCol, DimId) INCLUDE(Val);

    -- 5) Agg narrow
    IF OBJECT_ID('tempdb..#Agg_Narrow') IS NULL
        CREATE TABLE #Agg_Narrow(DimId INT, OutCol SYSNAME, SumVal DECIMAL(38,6));
    ELSE
        TRUNCATE TABLE #Agg_Narrow;

	--select * from #Base

    INSERT INTO #Agg_Narrow
    SELECT DimId, OutCol, SUM(COALESCE(Val,0))
    FROM #Base
    GROUP BY DimId, OutCol;

    -- 6) Danh sách VALUE cols
    IF OBJECT_ID('tempdb..#ValueCols') IS NULL
        CREATE TABLE #ValueCols(Col SYSNAME PRIMARY KEY);
    ELSE
        TRUNCATE TABLE #ValueCols;

    INSERT INTO #ValueCols
    SELECT DISTINCT OutCol FROM #Map WHERE UPPER(RenderMode)=N'VALUE';

    -- 6b) ExprBuilt
    IF OBJECT_ID('tempdb..#ExprBuilt') IS NULL
        CREATE TABLE #ExprBuilt(ExcelCol SYSNAME PRIMARY KEY, ExprSql NVARCHAR(MAX));
    ELSE
        TRUNCATE TABLE #ExprBuilt;

    DECLARE @outColExpr SYSNAME, @exprIn NVARCHAR(MAX), @exprOut NVARCHAR(MAX);
    DECLARE @i INT, @len INT, @ch NCHAR(1), @j INT, @tok NVARCHAR(128);

    DECLARE curE CURSOR LOCAL FAST_FORWARD FOR
        SELECT ExcelCol, ExprText
        FROM dbo.BCDT_BMTH_ColumnExpr
        WHERE TongHopBieuMauId=@TongHopBieuMauId AND IsActive=1
        ORDER BY ExcelCol;
    OPEN curE; FETCH NEXT FROM curE INTO @outColExpr,@exprIn;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @exprOut = N'';
        SET @i = 1; SET @len = LEN(@exprIn);
        WHILE @i <= @len
        BEGIN
            SET @ch = SUBSTRING(@exprIn,@i,1);
            IF (@ch LIKE N'[A-Za-z_]')
            BEGIN
                SET @j = @i;
                WHILE @j <= @len AND SUBSTRING(@exprIn,@j,1) LIKE N'[A-Za-z0-9_]'
                    SET @j = @j + 1;
                SET @tok = SUBSTRING(@exprIn,@i,@j-@i);
                IF EXISTS (SELECT 1 FROM #ValueCols WHERE Col=@tok)
                    SET @exprOut = @exprOut + N'COALESCE(['+@tok+N'],0)';
                ELSE
                    SET @exprOut = @exprOut + @tok;
                SET @i = @j; CONTINUE;
            END
            ELSE
            BEGIN
                SET @exprOut = @exprOut + @ch;
                SET @i = @i + 1;
            END
        END

		PRINT @exprOut
		-- Chống chia cho 0; để NULL khi mẫu số = 0
		SET @exprOut = dbo.fn_BCDT_ProtectDivideByZero(@exprOut, 1);
		PRINT @exprOut
        INSERT INTO #ExprBuilt(ExcelCol,ExprSql) VALUES (@outColExpr, @exprOut);
        IF NOT EXISTS (SELECT 1 FROM #ValueCols WHERE Col=@outColExpr)
            INSERT INTO #ValueCols(Col) VALUES (@outColExpr);
        FETCH NEXT FROM curE INTO @outColExpr,@exprIn;
    END
	
    CLOSE curE; DEALLOCATE curE;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_BMTH_Theo_KhuKinhTe]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================================
-- STORED PROCEDURE: dbo.SP_BCDT_BMTH_Theo_KhuKinhTe
-- Phiên bản : 1.0 (2025-11-03)
-- Mục đích  : Wrapper tổng hợp BMTH theo Khu kinh tế/KKT (Dim = KKT),
--             tái sử dụng engine dbo.SP_BCDT_BMTH_RenderNarrow.
--
-- Dim      : KKT xác định duy nhất theo BCDT_TieuChi_KKTKCN.Id
-- Hiển thị : TenKKTKCN
-- Ràng buộc: BitDaXoa = 0, TrangThai = 1
-- Map DonVi: qua BCDT_DanhMuc_TieuChi (TieuChiId -> DonViId)
-- Row-scope: #BMTH_RowScope_TieuChi(DimId,DonViId,KeHoachId,TieuChiId)
--
-- Tham số :
--   @TongHopBieuMauId : cấu hình BMTH (map cột, terms)
--   @NgayBatDauInt, @NgayKetThucInt : kỳ tính
--   @KKTScope         : ALL | LIST | EXCLUDE (lọc theo KKT.Id)
--   @KKTIdsJson       : JSON array các Id KKT (khi LIST/EXCLUDE)
--   @DonViScope       : ALL | LIST | EXCLUDE (lọc theo DonViId)
--   @DonViIdsJson     : JSON array các DonViId (khi LIST/EXCLUDE)
--   @KeHoachPickMode  : SUM | LATEST
--   @LoaiHinh         : NULL | KKTvb | KKTck
--   @Loai             : 0: ALL | 1: KKT | 2: KPTQ | 3: KCN
--   @UseColC_Province : 1: cột C = Tên tỉnh của KKT; 0: giữ nguyên như hiện tại
--
-- Đầu ra : Bảng kết quả A (STT), B (Tên KKT), các cột VALUE (pivot) + EXPR
-- Ghi chú: OPTION(RECOMPILE) ở khối pivot và SELECT cuối.
CREATE     PROCEDURE [dbo].[SP_BCDT_BMTH_Theo_KhuKinhTe]
(
    @TongHopBieuMauId INT,
    @NgayBatDauInt    INT,
    @NgayKetThucInt   INT,
    @KKTScope         NVARCHAR(10) = N'ALL',    -- ALL | LIST | EXCLUDE
    @KKTIdsJson       NVARCHAR(MAX) = NULL,
    @DonViScope       NVARCHAR(10) = N'ALL',    -- ALL | LIST | EXCLUDE
    @DonViIdsJson     NVARCHAR(MAX) = NULL,
    @KeHoachPickMode  NVARCHAR(10) = N'SUM',    -- SUM | LATEST
    @LoaiHinh         NVARCHAR(100) = NULL,     -- NULL | KKTvb | KKTck
	@Loai             INT = 0,                  -- 0: ALL | 1: KKT | 2: KPTQ | 3: KCN
	@UseColC_Province BIT = 0					-- 1: cột C = Tên tỉnh của KKT; 0: giữ nguyên như hiện tại

)
AS
BEGIN
    SET NOCOUNT ON;
	--Trang thai da tiep nhan cua cuc dtnn
	DECLARE @TrangThai INT = 1007;
	/* Preload JSON to temp tables to avoid repeated OPENJSON scans */
	IF OBJECT_ID('tempdb..#KKT_IDS') IS NOT NULL DROP TABLE #KKT_IDS;
	CREATE TABLE #KKT_IDS (Id INT PRIMARY KEY);  -- empty by default
	IF @KKTScope IN (N'LIST', N'EXCLUDE') AND ISJSON(@KKTIdsJson)=1
		INSERT INTO #KKT_IDS(Id)
		SELECT TRY_CONVERT(INT, value) FROM OPENJSON(@KKTIdsJson);

	IF OBJECT_ID('tempdb..#DV_IDS') IS NOT NULL DROP TABLE #DV_IDS;
	CREATE TABLE #DV_IDS (DonViId INT PRIMARY KEY);  -- empty by default
	IF @DonViScope IN (N'LIST', N'EXCLUDE') AND ISJSON(@DonViIdsJson)=1
		INSERT INTO #DV_IDS(DonViId)
		SELECT TRY_CONVERT(INT, value) FROM OPENJSON(@DonViIdsJson);

    /* ---------- A) Danh mục KKT (Dim) ---------- */
    IF OBJECT_ID('tempdb..#KKT') IS NOT NULL DROP TABLE #KKT;
    CREATE TABLE #KKT
    (
        DimId     INT IDENTITY(1,1) PRIMARY KEY,
        KKTId     INT NOT NULL,
        TenKKTKCN NVARCHAR(2000) NULL,
		DiaChi_Tinh NVARCHAR(50) NULL
    );

    INSERT INTO #KKT(KKTId, TenKKTKCN, DiaChi_Tinh)
	SELECT k.Id,
		   MAX(NULLIF(LTRIM(RTRIM(k.TenKKTKCN)), N'')) AS TenKKTKCN,
		   MAX(NULLIF(LTRIM(RTRIM(k.DiaChi_Tinh)), N'')) AS DiaChi_Tinh
	FROM dbo.BCDT_TieuChi_KKTKCN k
	WHERE k.BitDaXoa = 0
	  AND k.TrangThai = 1
	  AND (@Loai = 0 OR k.Loai = @Loai)
	  AND (@LoaiHinh IS NULL OR k.LoaiHinhId = @LoaiHinh)
	  AND (
			@KKTScope = N'ALL'
		 OR (@KKTScope = N'LIST'    AND EXISTS (SELECT 1 FROM #KKT_IDS j WHERE j.Id = k.Id))
		 OR (@KKTScope = N'EXCLUDE' AND NOT EXISTS (SELECT 1 FROM #KKT_IDS j WHERE j.Id = k.Id))
		  )
	GROUP BY k.Id;

	-- Tăng tốc tra cứu theo KKTId và join sang DM hành chính
	CREATE NONCLUSTERED INDEX IX_KKT_KKTId 
	ON #KKT(KKTId) 
	INCLUDE (DimId, TenKKTKCN, DiaChi_Tinh);

	-- Khi dùng cột C = tỉnh: tối ưu join theo DiaChi_Tinh
	IF (@UseColC_Province = 1)
		CREATE NONCLUSTERED INDEX IX_KKT_DiaChiTinh 
		ON #KKT(DiaChi_Tinh) 
		INCLUDE (DimId);

    IF NOT EXISTS (SELECT 1 FROM #KKT)
    BEGIN
        -- Trả ra schema rỗng đúng định dạng
        SELECT CAST(NULL AS INT) AS [A], CAST(NULL AS NVARCHAR(2000)) AS [B] WHERE 1=0;
        RETURN;
    END

	-- Sau khi tạo #KKT
	IF OBJECT_ID('tempdb..#DimBind') IS NOT NULL DROP TABLE #DimBind;
	CREATE TABLE #DimBind(DimId INT PRIMARY KEY, DimValueInt INT NOT NULL);

	INSERT INTO #DimBind(DimId, DimValueInt)
	SELECT DimId, KKTId
	FROM #KKT;


    /* ---------- B) Khóa kế hoạch theo mode + áp DonViScope ---------- */
    IF OBJECT_ID('tempdb..#KH_PICK') IS NOT NULL DROP TABLE #KH_PICK;
    ;WITH KH AS
    (
        SELECT k.Id AS KeHoachId, k.DonViId, d.NgayKetThucInt
        FROM dbo.BCDT_KeHoach k
        JOIN dbo.BCDT_KeHoach_Dot d ON d.Id = k.DotId AND d.BitDaXoa = 0
        WHERE k.BitDaXoa = 0
          AND d.NgayBatDauInt = @NgayBatDauInt
          AND d.NgayKetThucInt = @NgayKetThucInt
    )
    SELECT DonViId, KeHoachId
    INTO #KH_PICK
    FROM KH
    WHERE @KeHoachPickMode = N'SUM'
    UNION ALL
    SELECT x.DonViId, x.Id
    FROM (
        SELECT k.DonViId, k.Id,
               ROW_NUMBER() OVER (PARTITION BY k.DonViId
                                  ORDER BY d.NgayKetThucInt DESC, k.Id DESC) AS rn
        FROM dbo.BCDT_KeHoach k
        JOIN dbo.BCDT_KeHoach_Dot d ON d.Id = k.DotId AND d.BitDaXoa = 0
        WHERE k.BitDaXoa = 0
          AND d.NgayBatDauInt = @NgayBatDauInt
          AND d.NgayKetThucInt = @NgayKetThucInt
          AND @KeHoachPickMode = N'LATEST'
    ) x
    WHERE x.rn = 1;

	-- Tăng tốc join trên DonViId/KeHoachId cho các bước sau
	CREATE CLUSTERED INDEX IX_KH_PICK_DonVi_KeHoach 
	ON #KH_PICK(DonViId, KeHoachId);

    -- Áp lọc đơn vị (nếu có)
	IF @DonViScope = N'LIST'
		DELETE p FROM #KH_PICK p
		WHERE NOT EXISTS (SELECT 1 FROM #DV_IDS d WHERE d.DonViId = p.DonViId);

	IF @DonViScope = N'EXCLUDE'
		DELETE p FROM #KH_PICK p
		WHERE EXISTS (SELECT 1 FROM #DV_IDS d WHERE d.DonViId = p.DonViId);

    /* ---------- C) Bảng nguồn dùng trong cấu hình (Alias -> TableName) ---------- */
    IF OBJECT_ID('tempdb..#AliasTbl') IS NOT NULL DROP TABLE #AliasTbl;
    CREATE TABLE #AliasTbl(Alias SYSNAME, TableName SYSNAME, BieuMauId INT);

    INSERT INTO #AliasTbl(Alias, TableName, BieuMauId)
	SELECT DISTINCT t.Alias, a.TableName, a.BieuMauId
	FROM dbo.BCDT_BMTH_ColumnMap_Term t
	JOIN dbo.BCDT_BMTH_ColumnMap m
	  ON m.Id = t.MapId AND m.TongHopBieuMauId = @TongHopBieuMauId AND m.IsActive = 1
	JOIN dbo.BCDT_BMTH_BieuNguon_Alias a
	  ON a.Alias = t.Alias AND a.IsActive = 1;

    /* ---------- D) Xây UnitSet_All và RowScope_All theo dữ liệu thật (map KKTKCN_Id) ---------- */
    IF OBJECT_ID('tempdb..#UnitSet_All') IS NOT NULL DROP TABLE #UnitSet_All;
    CREATE TABLE #UnitSet_All
    (
        DimId   INT NOT NULL,
        DonViId INT NOT NULL,
        CONSTRAINT PK_UnitSet_All PRIMARY KEY (DimId, DonViId)
    );

    IF OBJECT_ID('tempdb..#RowScope_All') IS NOT NULL DROP TABLE #RowScope_All;
	CREATE TABLE #RowScope_All
	(
	  DimId     INT NOT NULL,
	  DonViId   INT NOT NULL,
	  KeHoachId INT NOT NULL,
	  TieuChiId INT NOT NULL,
	  BieuMauId INT NOT NULL,
	  TenTieuChi NVARCHAR(2000) NULL,
	  CONSTRAINT PK_RowScope_All PRIMARY KEY (DimId, DonViId, KeHoachId, TieuChiId, BieuMauId)
	);

    DECLARE @alias SYSNAME, @srcTable SYSNAME, @bmId INT, @sql NVARCHAR(MAX);

	DECLARE curSrc CURSOR LOCAL FAST_FORWARD FOR
		SELECT Alias, TableName, BieuMauId FROM #AliasTbl;

	OPEN curSrc; FETCH NEXT FROM curSrc INTO @alias, @srcTable, @bmId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Đơn vị có data của KKT trong kỳ
        SET @sql = N'
			INSERT INTO #UnitSet_All(DimId, DonViId)
			SELECT DISTINCT kk.DimId, s.DonViId
			FROM #KKT kk
			JOIN ' + QUOTENAME(@srcTable) + N' s
			  ON s.BitDaXoa = 0
			 AND s.KKTKCN_Id = kk.KKTId
			JOIN #KH_PICK kh
			  ON kh.DonViId  = s.DonViId
			 AND kh.KeHoachId = s.KeHoachId
			JOIN dbo.BCDT_KeHoach_TongHop th
			  ON th.KeHoachId = s.KeHoachId
			 AND th.BieuMauId = @bmId
			 AND th.TrangThai = @TrangThai
			WHERE NOT EXISTS (
			  SELECT 1 FROM #UnitSet_All u
			  WHERE u.DimId = kk.DimId AND u.DonViId = s.DonViId
			);';
		EXEC sp_executesql @sql, N'@bmId INT,@TrangThai INT', @bmId, @TrangThai;

        -- Row-scope tiêu chí theo KKT
		SET @sql = N'
			INSERT INTO #RowScope_All(DimId, DonViId, KeHoachId, TieuChiId, BieuMauId, TenTieuChi)
			SELECT DISTINCT kk.DimId, s.DonViId, s.KeHoachId, s.TieuChiId, @bmId, kk.TenKKTKCN
			FROM #KKT kk
			JOIN ' + QUOTENAME(@srcTable) + N' s
			  ON s.BitDaXoa = 0
			 AND s.KKTKCN_Id = kk.KKTId
			JOIN #KH_PICK kh
			  ON kh.DonViId  = s.DonViId
			 AND kh.KeHoachId = s.KeHoachId
			JOIN dbo.BCDT_KeHoach_TongHop th
			  ON th.KeHoachId = s.KeHoachId
			 AND th.BieuMauId = @bmId
			 AND th.TrangThai = @TrangThai
			WHERE NOT EXISTS (
			  SELECT 1 FROM #RowScope_All r
			  WHERE r.DimId     = kk.DimId
				AND r.DonViId   = s.DonViId
				AND r.KeHoachId = s.KeHoachId
				AND r.TieuChiId = s.TieuChiId
				AND r.BieuMauId = @bmId
			);';
		EXEC sp_executesql @sql, N'@bmId INT,@TrangThai INT', @bmId, @TrangThai;


        FETCH NEXT FROM curSrc INTO @alias, @srcTable, @bmId;
    END
    CLOSE curSrc; DEALLOCATE curSrc;

	IF OBJECT_ID('tempdb..#KKT_NameKH') IS NOT NULL DROP TABLE #KKT_NameKH;
	;WITH x AS (
	  SELECT rs.DimId, ISNULL(rs.TenTieuChi, ct.TenTieuChi) as TenTieuChi, rs.KeHoachId,
			 ROW_NUMBER() OVER (PARTITION BY rs.DimId ORDER BY rs.KeHoachId DESC) rn
	  FROM #RowScope_All rs
	  JOIN dbo.BCDT_CauTruc_BieuMau ct
		ON ct.BitDaXoa = 0
	   AND ct.KeHoachId = rs.KeHoachId
	   AND ct.TieuChiId = rs.TieuChiId
	   AND ct.BieuMauId = rs.BieuMauId
	)
	SELECT DimId, MAX(NULLIF(LTRIM(RTRIM(TenTieuChi)), N'')) AS TenTheoKeHoach
	INTO #KKT_NameKH
	FROM x
	WHERE rn = 1
	GROUP BY DimId;

	CREATE UNIQUE CLUSTERED INDEX IX_KKT_NameKH_DimId ON #KKT_NameKH(DimId);

    /* ---------- E') Chuẩn bị #UnitSet & #BMTH_RowScope_TieuChi cho TẤT CẢ Dim ---------- */
	IF OBJECT_ID('tempdb..#UnitSet') IS NOT NULL DROP TABLE #UnitSet;
	CREATE TABLE #UnitSet(
	  DimId   INT NOT NULL,
	  DonViId INT NOT NULL,
	  CONSTRAINT PK_UnitSet PRIMARY KEY (DimId, DonViId)
	);
	INSERT INTO #UnitSet(DimId, DonViId)
	SELECT DimId, DonViId
	FROM #UnitSet_All;

	IF OBJECT_ID('tempdb..#BMTH_RowScope_TieuChi') IS NOT NULL DROP TABLE #BMTH_RowScope_TieuChi;
	CREATE TABLE #BMTH_RowScope_TieuChi
	(
	  DimId     INT NOT NULL,
	  DonViId   INT NOT NULL,
	  KeHoachId INT NOT NULL,
	  TieuChiId INT NOT NULL,
	  CONSTRAINT PK_RowScope PRIMARY KEY (DimId, DonViId, KeHoachId, TieuChiId)
	);
	INSERT INTO #BMTH_RowScope_TieuChi(DimId, DonViId, KeHoachId, TieuChiId)
	SELECT DimId, DonViId, KeHoachId, TieuChiId
	FROM #RowScope_All;

	/* (khuyến nghị) index phụ lookup theo TieuChiId khi RenderNarrow join */
	CREATE NONCLUSTERED INDEX IX_RowScope_TieuChi_T
	ON #BMTH_RowScope_TieuChi(TieuChiId)
	INCLUDE(DimId, DonViId, KeHoachId);

	/* BẢO ĐẢM #temp engine tồn tại dù RenderNarrow có RAISERROR/RETURN sớm */
	IF OBJECT_ID('tempdb..#Agg_Narrow') IS NULL
		CREATE TABLE #Agg_Narrow (DimId INT, OutCol SYSNAME, SumVal DECIMAL(38,6));
	ELSE
		TRUNCATE TABLE #Agg_Narrow;

	IF OBJECT_ID('tempdb..#ValueCols') IS NULL
		CREATE TABLE #ValueCols (Col SYSNAME PRIMARY KEY);
	ELSE
		TRUNCATE TABLE #ValueCols;

	IF OBJECT_ID('tempdb..#ExprBuilt') IS NULL
		CREATE TABLE #ExprBuilt (ExcelCol SYSNAME PRIMARY KEY, ExprSql NVARCHAR(MAX));
	ELSE
		TRUNCATE TABLE #ExprBuilt;

	/* Engine sẽ đọc #UnitSet, #BMTH_RowScope_TieuChi, #DimBind (map KKTKCN_Id) → render CHO TẤT CẢ Dim 1 LẦN */
	EXEC dbo.SP_BCDT_BMTH_RenderNarrow
		 @TongHopBieuMauId = @TongHopBieuMauId,
		 @NgayBatDauInt    = @NgayBatDauInt,
		 @NgayKetThucInt   = @NgayKetThucInt,
		 @KeHoachPickMode  = @KeHoachPickMode;
	
	-- Loại cột C khỏi danh sách VALUE nếu dùng C cho tên tỉnh
	-- Nếu dùng C cho tên tỉnh, loại bỏ EXPR C để tránh đè cột
	IF (@UseColC_Province = 1)
	BEGIN
		DELETE FROM #ValueCols WHERE Col = N'C';
		DELETE FROM #ExprBuilt WHERE ExcelCol = N'C';
	END

	/* ---------- F') Pivot kết quả ra dạng rộng ---------- */
	/* Engine đã đổ sẵn: #Agg_Narrow(DimId,OutCol,SumVal), #ValueCols(Col), #ExprBuilt(ExcelCol,ExprSql) */

	IF NOT EXISTS (
		SELECT 1 FROM tempdb.sys.indexes
		WHERE name='IX_Agg_Narrow_OutColDim'
		  AND object_id = OBJECT_ID('tempdb..#Agg_Narrow')
	)
	CREATE NONCLUSTERED INDEX IX_Agg_Narrow_OutColDim
	ON #Agg_Narrow(OutCol, DimId) INCLUDE (SumVal);

	DECLARE @cols NVARCHAR(MAX) =
		STUFF((
			SELECT N',' + QUOTENAME(Col)
			FROM #ValueCols
			ORDER BY Col
			FOR XML PATH(''), TYPE).value('.','nvarchar(max)'
		),1,1,'');

	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
	CREATE TABLE #Result([A] INT NOT NULL, [B] NVARCHAR(450) NOT NULL, DimId INT NOT NULL);

	DECLARE @addColSql NVARCHAR(MAX) = N'';
	SELECT @addColSql = @addColSql + N'ALTER TABLE #Result ADD ' + QUOTENAME(Col) + N' DECIMAL(38,6) NULL;' + CHAR(10)
	FROM #ValueCols;
	IF LEN(@addColSql) > 0 EXEC sp_executesql @addColSql;

	DECLARE @selectValueCols NVARCHAR(MAX) =
		STUFF((
			SELECT N',COALESCE(pv.' + QUOTENAME(Col) + N',0) AS ' + QUOTENAME(Col)
			FROM #ValueCols
			ORDER BY Col
			FOR XML PATH(''), TYPE).value('.','nvarchar(max)'
		),1,1,'');

	IF ISNULL(@cols,N'') = N''
	BEGIN		
		INSERT INTO #Result([A],[B], DimId)
		SELECT ROW_NUMBER() OVER (
				 ORDER BY COALESCE(nkh.TenTheoKeHoach, kk.TenKKTKCN, CONVERT(NVARCHAR(50), kk.KKTId))
			   ) AS [A],
			   COALESCE(nkh.TenTheoKeHoach, kk.TenKKTKCN, CONVERT(NVARCHAR(50), kk.KKTId)) AS [B],
			   kk.DimId
		FROM #KKT kk
		LEFT JOIN #KKT_NameKH nkh ON nkh.DimId = kk.DimId
		ORDER BY COALESCE(nkh.TenTheoKeHoach, kk.TenKKTKCN, CONVERT(NVARCHAR(50), kk.KKTId));
	END
	ELSE
	BEGIN
		DECLARE @sqlInsert NVARCHAR(MAX) = N'
			WITH Pv AS
			(
				SELECT DimId,' + @cols + N'
				FROM (SELECT DimId, OutCol, SumVal FROM #Agg_Narrow) s
				PIVOT (MAX(SumVal) FOR OutCol IN (' + @cols + N')) pv
			)
			INSERT INTO #Result([A],[B],DimId,' + @cols + N')
			SELECT ROW_NUMBER() OVER (
					 ORDER BY COALESCE(nkh.TenTheoKeHoach, kk.TenKKTKCN, CONVERT(NVARCHAR(50), kk.KKTId))
				   ),
				   COALESCE(nkh.TenTheoKeHoach, kk.TenKKTKCN, CONVERT(NVARCHAR(50), kk.KKTId)),
				   kk.DimId'
				   + CASE WHEN ISNULL(@selectValueCols,N'')=N'' THEN N'' ELSE N',' + @selectValueCols END + N'
			FROM #KKT kk
			LEFT JOIN #KKT_NameKH nkh ON nkh.DimId = kk.DimId
			LEFT JOIN Pv pv ON pv.DimId = kk.DimId
			ORDER BY COALESCE(nkh.TenTheoKeHoach, kk.TenKKTKCN, CONVERT(NVARCHAR(50), kk.KKTId))
			OPTION(RECOMPILE);';
		EXEC sp_executesql @sqlInsert;
	END

	-- Tối ưu update C theo DimId
	IF (@UseColC_Province = 1)
		CREATE NONCLUSTERED INDEX IX_Result_DimId ON #Result(DimId);

	IF (@UseColC_Province = 1)
	BEGIN
		-- đảm bảo cột C là chuỗi
		ALTER TABLE #Result ADD [C] NVARCHAR(500) NULL;

		-- Gom sẵn mapping DimId -> TenTinh để UPDATE nhanh hơn
		IF OBJECT_ID('tempdb..#KKT_Prov') IS NOT NULL DROP TABLE #KKT_Prov;
		SELECT kk.DimId, dv.TenDonVi AS TenTinh
		INTO #KKT_Prov
		FROM #KKT kk
		LEFT JOIN dbo.BCDT_DanhMuc_DonViHanhChinh dv
			   ON RTRIM(LTRIM(dv.MaDonVi)) = RTRIM(LTRIM(kk.DiaChi_Tinh))
			  AND dv.BitHieuLuc = 1
			  AND dv.BitDaXoa = 0;

		CREATE UNIQUE CLUSTERED INDEX IX_KKT_Prov_DimId ON #KKT_Prov(DimId);

		UPDATE r
		SET r.[C] = p.TenTinh
		FROM #Result r
		JOIN #KKT_Prov p ON p.DimId = r.DimId;
	END

	IF NOT EXISTS (
		SELECT 1 FROM tempdb.sys.indexes
		WHERE name='IX_Result_B' AND object_id = OBJECT_ID('tempdb..#Result')
	)
	CREATE CLUSTERED INDEX IX_Result_B ON #Result([B]);	

		/* ---------- G') Áp dụng EXPR vào #Result bằng UPDATE ---------- */
	DECLARE @eCol      SYSNAME;
	DECLARE @eSql      NVARCHAR(MAX);
	DECLARE @sqlUpdate NVARCHAR(MAX);

	DECLARE curExpr CURSOR LOCAL FAST_FORWARD FOR
		SELECT ExcelCol, ExprSql
		FROM #ExprBuilt
		ORDER BY ExcelCol;

	OPEN curExpr;
	FETCH NEXT FROM curExpr INTO @eCol, @eSql;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Ví dụ sinh ra:
		-- UPDATE r SET [G] = COALESCE([F],0)*100/NULLIF(COALESCE([E],0),0) FROM #Result r;
		SET @sqlUpdate = N'
			UPDATE r
			SET ' + QUOTENAME(@eCol) + N' = ' + @eSql + N'
			FROM #Result r;
		';

		-- Có thể bật để debug:
		-- PRINT @sqlUpdate;

		EXEC sp_executesql @sqlUpdate;

		FETCH NEXT FROM curExpr INTO @eCol, @eSql;
	END
	CLOSE curExpr;
	DEALLOCATE curExpr;


	/* ---------- H') Xuất kết quả: A, B, (C nếu dùng tỉnh), VALUE cols (đã include EXPR) ---------- */
	-- Danh sách cột hiển thị C..T (VALUE + các cột bị EXPR ghi đè)
	DECLARE @valSelect NVARCHAR(MAX) =
		STUFF((
			SELECT N',' + QUOTENAME(Col)
			FROM #ValueCols
			ORDER BY Col
			FOR XML PATH(''), TYPE
		).value('.','nvarchar(max)'), 1, 1, N'');

	-- Nếu @UseColC_Province = 1 thì thêm cột [C] (tên tỉnh) đứng ngay sau [B]
	DECLARE @colC NVARCHAR(10) =
		CASE WHEN @UseColC_Province = 1 THEN N',[C]' ELSE N'' END;

	DECLARE @sqlOut NVARCHAR(MAX) = N'
		SELECT [A],[B]' + @colC
		+ CASE WHEN ISNULL(@valSelect,N'') = N'' THEN N'' ELSE N',' + @valSelect END
		+ N' FROM #Result
		   ORDER BY [B]
		   OPTION(RECOMPILE);';

	-- Có thể bật để xem câu SELECT runtime
	-- PRINT @sqlOut;

	EXEC sp_executesql @sqlOut;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_BMTH_Theo_NhaDauTu]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================================
-- STORED PROCEDURE: dbo.SP_BCDT_BMTH_Theo_NhaDauTu
-- Phiên bản : 1.0 (2025-10-30)
-- Mục đích  : Wrapper tổng hợp Biểu Mẫu Tổng Hợp (BMTH) theo Nhà đầu tư (NĐT),
--             dùng chung engine dbo.SP_BCDT_BMTH_RenderNarrow.
--
-- Tư tưởng  :
--   - NĐT được xác định duy nhất bởi MaDinhDanh (nghiệp vụ bắt buộc).
--   - Một NĐT có thể xuất hiện ở nhiều TieuChiId/DonViId (qua bảng BCDT_TieuChi_NhaDauTu).
--   - Engine RenderNarrow yêu cầu:
--       (1) #UnitSet(DimId, DonViId) : ánh xạ Dim → các đơn vị (DonViId) cần tổng hợp
--       (2) (tùy chọn) #BMTH_RowScope_TieuChi(DimId,DonViId,KeHoachId,TieuChiId)
--           để ràng buộc dòng dữ liệu theo tiêu chí đúng cho Dim
--     => Wrapper này chuẩn bị đủ (1) và (2), sau đó gọi engine.
--
-- Tham số :
--   @TongHopBieuMauId : cấu hình BMTH (map cột, terms) đã có sẵn
--   @NgayBatDauInt, @NgayKetThucInt : kỳ tính (áp dụng cho chọn kế hoạch)
--   @NhaDauTuScope    : ALL | LIST | EXCLUDE (lọc theo MaDinhDanh)
--   @MaDinhDanhJson   : JSON array các MaDinhDanh (khi LIST/EXCLUDE)
--   @DonViScope       : ALL | LIST | EXCLUDE (lọc thêm theo DonViId, tùy chọn)
--   @DonViIdsJson     : JSON array DonViId (khi LIST/EXCLUDE)
--   @KeHoachPickMode  : SUM (cộng mọi KH trong kỳ) | LATEST (chọn KH mới nhất/đơn vị)
--
-- Đầu ra :
--   - Bảng kết quả theo pattern: A (STT), B (Tên NĐT), các cột VALUE (pivot)
--     và các cột EXPR (từ #ExprBuilt của engine).
--
-- Ghi chú hiệu năng:
--   - Dùng OPTION(RECOMPILE) cho các truy vấn động / phụ thuộc dữ liệu
--     để tối ưu plan khi số cột pivot, tập NĐT/Đơn vị thay đổi lớn.
-- =============================================================================
CREATE     PROCEDURE [dbo].[SP_BCDT_BMTH_Theo_NhaDauTu]
(
    @TongHopBieuMauId INT,
    @NgayBatDauInt    INT,
    @NgayKetThucInt   INT,
    @NhaDauTuScope    NVARCHAR(10) = N'ALL',       -- ALL | LIST | EXCLUDE (lọc theo MaDinhDanh)
    @MaDinhDanhJson   NVARCHAR(MAX) = NULL,        -- JSON array các MaDinhDanh nếu dùng LIST/EXCLUDE
    @DonViScope       NVARCHAR(10) = N'ALL',       -- ALL | LIST | EXCLUDE (lọc theo DonViId)
    @DonViIdsJson     NVARCHAR(MAX) = NULL,
    @KeHoachPickMode  NVARCHAR(10) = N'SUM'        -- SUM | LATEST
)
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @TrangThai INT = 1007; 
    /* A) Danh mục NĐT (Dim) theo MaDinhDanh (khóa duy nhất) */
    IF OBJECT_ID('tempdb..#Investor') IS NOT NULL DROP TABLE #Investor;
    CREATE TABLE #Investor(
        DimId INT IDENTITY(1,1) PRIMARY KEY,
        MaDinhDanh NVARCHAR(200) NOT NULL,
        TenNDT NVARCHAR(2000) NULL
    );

    -- Chọn distinct theo MaDinhDanh, tên đại diện lấy MAX(Ten) sau khi trim.
	INSERT INTO #Investor(MaDinhDanh, TenNDT)
	SELECT  mdn = UPPER(LTRIM(RTRIM(n.MaDinhDanh))),
			MAX(NULLIF(LTRIM(RTRIM(n.Ten)), N''))
	FROM dbo.BCDT_TieuChi_NhaDauTu n
	WHERE n.BitDaXoa = 0
	  AND n.MaDinhDanh IS NOT NULL
	  AND LTRIM(RTRIM(n.MaDinhDanh)) <> N''
	  AND (
			@NhaDauTuScope = N'ALL'
		 OR (@NhaDauTuScope = N'LIST'
			 AND ISJSON(@MaDinhDanhJson)=1
			 AND EXISTS (SELECT 1 FROM OPENJSON(@MaDinhDanhJson)
						 WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200), value))))
							   = UPPER(LTRIM(RTRIM(n.MaDinhDanh)))))
		 OR (@NhaDauTuScope = N'EXCLUDE'
			 AND (ISJSON(@MaDinhDanhJson)<>1 OR NOT EXISTS (
					SELECT 1 FROM OPENJSON(@MaDinhDanhJson)
					WHERE UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(200), value))))
						  = UPPER(LTRIM(RTRIM(n.MaDinhDanh)))
				 )))
		  )
	GROUP BY UPPER(LTRIM(RTRIM(n.MaDinhDanh)));

    /* B) Ánh xạ Investor → DonVi → #UnitSet(DimId, DonViId)
          Nguồn DonViId lấy từ BCDT_DanhMuc_TieuChi tương ứng TieuChiId của NĐT */
    IF OBJECT_ID('tempdb..#UnitSet') IS NOT NULL DROP TABLE #UnitSet;
    CREATE TABLE #UnitSet(
        DimId INT NOT NULL,
        DonViId INT NOT NULL,
        PRIMARY KEY(DimId, DonViId)
    );

    INSERT INTO #UnitSet(DimId, DonViId)
    SELECT DISTINCT i.DimId, tc.DonViId
    FROM #Investor i
    JOIN dbo.BCDT_TieuChi_NhaDauTu n
         ON n.BitDaXoa=0 AND LTRIM(RTRIM(n.MaDinhDanh)) = LTRIM(RTRIM(i.MaDinhDanh))
    JOIN dbo.BCDT_DanhMuc_TieuChi tc
         ON tc.BitDaXoa=0 AND tc.Id = n.TieuChiId
    WHERE tc.DonViId IS NOT NULL
      AND (
            @DonViScope = N'ALL'
         OR (@DonViScope = N'LIST'
                AND ISJSON(@DonViIdsJson)=1
                AND EXISTS (SELECT 1 FROM OPENJSON(@DonViIdsJson) j WHERE TRY_CONVERT(INT, j.value) = tc.DonViId)
            )
         OR (@DonViScope = N'EXCLUDE'
                AND (ISJSON(@DonViIdsJson)<>1
                     OR NOT EXISTS (SELECT 1 FROM OPENJSON(@DonViIdsJson) j WHERE TRY_CONVERT(INT, j.value) = tc.DonViId))
            )
          )

	IF OBJECT_ID('tempdb..#AliasBM') IS NOT NULL DROP TABLE #AliasBM;
		SELECT DISTINCT a.BieuMauId
		INTO #AliasBM
		FROM dbo.BCDT_BMTH_ColumnMap m
		JOIN dbo.BCDT_BMTH_ColumnMap_Term t ON t.MapId = m.Id AND m.TongHopBieuMauId = @TongHopBieuMauId AND m.IsActive = 1
		JOIN dbo.BCDT_BMTH_BieuNguon_Alias a ON a.Alias = t.Alias AND a.IsActive = 1;


    /* C) Row-scope theo TieuChiId cho toàn bộ KH trong kỳ
          - Engine sẽ LEFT JOIN vào #BMTH_RowScope_TieuChi để ràng buộc dòng đúng Dim/DonVi/KeHoach/TieuChi
          - Hoạt động đúng cho cả SUM (mọi KH) và LATEST (engine tự chọn KH trong kỳ)
    */
    IF OBJECT_ID('tempdb..#BMTH_RowScope_TieuChi') IS NOT NULL DROP TABLE #BMTH_RowScope_TieuChi;
    CREATE TABLE #BMTH_RowScope_TieuChi(
        DimId INT NOT NULL,
        DonViId INT NOT NULL,
        KeHoachId INT NOT NULL,
        TieuChiId INT NOT NULL,
        PRIMARY KEY (DimId, DonViId, KeHoachId, TieuChiId)
    );

    ;WITH KH AS (
    SELECT k.Id AS KeHoachId, k.DonViId
    FROM dbo.BCDT_KeHoach k
    JOIN dbo.BCDT_KeHoach_Dot d ON d.Id = k.DotId AND d.BitDaXoa = 0
    WHERE k.BitDaXoa = 0
      AND d.NgayBatDauInt = @NgayBatDauInt
      AND d.NgayKetThucInt = @NgayKetThucInt
	),
	KH_PICK AS (
		-- SUM: giữ nguyên toàn bộ KH trong kỳ
		SELECT DonViId, KeHoachId
		FROM KH
		WHERE @KeHoachPickMode = N'SUM'

		UNION ALL

		-- LATEST: chọn KH mới nhất mỗi Đơn vị theo ngày, tie-break theo Id
		SELECT x.DonViId, x.Id AS KeHoachId
		FROM (
			SELECT
				k.DonViId,
				k.Id,
				ROW_NUMBER() OVER (
					PARTITION BY k.DonViId
					ORDER BY d.NgayKetThucInt DESC, k.Id DESC
				) AS rn
			FROM dbo.BCDT_KeHoach k
			JOIN dbo.BCDT_KeHoach_Dot d ON d.Id = k.DotId AND d.BitDaXoa = 0
			WHERE k.BitDaXoa = 0
			  AND d.NgayBatDauInt = @NgayBatDauInt
			  AND d.NgayKetThucInt = @NgayKetThucInt
			  AND @KeHoachPickMode = N'LATEST'
		) x
		WHERE x.rn = 1
	)
	INSERT INTO #BMTH_RowScope_TieuChi(DimId, DonViId, KeHoachId, TieuChiId)
	SELECT DISTINCT i.DimId, tc.DonViId, khp.KeHoachId, tc.Id AS TieuChiId
	FROM #Investor i
	JOIN dbo.BCDT_TieuChi_NhaDauTu n
		 ON n.BitDaXoa=0 AND LTRIM(RTRIM(n.MaDinhDanh)) = i.MaDinhDanh
	JOIN dbo.BCDT_DanhMuc_TieuChi tc
		 ON tc.BitDaXoa=0 AND tc.Id = n.TieuChiId
	JOIN KH_PICK khp
		 ON khp.DonViId = tc.DonViId
	JOIN dbo.BCDT_KeHoach_TongHop th
		ON th.KeHoachId = khp.KeHoachId
		 AND th.TrangThai = @TrangThai
		 AND EXISTS (SELECT 1 FROM #AliasBM b WHERE b.BieuMauId = th.BieuMauId)
	WHERE EXISTS (SELECT 1 FROM #UnitSet u WHERE u.DimId = i.DimId AND u.DonViId = tc.DonViId);

    /* D) Khởi tạo các temp mà engine sẽ dùng/ghi (tránh lỗi compile và để engine TRUNCATE/INSERT) */
    IF OBJECT_ID('tempdb..#ValueCols') IS NULL
        CREATE TABLE #ValueCols(Col SYSNAME PRIMARY KEY);
    ELSE
        TRUNCATE TABLE #ValueCols;

    IF OBJECT_ID('tempdb..#Agg_Narrow') IS NULL
        CREATE TABLE #Agg_Narrow(DimId INT NOT NULL, OutCol SYSNAME NOT NULL, SumVal DECIMAL(38,6) NULL);
    ELSE
        TRUNCATE TABLE #Agg_Narrow;

    IF OBJECT_ID('tempdb..#ExprBuilt') IS NULL
        CREATE TABLE #ExprBuilt(ExcelCol SYSNAME PRIMARY KEY, ExprSql NVARCHAR(MAX));
    ELSE
        TRUNCATE TABLE #ExprBuilt;

    /* E) Gọi engine tính dùng chung (KHÔNG sửa logic engine) */
    EXEC dbo.SP_BCDT_BMTH_RenderNarrow
         @TongHopBieuMauId=@TongHopBieuMauId,
         @NgayBatDauInt=@NgayBatDauInt,
         @NgayKetThucInt=@NgayKetThucInt,
         @KeHoachPickMode=@KeHoachPickMode;
	
	IF NOT EXISTS (
		SELECT 1
		FROM tempdb.sys.indexes 
		WHERE name = 'IX_Agg_Narrow_OutColDim'
		  AND object_id = OBJECT_ID('tempdb..#Agg_Narrow')
	)
		CREATE NONCLUSTERED INDEX IX_Agg_Narrow_OutColDim
			ON #Agg_Narrow(OutCol, DimId) INCLUDE (SumVal);

    /* F) Pivot các VALUE cols vào bảng kết quả #Result (A=STT, B=Tên NĐT) */
    DECLARE @cols NVARCHAR(MAX) =
      STUFF((SELECT N','+QUOTENAME(Col) FROM #ValueCols ORDER BY Col FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,'');

    IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
    CREATE TABLE #Result([A] INT NOT NULL, [B] NVARCHAR(2000) NOT NULL);

    -- Thêm động các cột VALUE vào #Result
    DECLARE @addColSql NVARCHAR(MAX)=N'';
    SELECT @addColSql = @addColSql + N'ALTER TABLE #Result ADD ' + QUOTENAME(Col) + N' DECIMAL(38,6) NULL;' + CHAR(10)
    FROM #ValueCols;
    IF LEN(@addColSql)>0 EXEC sp_executesql @addColSql;

    -- Build SELECT phần VALUE (COALESCE để tránh NULL)
    DECLARE @selectValueCols NVARCHAR(MAX) =
      STUFF((SELECT N',COALESCE(pv.'+QUOTENAME(Col)+N',0) AS '+QUOTENAME(Col)
             FROM #ValueCols ORDER BY Col FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,'');

    IF @cols IS NULL OR LEN(@cols)=0
    BEGIN
        -- Không có cột VALUE: chỉ đổ A,B
        INSERT INTO #Result([A],[B])
        SELECT ROW_NUMBER() OVER (ORDER BY COALESCE(TenNDT, MaDinhDanh)) AS [A],
               COALESCE(TenNDT, MaDinhDanh) AS [B]
        FROM #Investor
        ORDER BY COALESCE(TenNDT, MaDinhDanh)
    END
    ELSE
    BEGIN
        -- Có cột VALUE: pivot trước vào CTE Pv rồi insert vào #Result
        DECLARE @sqlInsert NVARCHAR(MAX)=N'
        WITH Pv AS (
          SELECT DimId,'+@cols+N'
          FROM (SELECT DimId, OutCol, SumVal FROM #Agg_Narrow) s
          PIVOT (MAX(SumVal) FOR OutCol IN ('+@cols+N')) pv
        )
        INSERT INTO #Result([A],[B],'+@cols+N')
        SELECT ROW_NUMBER() OVER(ORDER BY COALESCE(i.TenNDT, i.MaDinhDanh)) AS [A],
               COALESCE(i.TenNDT, i.MaDinhDanh) AS [B]'
               + CASE WHEN @selectValueCols IS NULL OR LEN(@selectValueCols)=0 THEN N'' ELSE N','+@selectValueCols END + N'
        FROM #Investor i
        LEFT JOIN Pv pv ON pv.DimId = i.DimId
        ORDER BY COALESCE(i.TenNDT, i.MaDinhDanh)
        OPTION(RECOMPILE);';  -- số cột pivot thay đổi → luôn tái biên dịch cho plan phù hợp
        EXEC sp_executesql @sqlInsert;
    END

	IF NOT EXISTS (
	  SELECT 1 FROM tempdb.sys.indexes 
	  WHERE name = 'IX_Result_B' AND object_id = OBJECT_ID('tempdb..#Result')
	)
		CREATE CLUSTERED INDEX IX_Result_B ON #Result([B]);

        /* G) Áp dụng EXPR vào #Result bằng UPDATE
       - Mỗi dòng trong #ExprBuilt: ExcelCol, ExprSql
       - ExprSql là biểu thức dùng các cột đã có trong #Result (C..T, v.v.)
       - Ta UPDATE trực tiếp giá trị cột tương ứng trong #Result
    ------------------------------------------------------------------*/
    DECLARE @tmpCol    SYSNAME;
    DECLARE @tmpExpr   NVARCHAR(MAX);
    DECLARE @sqlUpdate NVARCHAR(MAX);

    DECLARE curB CURSOR LOCAL FAST_FORWARD FOR
        SELECT ExcelCol, ExprSql
        FROM #ExprBuilt
        ORDER BY ExcelCol;

    OPEN curB;
    FETCH NEXT FROM curB INTO @tmpCol, @tmpExpr;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Ví dụ sinh ra:
        -- UPDATE r SET [G] = COALESCE([F],0)*100/NULLIF(COALESCE([E],0),0) FROM #Result r;
        SET @sqlUpdate = N'
            UPDATE r
            SET ' + QUOTENAME(@tmpCol) + N' = ' + @tmpExpr + N'
            FROM #Result r;
        ';

        -- Có thể bật debug nếu cần:
        -- PRINT @sqlUpdate;

        EXEC sp_executesql @sqlUpdate;

        FETCH NEXT FROM curB INTO @tmpCol, @tmpExpr;
    END
    CLOSE curB;
    DEALLOCATE curB;


    /* H) Xuất kết quả
       - Tất cả EXPR đã được ghi trực tiếp vào cột tương ứng trong #Result
       - SELECT cuối: A, B + các VALUE cols (C..T), không còn append AS [G] lần nữa
    ------------------------------------------------------------------*/
    DECLARE @valSelect NVARCHAR(MAX) =
      STUFF((
        SELECT N',' + QUOTENAME(Col)
        FROM #ValueCols
        ORDER BY Col
        FOR XML PATH(''), TYPE
      ).value('.','nvarchar(max)'), 1, 1, N'');

    DECLARE @sqlOut NVARCHAR(MAX) = N'
      SELECT [A],[B]'
      + CASE WHEN @valSelect IS NULL OR LEN(@valSelect) = 0
             THEN N''
             ELSE N',' + @valSelect
        END
      + N' FROM #Result
         ORDER BY [B]
         OPTION(RECOMPILE);';

    -- Có thể bật để xem câu SELECT runtime:
    -- PRINT @sqlOut;

    EXEC sp_executesql @sqlOut;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_BMTH_Theo_Tinh]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*==============================================================================
  SP:        dbo.SP_BCDT_BMTH_Theo_Tinh
  Mục đích:  Kết xuất báo cáo tổng hợp theo ĐỊA GIỚI HÀNH CHÍNH cấp TỈNH,
             có thể tùy chọn nhóm hiển thị THEO VÙNG KINH TẾ (A=La Mã cho Vùng,
             B=Tên Vùng / Tên Tỉnh; các cột C..T là VALUE/EXPR do engine build).

  Engine dùng chung:
    - dbo.SP_BCDT_BMTH_RenderNarrow: bơm dữ liệu vào các temp sau (tạo nếu chưa có):
        #ValueCols(Col)       : danh sách cột VALUE cần pivot (như 'C','D',...)
        #Agg_Narrow(DimId,OutCol,SumVal) : dữ liệu dạng “hẹp” để pivot
        #ExprBuilt(ExcelCol,ExprSql)     : biểu thức EXPR cần append vào SELECT cuối

  Tham số:
    @TongHopBieuMauId : Id cấu hình biểu tổng hợp (BMTH)
    @NgayBatDauInt    : Ngày đầu kỳ (yyyymmdd int)
    @NgayKetThucInt   : Ngày cuối kỳ (yyyymmdd int)
    @DonViScope       : Lọc đơn vị nguồn (ALL|LIST|EXCLUDE) qua #UnitSet
    @DonViIdsJson     : JSON mảng Id đơn vị nguồn (áp dụng theo @DonViScope)
    @KeHoachPickMode  : Cách chọn KH (SUM|LATEST) chuyển cho engine
    @GroupBy          : NONE (theo Tỉnh) | REGION (theo Vùng → Tỉnh)

  Đầu ra:
    - Bảng tạm #Result để SELECT ra ngoài theo trật tự OrderKey
      Cột A: Số thứ tự hiển thị trong vùng (hoặc toàn danh sách khi NONE)
      Cột B: Tên hiển thị (Vùng hoặc Tỉnh)
      Cột C..T (nếu có): VALUE (pivot từ #Agg_Narrow) + cột EXPR (từ #ExprBuilt)

  Ghi chú hiệu năng:
    - Có index tạm trên #Agg_Narrow(OutCol,DimId) INCLUDE(SumVal) hỗ trợ PIVOT/lookup
    - #Result có clustered index theo OrderKey để đảm bảo sắp xếp ổn định
    - OrderKey dựng theo dạng CHUỖI zero-pad 'RRR-PPPP' (RRR = thứ tự vùng; PPPP = stt tỉnh)
      để ORDER BY luôn đúng thứ tự mong muốn (ổn định theo “từ điển”)
==============================================================================*/
CREATE   PROCEDURE [dbo].[SP_BCDT_BMTH_Theo_Tinh]
(
    @TongHopBieuMauId INT,
    @NgayBatDauInt    INT,
    @NgayKetThucInt   INT,
    @DonViScope       NVARCHAR(10) = N'ALL',      -- ALL | LIST | EXCLUDE
    @DonViIdsJson     NVARCHAR(MAX) = NULL,
    @KeHoachPickMode  NVARCHAR(10) = N'SUM',      -- SUM | LATEST
    @GroupBy          NVARCHAR(10) = N'NONE'      -- NONE | REGION
)
AS
BEGIN
    SET NOCOUNT ON;

    /*----------------------------------------------------------------------
      A) Danh mục TỈNH (Dim)
      - #Province: danh sách tỉnh (DimId = Id tỉnh, Ten = Tên tỉnh)
      - Chỉ lấy cấp gốc (MaCapCha = ''), chưa xóa
    ----------------------------------------------------------------------*/
    IF OBJECT_ID('tempdb..#Province') IS NOT NULL DROP TABLE #Province;
    CREATE TABLE #Province(DimId INT PRIMARY KEY, Ten NVARCHAR(500));

    INSERT INTO #Province(DimId, Ten)
    SELECT a.Id, a.TenDonVi
    FROM dbo.BCDT_DanhMuc_DonViHanhChinh a
    WHERE ISNULL(a.MaCapCha,'')='' AND a.BitDaXoa=0;
    -- Nếu có BitHieuLuc, có thể thêm: AND a.BitHieuLuc=1

    /*----------------------------------------------------------------------
      B) Ánh xạ Province ↔ DonVi → #UnitSet(DimId, DonViId)
      - Dùng để giới hạn tập tỉnh theo phạm vi @DonViScope/@DonViIdsJson
      - Chỉ các tỉnh có ít nhất 01 DonViSuDung hợp lệ mới góp mặt
    ----------------------------------------------------------------------*/
    IF OBJECT_ID('tempdb..#UnitSet') IS NOT NULL DROP TABLE #UnitSet;
    CREATE TABLE #UnitSet(DimId INT, DonViId INT, PRIMARY KEY(DimId, DonViId));

    INSERT INTO #UnitSet(DimId, DonViId)
    SELECT a.Id, b.Id
    FROM dbo.BCDT_DanhMuc_DonViHanhChinh a
    JOIN dbo.DM_DonViSuDung b ON a.Id=b.TinhId AND b.BitDaXoa=0
    WHERE ISNULL(a.MaCapCha,'')='' AND a.BitDaXoa=0
      AND (
            @DonViScope=N'ALL'
         OR (@DonViScope=N'LIST'
             AND ISJSON(@DonViIdsJson)=1
             AND EXISTS (SELECT 1 FROM OPENJSON(@DonViIdsJson) j WHERE TRY_CONVERT(INT,j.value)=b.Id))
         OR (@DonViScope=N'EXCLUDE'
             AND (ISJSON(@DonViIdsJson)<>1
                  OR NOT EXISTS (SELECT 1 FROM OPENJSON(@DonViIdsJson) j WHERE TRY_CONVERT(INT,j.value)=b.Id)))
          );

    /*----------------------------------------------------------------------
      C0) KHỞI TẠO CÁC TEMP MÀ ENGINE SẼ GHI VÀO
      - Quan trọng: engine KHÔNG DROP các temp này → ở đây ta chủ động tạo/truncate
    ----------------------------------------------------------------------*/
    IF OBJECT_ID('tempdb..#ValueCols') IS NULL
        CREATE TABLE #ValueCols(Col SYSNAME PRIMARY KEY);
    ELSE
        TRUNCATE TABLE #ValueCols;

    IF OBJECT_ID('tempdb..#Agg_Narrow') IS NULL
        CREATE TABLE #Agg_Narrow(DimId INT NOT NULL, OutCol SYSNAME NOT NULL, SumVal DECIMAL(38,6) NULL);
    ELSE
        TRUNCATE TABLE #Agg_Narrow;

    IF OBJECT_ID('tempdb..#ExprBuilt') IS NULL
        CREATE TABLE #ExprBuilt(ExcelCol SYSNAME PRIMARY KEY, ExprSql NVARCHAR(MAX));
    ELSE
        TRUNCATE TABLE #ExprBuilt;

    /*----------------------------------------------------------------------
      C1) Gọi engine tính dùng chung để bơm #ValueCols/#Agg_Narrow/#ExprBuilt
    ----------------------------------------------------------------------*/
    BEGIN TRY
	EXEC dbo.SP_BCDT_BMTH_RenderNarrow
         @TongHopBieuMauId=@TongHopBieuMauId,
         @NgayBatDauInt=@NgayBatDauInt,
         @NgayKetThucInt=@NgayKetThucInt,
         @KeHoachPickMode=@KeHoachPickMode;
	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg NVARCHAR(4000) =
			N'SP_BCDT_BMTH_Theo_Tinh: lỗi khi gọi SP_BCDT_BMTH_RenderNarrow. ' +
			N'ERROR_PROCEDURE=' + ISNULL(ERROR_PROCEDURE(),N'NULL') +
			N', ERROR_LINE=' + CAST(ERROR_LINE() AS NVARCHAR(10)) +
			N', ERROR_MESSAGE=' + ERROR_MESSAGE() +
			N'; @TongHopBieuMauId=' + CAST(@TongHopBieuMauId AS NVARCHAR(20)) +
			N', @NgayBatDauInt=' + CAST(@NgayBatDauInt AS NVARCHAR(20)) +
			N', @NgayKetThucInt=' + CAST(@NgayKetThucInt AS NVARCHAR(20)) +
			N', @KeHoachPickMode=' + ISNULL(@KeHoachPickMode,N'<NULL>');

		RAISERROR(@ErrMsg, 16, 1);
		RETURN;
	END CATCH;
    /*----------------------------------------------------------------------
      C1.1) Index tạm để tăng tốc PIVOT/lookup trên #Agg_Narrow
      - Khóa tìm kiếm phổ biến: (OutCol, DimId) và cần đọc SumVal
      - INCLUDE(SumVal) để tránh lookup thêm
    ----------------------------------------------------------------------*/
    IF NOT EXISTS (
        SELECT 1
        FROM tempdb.sys.indexes 
        WHERE name = 'IX_Agg_Narrow_OutColDim'
          AND object_id = OBJECT_ID('tempdb..#Agg_Narrow')
    )
        CREATE NONCLUSTERED INDEX IX_Agg_Narrow_OutColDim
            ON #Agg_Narrow(OutCol, DimId) INCLUDE (SumVal);
	
    /*----------------------------------------------------------------------
      D) Build PIVOT danh sách VALUE cols
      - @cols là danh sách [Col] dạng [C],[D],...
      - #Result: chứa dòng đầu ra theo thứ tự OrderKey để SELECT cuối
        + OrderKey: 'RRR-PPPP' (RRR = thứ tự vùng, 000 khi GroupBy=NONE)
        + A       : STT hiển thị (La Mã cho dòng vùng; số 1..n cho tỉnh)
        + B       : Tên hiển thị (Vùng hoặc Tỉnh)
        + VALUE   : các cột kết quả pivot (nếu có)
    ----------------------------------------------------------------------*/
    DECLARE @cols NVARCHAR(MAX) =
      STUFF((SELECT N','+QUOTENAME(Col) FROM #ValueCols ORDER BY Col FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,'');

    IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
    CREATE TABLE #Result(
        OrderKey NVARCHAR(20) NOT NULL,
        [A] NVARCHAR(50) NOT NULL,
        [B] NVARCHAR(500) NOT NULL
    );

    -- (Tùy quy mô dữ liệu: có thể tạo clustered index SAU khi insert xong để insert nhanh hơn)
    DECLARE @addColSql NVARCHAR(MAX)=N'';
    SELECT @addColSql = @addColSql + N'ALTER TABLE #Result ADD ' + QUOTENAME(Col) + N' DECIMAL(38,6) NULL;' + CHAR(10)
    FROM #ValueCols;
    IF LEN(@addColSql)>0 EXEC sp_executesql @addColSql;    

    DECLARE @selectValueCols NVARCHAR(MAX) =
      STUFF((SELECT N',COALESCE(pv.'+QUOTENAME(Col)+N',0) AS '+QUOTENAME(Col)
             FROM #ValueCols ORDER BY Col FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,'');

    /*----------------------------------------------------------------------
      Nhánh 1: GroupBy = NONE → Hiển thị theo TỈNH
    ----------------------------------------------------------------------*/
    IF UPPER(@GroupBy) <> N'REGION'
    BEGIN
        IF @cols IS NULL OR LEN(@cols)=0
        BEGIN
            -- Không có cột VALUE → chỉ A,B
            INSERT INTO #Result(OrderKey,[A],[B])
            SELECT '000-' + FORMAT(ROW_NUMBER() OVER (ORDER BY Ten),'D4'),
                   CONVERT(NVARCHAR(50), ROW_NUMBER() OVER (ORDER BY Ten)),
                   Ten
            FROM #Province
            ORDER BY Ten;
        END
        ELSE
        BEGIN
            -- Có cột VALUE → PIVOT rồi join
            DECLARE @sqlInsert NVARCHAR(MAX)=N'
            WITH Pv AS (
              SELECT DimId,'+@cols+N'
              FROM (SELECT DimId, OutCol, SumVal FROM #Agg_Narrow) s
              PIVOT (MAX(SumVal) FOR OutCol IN ('+@cols+N')) pv
            )
            INSERT INTO #Result(OrderKey,[A],[B],'+@cols+N')
            SELECT ''000-'' + FORMAT(ROW_NUMBER() OVER(ORDER BY p.Ten),''D4'') AS OrderKey,
                   CONVERT(NVARCHAR(50), ROW_NUMBER() OVER(ORDER BY p.Ten)) AS [A],
                   p.Ten AS [B]'
                   + CASE WHEN @selectValueCols IS NULL OR LEN(@selectValueCols)=0 THEN N'' ELSE N','+@selectValueCols END + N'
            FROM #Province p
            LEFT JOIN Pv pv ON pv.DimId=p.DimId
            ORDER BY p.Ten;';			
            EXEC sp_executesql @sqlInsert;
        END
    END
    ELSE
    /*----------------------------------------------------------------------
      Nhánh 2: GroupBy = REGION → Hiển thị VÙNG (dòng tiêu đề) → TỈNH (dòng con)
      - #Region: danh mục vùng có xuất hiện trong #UnitSet
      - #ProvinceR: danh sách tỉnh trong từng vùng, đã loại trùng, đánh số PIdx
      - Chèn dòng vùng trước, sau đó chèn tỉnh, sort theo RIdx, PIdx bằng OrderKey
    ----------------------------------------------------------------------*/
    BEGIN
        -- 1) Danh mục vùng
        IF OBJECT_ID('tempdb..#Region') IS NOT NULL DROP TABLE #Region;
        CREATE TABLE #Region(RegionId INT PRIMARY KEY, TenVung NVARCHAR(500), RIdx INT, Roman NVARCHAR(10));

        ;WITH R AS (
          SELECT DISTINCT v.Id   AS RegionId, v.TenVung
          FROM dbo.BCDT_DanhMuc_VungKinhTe v
          JOIN dbo.BCDT_DanhMuc_DonViHanhChinh p
               ON p.VungKinhTeId=v.Id
              AND ISNULL(p.MaCapCha,'')='' AND p.BitDaXoa=0
          JOIN #UnitSet u ON u.DimId=p.Id
          WHERE v.BitDaXoa=0
        ),
        Rn AS (
          -- Thứ tự vùng: theo RegionId (ổn định, không phụ thuộc chữ cái)
          SELECT RegionId, TenVung,
                 ROW_NUMBER() OVER(ORDER BY RegionId) AS RIdx
          FROM R
        )
        INSERT INTO #Region(RegionId,TenVung,RIdx,Roman)
        SELECT RegionId, TenVung, RIdx,
               CASE RIdx
                    WHEN 1 THEN N'I'  WHEN 2 THEN N'II'   WHEN 3 THEN N'III' WHEN 4 THEN N'IV'  WHEN 5 THEN N'V'
                    WHEN 6 THEN N'VI' WHEN 7 THEN N'VII'  WHEN 8 THEN N'VIII' WHEN 9 THEN N'IX' WHEN 10 THEN N'X'
                    ELSE N'X' + CONVERT(NVARCHAR(10), RIdx-10) END
        FROM Rn;

        -- 2) Danh sách tỉnh theo từng vùng (đã DISTINCT theo UnitSet để tránh trùng)
        IF OBJECT_ID('tempdb..#ProvinceR') IS NOT NULL DROP TABLE #ProvinceR;
        CREATE TABLE #ProvinceR(
            DimId    INT PRIMARY KEY,      -- khóa tỉnh
            Ten      NVARCHAR(500),
            RegionId INT,
            PIdx     INT,                  -- thứ tự trong vùng
            OrderKey NVARCHAR(100)         -- 'RRR-PPPP' để sort ổn định
        );

        ;WITH PR AS (
            SELECT DISTINCT
                p.Id        AS DimId,
                p.TenDonVi  AS Ten,
                rg.RegionId
            FROM dbo.BCDT_DanhMuc_DonViHanhChinh p
            JOIN #Region rg     ON rg.RegionId = p.VungKinhTeId
            JOIN #UnitSet u     ON u.DimId     = p.Id
            WHERE ISNULL(p.MaCapCha,'') = '' AND p.BitDaXoa = 0
        ),
        PRn AS (
            SELECT
                DimId, Ten, RegionId,
                ROW_NUMBER() OVER (PARTITION BY RegionId ORDER BY Ten) AS PIdx
            FROM PR
        )
        INSERT INTO #ProvinceR(DimId, Ten, RegionId, PIdx, OrderKey)
        SELECT
            n.DimId, n.Ten, n.RegionId, n.PIdx,
            FORMAT(r.RIdx,'D3') + N'-' + FORMAT(n.PIdx,'D4') AS OrderKey
        FROM PRn n
        JOIN #Region r ON r.RegionId = n.RegionId;

		/* 2.1) Tổng hợp VALUE theo Vùng từ #Agg_Narrow (subtotal region) */
		IF OBJECT_ID('tempdb..#Agg_Region') IS NOT NULL DROP TABLE #Agg_Region;
		CREATE TABLE #Agg_Region(
			RegionId INT NOT NULL,
			OutCol   SYSNAME NOT NULL,
			SumVal   DECIMAL(38,6) NULL,
			PRIMARY KEY(RegionId, OutCol)
		);

		INSERT INTO #Agg_Region(RegionId, OutCol, SumVal)
		SELECT pr.RegionId, an.OutCol, SUM(an.SumVal)
		FROM #ProvinceR pr
		JOIN #Agg_Narrow an ON an.DimId = pr.DimId
		GROUP BY pr.RegionId, an.OutCol;

		/* Chuỗi select cho pivot vùng (giống @selectValueCols nhưng alias là pvr) */
		DECLARE @selectValueColsR NVARCHAR(MAX) =
		  STUFF((
			SELECT N',COALESCE(pvr.' + QUOTENAME(Col) + N',0) AS ' + QUOTENAME(Col)
			FROM #ValueCols ORDER BY Col FOR XML PATH(''), TYPE
		  ).value('.','nvarchar(max)'),1,1,'');

        -- 3) Chèn dòng VÙNG (A=La Mã; B=Tên Vùng)
		IF @cols IS NULL OR LEN(@cols) = 0
		BEGIN
			-- Không có VALUE → chỉ A,B
			INSERT INTO #Result(OrderKey,[A],[B])
			SELECT FORMAT(r.RIdx,'D3') + N'-0000', r.Roman, r.TenVung
			FROM #Region r
			ORDER BY r.RIdx;
		END
		ELSE
		BEGIN
			-- Có VALUE → pivot tổng vùng rồi chèn kèm các cột VALUE (subtotal)
			DECLARE @sqlInsertRegion NVARCHAR(MAX) = N'
			WITH PvR AS (
			  SELECT RegionId,' + @cols + N'
			  FROM (SELECT RegionId, OutCol, SumVal FROM #Agg_Region) s
			  PIVOT (MAX(SumVal) FOR OutCol IN (' + @cols + N')) p
			)
			INSERT INTO #Result(OrderKey,[A],[B],' + @cols + N')
			SELECT FORMAT(r.RIdx,''D3'') + N''-0000'' AS OrderKey,
				   r.Roman AS [A],
				   r.TenVung AS [B]'
				   + CASE WHEN @selectValueColsR IS NULL OR LEN(@selectValueColsR)=0
						  THEN N'' ELSE N',' + @selectValueColsR END + N'
			FROM #Region r
			LEFT JOIN PvR pvr ON pvr.RegionId = r.RegionId
			ORDER BY r.RIdx;';
			EXEC sp_executesql @sqlInsertRegion;
		END

        -- 4) Chèn dòng TỈNH: có/không có VALUE
        IF @cols IS NULL OR LEN(@cols)=0
        BEGIN
            INSERT INTO #Result(OrderKey,[A],[B])
            SELECT FORMAT(r.RIdx,'D3') + N'-' + FORMAT(pr.PIdx,'D4') AS OrderKey,
                   CONVERT(NVARCHAR(50), pr.PIdx) AS [A],
                   pr.Ten AS [B]
            FROM #ProvinceR pr
            JOIN #Region r ON r.RegionId=pr.RegionId
            ORDER BY r.RIdx, pr.PIdx;
        END
        ELSE
        BEGIN
            DECLARE @sqlInsertR NVARCHAR(MAX)=N'
            WITH Pv AS (
              SELECT DimId,'+@cols+N'
              FROM (SELECT DimId, OutCol, SumVal FROM #Agg_Narrow) s
              PIVOT (MAX(SumVal) FOR OutCol IN ('+@cols+N')) pv
            )
            INSERT INTO #Result(OrderKey,[A],[B],'+@cols+N')
            SELECT FORMAT(r.RIdx,''D3'') + N''-'' + FORMAT(pr.PIdx,''D4'') AS OrderKey,
                   CONVERT(NVARCHAR(50), pr.PIdx) AS [A],
                   pr.Ten AS [B]'
                   + CASE WHEN @selectValueCols IS NULL OR LEN(@selectValueCols)=0 THEN N'' ELSE N','+@selectValueCols END + N'
            FROM #ProvinceR pr
            LEFT JOIN Pv pv ON pv.DimId=pr.DimId
            JOIN #Region r ON r.RegionId=pr.RegionId
            ORDER BY r.RIdx, pr.PIdx;';
            EXEC sp_executesql @sqlInsertR;
        END
    END

	-- TẠO CLUSTERED INDEX SAU KHI ĐÃ CHÈN ĐẦY ĐỦ DỮ LIỆU #Result (tối ưu tốc độ insert)
	IF NOT EXISTS (SELECT 1 FROM tempdb.sys.indexes WHERE name = 'IX_Result_OrderKey' AND object_id = OBJECT_ID('tempdb..#Result'))
		CREATE CLUSTERED INDEX IX_Result_OrderKey ON #Result(OrderKey);

    /*----------------------------------------------------------------------
      E) Áp dụng EXPR vào #Result bằng UPDATE
      - Mỗi dòng trong #ExprBuilt: ExcelCol, ExprSql
      - ExprSql là biểu thức dùng các cột trong #Result (vd: COALESCE([F],0)*100/NULLIF(COALESCE([E],0),0))
      - Ta UPDATE giá trị cột tương ứng trong #Result
    ----------------------------------------------------------------------*/
    DECLARE @tmpCol   SYSNAME;
    DECLARE @tmpExpr  NVARCHAR(MAX);
    DECLARE @sqlUpdate NVARCHAR(MAX);

    DECLARE curB CURSOR LOCAL FAST_FORWARD FOR
        SELECT ExcelCol, ExprSql
        FROM #ExprBuilt
        ORDER BY ExcelCol;

    OPEN curB;
    FETCH NEXT FROM curB INTO @tmpCol, @tmpExpr;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Ví dụ build ra:
        -- UPDATE r SET [G] = COALESCE([F],0)*100/NULLIF(COALESCE([E],0),0) FROM #Result r;
        SET @sqlUpdate = N'
            UPDATE r
            SET ' + QUOTENAME(@tmpCol) + N' = ' + @tmpExpr + N'
            FROM #Result r;
        ';

        -- Nếu cần debug công thức, có thể bật PRINT:
        -- PRINT @sqlUpdate;

        EXEC sp_executesql @sqlUpdate;

        FETCH NEXT FROM curB INTO @tmpCol, @tmpExpr;
    END
    CLOSE curB;
    DEALLOCATE curB;


    /*----------------------------------------------------------------------
      F) Xuất kết quả
      - Tất cả EXPR đã được tính và ghi trực tiếp vào các cột tương ứng trong #Result
      - Chỉ cần SELECT [A],[B] + các VALUE cols từ #ValueCols
      - ORDER BY OrderKey để bảo toàn thứ tự Vùng / Tỉnh
    ----------------------------------------------------------------------*/
    DECLARE @valSelect NVARCHAR(MAX) =
      STUFF((
        SELECT N',' + QUOTENAME(Col)
        FROM #ValueCols
        ORDER BY Col
        FOR XML PATH(''), TYPE
      ).value('.','nvarchar(max)'), 1, 1, N'');

    DECLARE @sqlOut NVARCHAR(MAX) = N'
        SELECT [A],[B]'
        + CASE WHEN @valSelect IS NULL OR LEN(@valSelect) = 0
               THEN N''
               ELSE N',' + @valSelect
          END
        + N' FROM #Result ORDER BY OrderKey;';

    PRINT @sqlOut;   -- nếu muốn xem câu lệnh sinh ra
    EXEC sp_executesql @sqlOut;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_CapNhatKeHoachTongHop]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 26/06/2025
-- Description:	Cập nhật trạng thái kế hoạch tổng hợp
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_CapNhatKeHoachTongHop]
	@keHoachId INT,
	@trangThai INT,
	@lyDo  NVARCHAR(MAX) = ''
AS
BEGIN
	IF	EXISTS(SELECT 1 FROM dbo.BCDT_KeHoach WHERE Id = @keHoachId)
		BEGIN
			UPDATE dbo.BCDT_KeHoach 
			SET TrangThai = @trangThai, NgaySua = getdate() 
			WHERE Id = @keHoachId AND BitDaXoa = 0;
			
			IF (@lyDo <> '')
				BEGIN
					UPDATE dbo.BCDT_KeHoach
					SET LyDo = @lyDo 
					WHERE Id = @keHoachId AND BitDaXoa = 0;
				END
		END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_CapNhatKeHoachTongHop_BieuMau]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 26/06/2025
-- Description:	Cập nhật trạng thái kế hoạch tổng hợp
-- =============================================
CREATE PROCEDURE [dbo].[sp_BCDT_CapNhatKeHoachTongHop_BieuMau]
	@nguoiDungId INT,
	@keHoachId INT,
	@maBieuMau NVARCHAR(50),
	@trangThai INT,
	@isTongHop INT = 1,
	@lyDo  NVARCHAR(MAX) = ''
AS
BEGIN
	DECLARE @trangThaiGuiTH INT = 1001;
	DECLARE @trangThaiChoLDDuyet INT = 1002;
	DECLARE @trangThaiGuiBo INT = 1004;
	DECLARE @trangThaiTuChoiTiepNhan INT = 1006;
	DECLARE @trangThaiDaTiepNhanDangThamDinh INT = 1007;
	DECLARE @bieuMauId INT;
	select @bieuMauId = Id from BCDT_DanhMuc_BieuMau where MaBieuMau = @maBieuMau and BitDaXoa = 0; 
	IF (@isTongHop = -1 AND EXISTS(SELECT 1 FROM dbo.BCDT_KeHoach_TongHop WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0))
		BEGIN
			UPDATE dbo.BCDT_KeHoach_TongHop 
			SET TrangThai = @trangThai , NguoiSua = @nguoiDungId, NgaySua = GETDATE()
			WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0;
			
			IF (@lyDo <> '')
				BEGIN
					UPDATE dbo.BCDT_KeHoach_TongHop 
					SET LyDo = @lyDo 
					WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0;
				END
		END
	IF (@isTongHop = 1 AND EXISTS(SELECT 1 FROM dbo.BCDT_KeHoach_TongHop WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0 AND TrangThai IN (@trangThaiGuiTH, @trangThaiTuChoiTiepNhan)))
		BEGIN
			UPDATE dbo.BCDT_KeHoach_TongHop 
			SET TrangThai = @trangThai , NguoiSua = @nguoiDungId, NgaySua = GETDATE()
			WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0;
			
			IF (@lyDo <> '')
				BEGIN
					UPDATE dbo.BCDT_KeHoach_TongHop 
					SET LyDo = @lyDo 
					WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0;
				END
		END
	IF (@isTongHop = 0 AND EXISTS(SELECT 1 FROM dbo.BCDT_KeHoach_TongHop WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0 AND TrangThai = @trangThaiChoLDDuyet))
		BEGIN
			UPDATE dbo.BCDT_KeHoach_TongHop 
			SET TrangThai = @trangThai , NguoiSua = @nguoiDungId, NgaySua = GETDATE() 
			WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0;			
			IF (@lyDo <> '')
				BEGIN
					UPDATE dbo.BCDT_KeHoach_TongHop 
					SET LyDo = @lyDo 
					WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0;
				END
		END
	IF (@isTongHop = 2 AND EXISTS(SELECT 1 FROM dbo.BCDT_KeHoach_TongHop WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0 AND TrangThai IN (@trangThaiGuiTH, @trangThaiGuiBo, @trangThaiDaTiepNhanDangThamDinh)))
		BEGIN
			UPDATE dbo.BCDT_KeHoach_TongHop 
			SET TrangThai = @trangThai , NguoiSua = @nguoiDungId, NgaySua = GETDATE(), LyDo = CASE WHEN @lyDo <> '' THEN @lyDo ELSE LyDo END
			WHERE KeHoachId = @keHoachId AND BieuMauId = @bieuMauId AND BitDaXoa = 0 AND TrangThai IN (@trangThaiGuiBo, @trangThaiDaTiepNhanDangThamDinh);			
		END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_GetBieuMau_ByMa]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description:	get thong tin bieu mau theo ma
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_GetBieuMau_ByMa]
	@maBieuMau NVARCHAR(50)
AS
BEGIN
	SELECT
		Id,
		MaBieuMau,
		TenBieuMau,
		TenVietTat,
		TenBieuThamDinh,
		DongBatDau,
		BitHieuLuc,
		NguoiTao,
		NgayTao,
		NguoiSua,
		NgaySua,
		BitDaXoa 
	FROM dbo.BCDT_DanhMuc_BieuMau
	WHERE MaBieuMau = @maBieuMau
	AND BitDaXoa = 0 AND BitHieuLuc = 1
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_GetBieuMau_GetAll]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Lấy danh sách biểu mẫu - bcdt
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_GetBieuMau_GetAll]
AS
BEGIN
	SELECT  
		bm.Id AS BieuMauId,
		bm.MaBieuMau,
		bm.LoaiBieuMau,
		bm.TenBieuMau,  
		bm.TenVietTat,
		bm.TenBieuThamDinh,
		bm.BitThamDinh,
		bm.IsTongHop
	FROM dbo.BCDT_DanhMuc_BieuMau bm
	WHERE bm.BitDaXoa = 0 AND bm.BitHieuLuc = 1 AND IsTongHop = 0;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_GetBieuMau_GetAll_TongHop]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Lấy danh sách biểu mẫu - bcdt
-- =============================================
create   PROCEDURE [dbo].[sp_BCDT_GetBieuMau_GetAll_TongHop]
AS
BEGIN
	SELECT  
		bm.Id AS BieuMauId,
		bm.MaBieuMau,
		bm.TenBieuMau,  
		bm.TenVietTat,
		bm.TenBieuThamDinh,
		bm.BitThamDinh,
		bm.IsTongHop
	FROM dbo.BCDT_DanhMuc_BieuMau bm
	WHERE bm.BitDaXoa = 0 AND bm.BitHieuLuc = 1 AND IsTongHop = 1;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_GetDanhSachBaoCaoByDonVi]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 01/07/2025
-- =============================================
CREATE PROCEDURE [dbo].[sp_BCDT_GetDanhSachBaoCaoByDonVi]
	@keHoachId INT
AS
BEGIN
	SELECT 
		   th.Id,
		   th.KeHoachId,
           th.DonViId,
           th.BieuMauId,
		   bm.MaBieuMau,
		   (bm.MaBieuMau + ' - ' + bm.TenBieuMau) as TenBieuMau, 
           th.TrangThai,
           th.LyDo,
           th.NguoiTao,
           th.NgayTao,
           th.NguoiSua,
           th.NgaySua,
           th.BitDaXoa	
	FROM dbo.BCDT_KeHoach_TongHop th
	left join dbo.BCDT_DanhMuc_BieuMau bm on th.BieuMauId = bm.Id
	WHERE th.KeHoachId = @keHoachId 
	AND th.BitDaXoa = 0;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_GetFileDinhKemBieuMau]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 11/07/2025
-- Description:	Lấy danh sách file đính kèm biểu mẫu - lĩnh vực 
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_GetFileDinhKemBieuMau]
	@keHoachId INT,
	@maBieuMau nvarchar(50)
AS
BEGIN
	DECLARE @trangThai INT = 0, @bieuMauId INT = 0;
	SELECT @bieuMauId = Id FROM dbo.BCDT_DanhMuc_BieuMau WHERE MaBieuMau = @maBieuMau;
	SELECT @trangThai = TrangThai FROM dbo.BCDT_KeHoach_TongHop WHERE KeHoachId = @keHoachId and BieuMauId = @bieuMauId;

	SELECT
		dt.Id,
		dt.BieuMauId,
		@maBieuMau as MaBieuMau,
		@trangThai AS TrangThai,		
		(SELECT f.Id,
			f.FileName,
			f.FileExtend,
			f.FileSize,
			f.RootPath,
			f.IsSigned,
			f.NgayTao
		FROM dbo.FileDinhKem AS f 
		WHERE f.EntityName = REPLACE(REPLACE(LTRIM(RTRIM(@maBieuMau)), '.', ''), ' ', '') and f.EntityKey = @keHoachId and f.BitDaXoa = 0
		FOR JSON AUTO) AS FileDinhKem	
	FROM dbo.BCDT_DanhMuc_BieuMau bm
	left join dbo.BCDT_KeHoach_TongHop dt on bm.Id = dt.BieuMauId and dt.KeHoachId = @keHoachId and dt.BieuMauId = @bieuMauId AND dt.BitDaXoa = 0

	WHERE bm.MaBieuMau = @maBieuMau

END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_GetKeHoachTongHop]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
create PROCEDURE [dbo].[sp_BCDT_GetKeHoachTongHop]
	@keHoachId INT,
	@maBieuMau nvarchar(50)
AS
BEGIN
	SELECT
		th.Id,
        th.KeHoachId,
        th.DonViId,
        th.BieuMauId,
        th.TrangThai,
        th.NguoiTao,
        th.NgayTao,
        th.NguoiSua,
        th.NgaySua,
        th.BitDaXoa
	FROM BCDT_KeHoach_TongHop th
	WHERE th.BitDaXoa = 0
	AND th.KeHoachId = @keHoachId
	AND th.BieuMauId = (select Id from BCDT_DanhMuc_BieuMau where MaBieuMau = @maBieuMau and BitDaXoa = 0);
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_KeHoach_Dot_ByDonVi]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description: Get thông tin kế hoạch theo đơn vị
-- =============================================
CREATE PROCEDURE [dbo].[sp_BCDT_KeHoach_Dot_ByDonVi]
	@donViId INT,
	@dotKh INT
AS
BEGIN
DECLARE @entityName NVARCHAR(50) = 'BCDT_KeHoach';
	SELECT Id,
           DotId,
           DonViId,
           TrangThai,
           NguoiTao,
           NgayTao,
           NguoiSua,
           NgaySua,
           BitDaXoa,
		   (SELECT f.Id,
			f.FileName,
			f.FileExtend,
			f.FileSize,
			f.RootPath,
			f.IsSigned,
			f.NgayTao
		FROM dbo.FileDinhKem AS f 
		WHERE f.EntityName = @entityName and f.EntityKey = kh.Id and f.BitDaXoa = 0
		FOR JSON AUTO) AS FileDinhKem	
	FROM dbo.BCDT_KeHoach kh
	WHERE DonViId = @donViId
	AND DotId = @dotKh
	AND BitDaXoa = 0
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_KeHoach_Dot_GetAll]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 09/10/2025
-- Description:	Lấy danh sách đợt
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_KeHoach_Dot_GetAll]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

     SELECT 
        d.Id,
        d.NamKeHoach,
        d.LoaiDot,
        d.Quy,
        d.TyGia,
        d.TrangThai,
        d.NgayBatDau,
        d.NgayHetHan,
        d.NgayBatDauInt,
        d.NgayKetThucInt,
        d.BitDaXoa,
        TenDot = 
        CASE 
            WHEN d.LoaiDot = 3 THEN 
                CONCAT(N'6 tháng đầu năm - Năm ', d.NamKeHoach)

            WHEN d.LoaiDot = 4 THEN 
                CONCAT(N'6 tháng cuối năm - Năm ', d.NamKeHoach)

            WHEN d.LoaiDot = 1 AND d.Quy IS NOT NULL AND d.Quy > 0 THEN 
                CONCAT(N'Quý ', d.Quy, N' - Năm ', d.NamKeHoach)

            ELSE 
                CONCAT(N'Năm ', d.NamKeHoach)
        END
    FROM dbo.BCDT_KeHoach_Dot d
    WHERE d.BitDaXoa = 0 and d.TrangThai = 1001;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_KhoiTaoBieuMau]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*===============================================================================
  SP_BCDT_KhoiTaoBieuMau
  Mục đích  : Orchestrator khởi tạo biểu: Cấu trúc → Vị trí Excel → Công thức
  Phiên bản : 1.0 (2025-10-03)
  Gọi tới   :
    - SP_BCDT_TaoCauTrucBieuMau(@ContextParams)
    - SP_BCDT_TaoViTriExcel(@StartRow, @DataColumn)
    - SP_BCDT_TaoCongThuc(@ContextParams)
  Ghi chú   :
    - Mỗi SP con tự quản lý TRANSACTION của chính nó. SP này điều phối & bắt lỗi.
===============================================================================*/
CREATE     PROCEDURE [dbo].[SP_BCDT_KhoiTaoBieuMau]
    @BieuMauId     INT,
    @DonViId       INT,
    @KeHoachId     INT,
    @StartRow      INT          = 6,        -- Dòng dữ liệu đầu tiên trên template
    @DataColumn    NVARCHAR(5)  = N'C',     -- Neo cột mặc định (fallback)
    @ContextParams NVARCHAR(MAX) = NULL     -- JSON tham số runtime (filter & formula)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @t0 DATETIME2(3) = SYSDATETIME();

    BEGIN TRY
        PRINT REPLICATE('-',80);
        PRINT N'Khởi tạo biểu…';
        PRINT N'  BieuMauId=' + CAST(@BieuMauId AS NVARCHAR(20))
            + N', DonViId=' + CAST(@DonViId AS NVARCHAR(20))
            + N', KeHoachId=' + CAST(@KeHoachId AS NVARCHAR(20));
        PRINT N'  StartRow=' + CAST(@StartRow AS NVARCHAR(20))
            + N', DataColumn=' + ISNULL(@DataColumn,N'(null)');

        /*-----------------------------
          0) VALIDATE cơ bản
        -----------------------------*/
        IF NOT EXISTS (SELECT 1 FROM dbo.BCDT_DanhMuc_BieuMau WHERE Id=@BieuMauId AND BitHieuLuc=1 AND BitDaXoa=0)
            RAISERROR(N'Biểu mẫu không tồn tại/không hiệu lực.',16,1);

        IF NOT EXISTS (SELECT 1 FROM dbo.DM_DonViSuDung WHERE Id=@DonViId AND ISNULL(BitDaXoa,0)=0)
            RAISERROR(N'Đơn vị không tồn tại/không hiệu lực.',16,1);

        IF NOT EXISTS (SELECT 1 FROM dbo.BCDT_KeHoach WHERE Id=@KeHoachId AND DonViId=@DonViId AND BitDaXoa=0)
            RAISERROR(N'Kế hoạch không tồn tại/không khớp đơn vị.',16,1);

		--Set Conext mặc định theo ngày bắt đầu, ngày kết thúc của đợt kế hoạch và tỷ giá theo đợt kế hoạch nếu @ContextParams = NULL
		IF @ContextParams IS NULL
		BEGIN
			DECLARE @NgayBatDauInt INT, @NgayKetThucInt INT, @TyGia INT;
			SELECT TOP(1) @NgayBatDauInt = a.NgayBatDauInt, @NgayKetThucInt = a.NgayKetThucInt, @TyGia = a.TyGia FROM BCDT_KeHoach_Dot a join BCDT_KeHoach b on a.Id = b.DotId and b.Id = @KeHoachId and b.BitDaXoa = 0
			-- Dựng JSON mặc định. Nếu không tìm thấy đợt, các khóa vẫn hiện diện với NULL.
			SET @ContextParams = (
				SELECT
					@NgayBatDauInt  AS NgayBatDauInt,
					@NgayKetThucInt AS NgayKetThucInt,
					@TyGia          AS TyGia
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
			);
			PRINT @ContextParams;
		END

        IF @DataColumn IS NULL OR (
              @DataColumn NOT LIKE '[A-Za-z]'
          AND @DataColumn NOT LIKE '[A-Za-z][A-Za-z]'
          AND @DataColumn NOT LIKE '[A-Za-z][A-Za-z][A-Za-z]')
            RAISERROR(N'@DataColumn không hợp lệ (A..XFD).',16,1);
        SET @DataColumn = UPPER(@DataColumn);

        IF @ContextParams IS NOT NULL AND ISJSON(@ContextParams)=0
            RAISERROR(N'@ContextParams phải là JSON hợp lệ.',16,1);

        /*-----------------------------
          1) Tạo cấu trúc biểu (có Unified Filter)
        -----------------------------*/
        PRINT N'[1/3] Tạo cấu trúc biểu…';
        EXEC dbo.SP_BCDT_TaoCauTrucBieuMau
             @BieuMauId     = @BieuMauId,
             @DonViId       = @DonViId,
             @KeHoachId     = @KeHoachId,
             @ContextParams = @ContextParams;     -- truyền xuống để filter theo ngữ cảnh
        PRINT N'  -> OK';

        /*-----------------------------
          2) Tạo vị trí Excel (hàng/cột)
        -----------------------------*/
        PRINT N'[2/3] Tạo vị trí Excel…';
        EXEC dbo.SP_BCDT_TaoViTriExcel
             @BieuMauId  = @BieuMauId,
             @DonViId    = @DonViId,
             @KeHoachId  = @KeHoachId,
             @StartRow   = @StartRow,
             @DataColumn = @DataColumn;           -- neo mặc định; không chi phối ViTri_Cot công thức
        PRINT N'  -> OK';

        /*-----------------------------
          3) Sinh công thức Excel
             (ưu tiên ViTri_Cot -> TargetAddr theo thiết kế mới)
        -----------------------------*/
        PRINT N'[3/3] Sinh công thức Excel…';
        EXEC dbo.SP_BCDT_TaoCongThuc
             @BieuMauId     = @BieuMauId,
             @DonViId       = @DonViId,
             @KeHoachId     = @KeHoachId,
             @ContextParams = @ContextParams;     -- truyền xuống để thay [CONTEXT:...]
        PRINT N'  -> OK';

        /*-----------------------------
          4) Tóm tắt
        -----------------------------*/
        DECLARE
            @nStruct INT = (
                SELECT COUNT(*) FROM dbo.BCDT_CauTruc_BieuMau
                WHERE BieuMauId=@BieuMauId AND DonViId=@DonViId AND KeHoachId=@KeHoachId AND BitDaXoa=0
            ),
            @nPos INT = (
                SELECT COUNT(*) 
                FROM dbo.BCDT_CauTruc_BieuMau c
                JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel v ON v.CauTrucGUID=c.CauTrucGUID
                WHERE c.BieuMauId=@BieuMauId AND c.DonViId=@DonViId AND c.KeHoachId=@KeHoachId AND c.BitDaXoa=0
            ),
            @nF INT = (
                SELECT COUNT(*)
                FROM dbo.BCDT_CauTruc_BieuMau c
                JOIN dbo.BCDT_CauTruc_BieuMau_CongThuc f ON f.CauTrucGUID=c.CauTrucGUID
                WHERE c.BieuMauId=@BieuMauId AND c.DonViId=@DonViId AND c.KeHoachId=@KeHoachId AND c.BitDaXoa=0
            );

        SELECT
            BieuMauId=@BieuMauId, DonViId=@DonViId, KeHoachId=@KeHoachId,
            StartRow=@StartRow, DataColumn=@DataColumn,
            StructureCount=@nStruct, PositionCount=@nPos, FormulaCount=@nF,
            DurationMs = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());

        PRINT REPLICATE('-',80);
        PRINT N'HOÀN THÀNH. Thời gian (ms): '
            + CAST(DATEDIFF(MILLISECOND,@t0,SYSDATETIME()) AS NVARCHAR(20));

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(2048)=ERROR_MESSAGE(), @ErrSev INT=ERROR_SEVERITY(), @ErrSta INT=ERROR_STATE();
        PRINT REPLICATE('-',80);
        PRINT N'LỖI: ' + @ErrMsg;
        RAISERROR(@ErrMsg, @ErrSev, @ErrSta);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_KiemTraDieuKienLoc]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================================================
-- STORED PROCEDURE: SP_BCDT_KiemTraDieuKienLoc
-- Mục đích: Validate filter trước khi lưu vào database
-- Input: BoLocId, Operator, FilterValue, ValueSource
-- Output: @IsValid (1=Valid, 0=Invalid), @ErrorMessage (chi tiết lỗi)
-- =============================================================================
CREATE     PROCEDURE [dbo].[SP_BCDT_KiemTraDieuKienLoc]
    @BoLocId INT,                       -- ID loại filter cần validate
    @Operator NVARCHAR(20),                  -- Toán tử (=, IN, LIKE, etc.)
    @FilterValue NVARCHAR(1000),             -- Giá trị filter
    @ValueSource NVARCHAR(20),               -- Nguồn giá trị (STATIC, PARENT, CONTEXT)
    @IsValid BIT OUTPUT,                     -- OUTPUT: 1=Valid, 0=Invalid
    @ErrorMessage NVARCHAR(500) OUTPUT       -- OUTPUT: Chi tiết lỗi nếu invalid
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Khởi tạo giá trị mặc định
    SET @IsValid = 1;                        -- Mặc định là valid
    SET @ErrorMessage = '';                  -- Không có lỗi
    
    -- =============================================================================
    -- BƯỚC 1: KIỂM TRA ĐẦU VÀO CƠ BẢN
    -- =============================================================================
    PRINT '=== SP_BCDT_KiemTraDieuKienLoc: BƯỚC 1 - INPUT VALIDATION ===';
    
    -- Kiểm tra BoLocId tồn tại và active
    IF NOT EXISTS (
        SELECT 1 FROM BCDT_DanhMuc_BoLoc 
        WHERE Id = @BoLocId AND IsActive = 1
    )
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'BoLocId không tồn tại hoặc không active';
        PRINT ' BoLocId invalid: ' + CAST(@BoLocId AS NVARCHAR);
        RETURN;
    END
    ELSE
    BEGIN
        PRINT ' BoLocId valid: ' + CAST(@BoLocId AS NVARCHAR);
    END
    
    -- Kiểm tra Operator hợp lệ
    DECLARE @ValidOperators TABLE (Operator NVARCHAR(20));
    INSERT INTO @ValidOperators VALUES 
        ('='), ('!='), ('>'), ('<'), ('>='), ('<='), 
        ('IN'), ('LIKE'), ('BETWEEN'), ('IS'), ('IS NOT');
    
    IF NOT EXISTS (SELECT 1 FROM @ValidOperators WHERE Operator = @Operator)
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'Operator không hợp lệ: ' + @Operator;
        PRINT ' Operator invalid: ' + @Operator;
        RETURN;
    END
    ELSE
    BEGIN
        PRINT ' Operator valid: ' + @Operator;
    END
    
    -- Kiểm tra ValueSource hợp lệ
    IF @ValueSource NOT IN ('STATIC', 'PARENT', 'CONTEXT')
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'ValueSource không hợp lệ: ' + @ValueSource;
        PRINT ' ValueSource invalid: ' + @ValueSource;
        RETURN;
    END
    ELSE
    BEGIN
        PRINT ' ValueSource valid: ' + @ValueSource;
    END
    
    -- =============================================================================
    -- BƯỚC 2: KIỂM TRA BẢO MẬT (SECURITY VALIDATION)
    -- =============================================================================
    PRINT '=== SP_BCDT_KiemTraDieuKienLoc: BƯỚC 2 - SECURITY VALIDATION ===';
    
    -- Danh sách từ khóa nguy hiểm cần block
    DECLARE @DangerousKeywords TABLE (Keyword NVARCHAR(50));
    INSERT INTO @DangerousKeywords VALUES 
        ('DROP'), ('DELETE'), ('UPDATE'), ('INSERT'), ('ALTER'), ('CREATE'),
        ('EXEC'), ('EXECUTE'), ('SP_'), ('XP_'), ('OPENROWSET'), ('OPENDATASOURCE'),
        ('BULK'), ('BACKUP'), ('RESTORE'), ('SHUTDOWN'), ('DBCC');
    
    -- Kiểm tra FilterValue có chứa từ khóa nguy hiểm không
    DECLARE @Keyword NVARCHAR(50);
    DECLARE keyword_cursor CURSOR FOR
    SELECT Keyword FROM @DangerousKeywords;
    
    OPEN keyword_cursor;
    FETCH NEXT FROM keyword_cursor INTO @Keyword;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF CHARINDEX(UPPER(@Keyword), UPPER(@FilterValue)) > 0
        BEGIN
            SET @IsValid = 0;
            SET @ErrorMessage = 'FilterValue chứa từ khóa nguy hiểm: ' + @Keyword;
            PRINT ' Dangerous keyword found: ' + @Keyword;
            CLOSE keyword_cursor;
            DEALLOCATE keyword_cursor;
            RETURN;
        END
        
        FETCH NEXT FROM keyword_cursor INTO @Keyword;
    END
    
    CLOSE keyword_cursor;
    DEALLOCATE keyword_cursor;
    
    PRINT ' Security check passed: No dangerous keywords';
    
    -- =============================================================================
    -- BƯỚC 3: KIỂM TRA BUSINESS LOGIC
    -- =============================================================================
    PRINT '=== SP_BCDT_KiemTraDieuKienLoc: BƯỚC 3 - BUSINESS LOGIC VALIDATION ===';
    
    -- Lấy thông tin filter type để validate
    DECLARE @ColumnName NVARCHAR(100), @DataType NVARCHAR(20), @AllowedOperators NVARCHAR(200);
    
    SELECT 
        @ColumnName = ColumnName,
        @DataType = DataType,
        @AllowedOperators = AllowedOperators
    FROM BCDT_DanhMuc_BoLoc
    WHERE Id = @BoLocId;
    
    -- Kiểm tra column tồn tại trong bảng BCDT_DanhMuc_TieuChi
    DECLARE @ColumnExists INT = 0;
    SELECT @ColumnExists = COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'BCDT_DanhMuc_TieuChi' 
      AND COLUMN_NAME = @ColumnName;
    
    IF @ColumnExists = 0
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'Column không tồn tại trong bảng: ' + @ColumnName;
        PRINT ' Column not found: ' + @ColumnName;
        RETURN;
    END
    ELSE
    BEGIN
        PRINT ' Column exists: ' + @ColumnName;
    END
    
    -- Kiểm tra operator có được phép cho loại filter này không
    IF CHARINDEX(@Operator, @AllowedOperators) = 0
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'Operator không được phép cho filter này. Allowed: ' + @AllowedOperators;
        PRINT ' Operator not allowed: ' + @Operator + ' (Allowed: ' + @AllowedOperators + ')';
        RETURN;
    END
    ELSE
    BEGIN
        PRINT ' Operator allowed: ' + @Operator;
    END
    
    -- Validate FilterValue theo DataType
    IF @ValueSource = 'STATIC' AND @FilterValue IS NOT NULL
    BEGIN
        -- Validate theo kiểu dữ liệu
        IF @DataType = 'INT'
        BEGIN
            IF ISNUMERIC(@FilterValue) = 0
            BEGIN
                SET @IsValid = 0;
                SET @ErrorMessage = 'FilterValue phải là số nguyên cho kiểu INT';
                PRINT ' FilterValue must be integer for INT type';
                RETURN;
            END
        END
        ELSE IF @DataType = 'NVARCHAR'
        BEGIN
            -- NVARCHAR chấp nhận mọi giá trị
            PRINT ' NVARCHAR accepts any value';
        END
        ELSE IF @DataType = 'BIT'
        BEGIN
            IF @FilterValue NOT IN ('0', '1', 'true', 'false', 'TRUE', 'FALSE')
            BEGIN
                SET @IsValid = 0;
                SET @ErrorMessage = 'FilterValue phải là 0/1 hoặc true/false cho kiểu BIT';
                PRINT ' FilterValue must be 0/1 or true/false for BIT type';
                RETURN;
            END
        END
        ELSE IF @DataType = 'SQL'
        BEGIN
            -- SQL type cần kiểm tra cú pháp cơ bản
            IF CHARINDEX(';', @FilterValue) > 0
            BEGIN
                SET @IsValid = 0;
                SET @ErrorMessage = 'SQL FilterValue không được chứa dấu chấm phẩy';
                PRINT ' SQL FilterValue cannot contain semicolon';
                RETURN;
            END
        END
        
        PRINT ' FilterValue valid for data type: ' + @DataType;
    END
    
    -- =============================================================================
    -- BƯỚC 4: KIỂM TRA CÚ PHÁP WHERE CLAUSE (SYNTAX VALIDATION)
    -- =============================================================================
    PRINT '=== SP_BCDT_KiemTraDieuKienLoc: BƯỚC 4 - SYNTAX VALIDATION ===';
    
    -- Tạo sample WHERE clause để kiểm tra cú pháp
    DECLARE @SampleWhereClause NVARCHAR(1000);
    
    -- Xử lý giá trị NULL
    IF @FilterValue IS NULL OR @FilterValue = 'NULL'
    BEGIN
        IF @Operator = '='
            SET @SampleWhereClause = @ColumnName + ' IS NULL';
        ELSE IF @Operator = '!='
            SET @SampleWhereClause = @ColumnName + ' IS NOT NULL';
        ELSE
            SET @SampleWhereClause = '1=0'; -- Invalid cho toán tử khác với NULL
    END
    ELSE
    BEGIN
        -- Xử lý giá trị không NULL
        IF @Operator = 'IN'
        BEGIN
            -- Validate IN clause format (value1,value2,value3)
            IF CHARINDEX(',', @FilterValue) = 0
            BEGIN
                SET @IsValid = 0;
                SET @ErrorMessage = 'IN operator yêu cầu ít nhất 2 giá trị ngăn cách bởi dấu phẩy';
                PRINT ' IN operator requires comma-separated values';
                RETURN;
            END
            
            SET @SampleWhereClause = @ColumnName + ' IN (' + @FilterValue + ')';
        END
        ELSE IF @Operator = 'LIKE'
        BEGIN
            -- LIKE nên chứa ít nhất một ký tự wildcard
            IF CHARINDEX('%', @FilterValue) = 0 AND CHARINDEX('_', @FilterValue) = 0
            BEGIN
                PRINT '  LIKE pattern should contain wildcards (% or _)';
            END
            
            SET @SampleWhereClause = @ColumnName + ' LIKE ''' + @FilterValue + '''';
        END
        ELSE IF @Operator = 'BETWEEN'
        BEGIN
            -- BETWEEN yêu cầu đúng 2 giá trị
            DECLARE @BetweenParts INT;
            SELECT @BetweenParts = LEN(@FilterValue) - LEN(REPLACE(@FilterValue, ',', ''));
            
            IF @BetweenParts != 1
            BEGIN
                SET @IsValid = 0;
                SET @ErrorMessage = 'BETWEEN operator yêu cầu đúng 2 giá trị ngăn cách bởi dấu phẩy';
                PRINT ' BETWEEN operator requires exactly 2 comma-separated values';
                RETURN;
            END
            
            SET @SampleWhereClause = @ColumnName + ' BETWEEN ' + REPLACE(@FilterValue, ',', ' AND ');
        END
        ELSE
        BEGIN
            SET @SampleWhereClause = @ColumnName + ' ' + @Operator + ' ' + @FilterValue;
        END
    END
    
    -- Kiểm tra độ dài WHERE clause (không quá dài)
    IF LEN(@SampleWhereClause) > 1000
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'WHERE clause quá dài (>1000 ký tự)';
        PRINT ' WHERE clause too long: ' + CAST(LEN(@SampleWhereClause) AS NVARCHAR) + ' characters';
        RETURN;
    END
    
    PRINT ' Sample WHERE clause valid: ' + @SampleWhereClause;
    
    -- =============================================================================
    -- BƯỚC 5: KIỂM TRA CUỐI CÙNG
    -- =============================================================================
    PRINT '=== SP_BCDT_KiemTraDieuKienLoc: BƯỚC 5 - FINAL VALIDATION ===';
    
    -- Kiểm tra kết hợp Operator + DataType hợp lệ
    IF @DataType = 'INT' AND @Operator NOT IN ('=', '!=', '>', '<', '>=', '<=', 'IN', 'BETWEEN')
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'INT column chỉ hỗ trợ toán tử số học và IN/BETWEEN';
        PRINT ' INT column only supports arithmetic and IN/BETWEEN operators';
        RETURN;
    END
    
    IF @DataType = 'NVARCHAR' AND @Operator = 'BETWEEN'
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'NVARCHAR column không hỗ trợ BETWEEN operator';
        PRINT ' NVARCHAR column does not support BETWEEN operator';
        RETURN;
    END
    
    IF @DataType = 'BIT' AND @Operator NOT IN ('=', '!=')
    BEGIN
        SET @IsValid = 0;
        SET @ErrorMessage = 'BIT column chỉ hỗ trợ = và !=';
        PRINT ' BIT column only supports = and !=';
        RETURN;
    END
    
    PRINT ' Operator + DataType combination valid';
    
    -- =============================================================================
    -- KẾT QUẢ CUỐI CÙNG
    -- =============================================================================
    IF @IsValid = 1
    BEGIN
        SET @ErrorMessage = 'Filter is valid';
        PRINT ' VALIDATION PASSED: Filter is valid';
    END
    ELSE
    BEGIN
        PRINT ' VALIDATION FAILED: ' + @ErrorMessage;
    END
    
    PRINT '=== SP_BCDT_KiemTraDieuKienLoc COMPLETED ===';
    PRINT '';
    
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_KiemTraVaKhoiTaoBieuMau]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE   PROCEDURE [dbo].[sp_BCDT_KiemTraVaKhoiTaoBieuMau]
    @BieuMauId INT,
    @DonViId INT,
	@KeHoachId INT,
	@StartRow INT,
	@JsonContextParam NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Result TABLE
    (
        BieuMauId INT,
		DonViId INT,
		KeHoachId INT,
		StartRow INT,
		DataColumn NVarchar(5),
		StructureCount INT,
		PositionCount INT,
		FormulaCount INT,
		DurationMs INT
    );
	DROP TABLE IF EXISTS #temp_KeHoach_NoUpdate;
	SELECT DISTINCT KeHoachId, BieuMauId, DonViId INTO #temp_KeHoach_NoUpdate FROM BCDT_KeHoach_TongHop WHERE TrangThai <> 1000 --Khac trang thai dang cap nhat (1000) thi khong duoc cap nhat cau truc bieu mau
	if not exists(select 1 from BCDT_CauTruc_BieuMau where BieuMauId = @BieuMauId and DonViId = @DonViId and KeHoachId = @KeHoachId)
	begin
		INSERT INTO @Result
		   EXEC dbo.SP_BCDT_KhoiTaoBieuMau
		       @BieuMauId     = @BieuMauId,
		       @DonViId       = @DonViId,
		       @KeHoachId     = @KeHoachId,
		       @StartRow      = @StartRow,
		       @DataColumn    = N'C',
		       @ContextParams = @JsonContextParam;

		IF (SELECT COUNT(1) FROM @Result) > 0
		BEGIN
			SELECT 'OK' AS Status, COUNT(*) AS SoDong FROM @Result;
		END
		ELSE
		   BEGIN
		       SELECT 'NO_DATA' AS Status, 0 AS SoDong;
		   END
	end
	else
	begin
		if  
		(
		exists (select 1 from BCDT_ThayDoi_DanhMuc_TieuChi where BieuMauId = @BieuMauId and KeHoachId = @KeHoachId and DonViId = @DonViId and BitDaXoa = 0)
		AND
		not exists(select 1 from #temp_KeHoach_NoUpdate where BieuMauId = @BieuMauId and KeHoachId = @KeHoachId and DonViId = @DonViId)
		)
		BEGIN
			INSERT INTO @Result
		    EXEC dbo.SP_BCDT_KhoiTaoBieuMau
		        @BieuMauId     = @BieuMauId,
		        @DonViId       = @DonViId,
		        @KeHoachId     = @KeHoachId,
		        @StartRow      = @StartRow,
		        @DataColumn    = N'C',
		        @ContextParams = @JsonContextParam;

			IF (SELECT COUNT(1) FROM @Result) > 0
			BEGIN
				UPDATE BCDT_ThayDoi_DanhMuc_TieuChi set BitDaXoa = 1 where BieuMauId = @BieuMauId and KeHoachId = @KeHoachId and DonViId = @DonViId and BitDaXoa = 0;

				SELECT 'OK' AS Status, COUNT(*) AS SoDong FROM @Result;
			END
			ELSE
		    BEGIN
		        SELECT 'NO_DATA' AS Status, 0 AS SoDong;
		    END
		END
		ELSE
		BEGIN
		    SELECT 'SKIP' AS Status, 0 AS SoDong;
		END
	end
	DROP TABLE IF EXISTS #temp_KeHoach_NoUpdate;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_KiemTraVaKhoiTaoTrangThai]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
create   PROCEDURE [dbo].[sp_BCDT_KiemTraVaKhoiTaoTrangThai]
	@keHoachId INT,
	@maBieuMau NVARCHAR(50),
	@donViId INT,
	@nguoiDungId INT
AS
BEGIN
	declare @bieuMauId INT;
	select @bieuMauId = Id from BCDT_DanhMuc_BieuMau where MaBieuMau = @maBieuMau and BitDaXoa = 0;
	IF NOT EXISTS(SELECT 1 FROM dbo.BCDT_KeHoach_TongHop WHERE KeHoachId = @keHoachId and BieuMauId = @bieuMauId and DonViId = @donViId and BitDaXoa = 0)
		BEGIN
			insert into BCDT_KeHoach_TongHop(KeHoachId, DonViId, BieuMauId, TrangThai, NguoiTao, NgayTao)
			values(@keHoachId, @donViId, @bieuMauId, 1000, @nguoiDungId, getdate());
		END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_LayDanhSachBieuMauTiepNhan]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE PROCEDURE [dbo].[sp_BCDT_LayDanhSachBieuMauTiepNhan]
	@DonViId INT,
	@KeHoachId INT
AS
BEGIN
	DECLARE @trangThaiDaGuiBo INT = 1004;
	DECLARE @trangThaiLanhDaoTuChoi INT = 1005;
	SELECT 
		lvth.DonViId, 
		bm.MaBieuMau,
		(bm.MaBieuMau + ' - ' + bm.TenBieuMau) as TenBieuMau, 
		lvth.Id, 
		lvth.TrangThai, 
		bm.Id as BieuMauId, 
		lvth.KeHoachId, 
		lvth.NguoiSua, 
		nsd.Hoten, 
		lvth.NgaySua,
		lvth.LyDo
	FROM dbo.BCDT_KeHoach_TongHop lvth
		INNER JOIN dbo.BCDT_DanhMuc_BieuMau AS bm ON lvth.BieuMauId=bm.Id
		LEFT JOIN dbo.QT_NguoiSuDung AS nsd ON lvth.NguoiSua = nsd.ID
	WHERE 
		lvth.BitDaXoa = 0 
	AND lvth.DonViId = @DonViId 
	AND lvth.KeHoachId = @KeHoachId
	AND lvth.TrangThai >= @trangThaiDaGuiBo --Chỉ lấy trạng thái trừ đã gửi bộ trở đi
	AND lvth.TrangThai <> @trangThaiLanhDaoTuChoi --Không lấy trạng thái lãnh đạo từ chối
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BCDT_LayDanhSachDonViTiepNhan]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Datnt3
-- Create date: 08/07/2025
-- Description:	Lấy danh sách đơn vị gửi báo cáo
-- =============================================
CREATE PROCEDURE [dbo].[sp_BCDT_LayDanhSachDonViTiepNhan]
	@DotKeHoachId INT,
	@NguoiDungID INT
AS
BEGIN
	DECLARE @entityName NVARCHAR(50) = 'BCDT_KeHoach';
	DECLARE @trangThai INT = 1004;

	SELECT 
		dtth.Id,
		dtth.DonViId, 
		dv.TenDonVi, 
		dv.MaDonVi, 
		dtth.TrangThai, 
		dtth.LyDo, 
		dtth.NguoiSua, 
		dtth.NgaySua,
		 (SELECT f.Id,
			f.FileName,
			f.FileExtend,
			f.FileSize,
			f.RootPath,
			f.IsSigned,
			f.NgayTao
		FROM dbo.FileDinhKem AS f 
		WHERE f.EntityName = @entityName and f.EntityKey = dtth.Id and f.BitDaXoa = 0
		FOR JSON AUTO) AS FileDinhKem	
	FROM dbo.BCDT_KeHoach dtth
	INNER JOIN dbo.DM_DonViSuDung AS dv ON dtth.DonViId =  dv.ID AND dv.TrangThai = 1
	WHERE 
		dtth.BitDaXoa = 0 
		AND dtth.DotId = @DotKeHoachId 
		AND dtth.DonViId in (SELECT DonViID FROM dbo.fn_Chung_LayDonVi_TheoPhanQuyen(@NguoiDungID))
		AND dtth.TrangThai >= @trangThai
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_PrintMax]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[SP_BCDT_PrintMax]
			@s NVARCHAR(MAX)
		AS
		BEGIN
			DECLARE @i INT = 1, @n INT = LEN(@s);
			WHILE @i <= @n
			BEGIN
				PRINT SUBSTRING(@s, @i, 4000);
				SET @i += 4000;
			END
		END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_TaoCauTrucBieuMau]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		thiennd
-- Create date: 25/06/2025
-- Modified:    2025-10-01: Tích hợp Unified Filter System
-- Description:	Tạo cấu trúc chi tiết cho biểu mẫu tương ứng mỗi đơn vị
-- Version:     Tích hợp Unified Filter System (loại bỏ hardcoded logic)
-- 
-- LOGIC TỔNG QUAN:
-- 1. Xây dựng cấu trúc lý tưởng từ template (BCDT_Bieu_TieuChi)
-- 2. Đồng bộ GUID với dữ liệu hiện có để giữ tính nhất quán
-- 3. Sử dụng MERGE để cập nhật/thêm/xóa dữ liệu hiệu quả
-- 4. Tính toán lại các giá trị phụ thuộc (PathId, SoThuTu)
-- 5. Sử dụng TRANSACTION để đảm bảo tính toàn vẹn dữ liệu
-- 6. Lọc tiêu chí động bằng Unified Filter System (thông qua SP_BCDT_TaoDieuKienLoc)
-- =============================================
CREATE       PROCEDURE [dbo].[SP_BCDT_TaoCauTrucBieuMau]
    @BieuMauId INT,     -- ID của biểu mẫu cần tạo cấu trúc
    @DonViId INT,       -- ID của đơn vị
    @KeHoachId INT,      -- ID của kế hoạch
	@ContextParams NVARCHAR(MAX) = NULL -- Dùng cho bộ lọc khi truyền giá trị lọc khi khởi tạo
AS
BEGIN
    SET NOCOUNT ON;
    
	-- =========================================================================================
	-- BƯỚC 0: KIỂM TRA TÍNH HỢP LỆ CỦA CÁC THAM SỐ
	-- =========================================================================================
	-- Kiểm tra Biểu mẫu ID
	IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_DanhMuc_BieuMau] WHERE Id = @BieuMauId AND BitHieuLuc = 1 AND BitDaXoa = 0)
	BEGIN
		RAISERROR(N'Lỗi: Biểu mẫu với BieuMauId = %d không tồn tại, không có hiệu lực hoặc đã bị xóa.', 16, 1, @BieuMauId);
		RETURN; -- Dừng SP tại đây
	END

	-- Kiểm tra Đơn vị ID 
	IF NOT EXISTS (SELECT 1 FROM [dbo].[DM_DonViSuDung] WHERE Id = @DonViId AND ISNULL(BitDaXoa, 0) = 0)
	BEGIN
		RAISERROR(N'Lỗi: Đơn vị với DonViId = %d không tồn tại, không có hiệu lực hoặc đã bị xóa.', 16, 1, @DonViId);
		RETURN;
	END

	-- Kiểm tra Kế hoạch ID
	IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_KeHoach] WHERE Id = @KeHoachId AND DonViId = @DonViId AND BitDaXoa = 0)
	BEGIN
		RAISERROR(N'Lỗi: Kế hoạch với KeHoachId = %d không tồn tại, kế hoạch không khớp với đơn vị, không có hiệu lực hoặc đã bị xóa.', 16, 1, @KeHoachId);
		RETURN;
	END

    -- Khai báo biến cho error handling
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- =========================================================================================
        -- BƯỚC 1: XÂY DỰNG CẤU TRÚC LÝ TƯỞNG VÀO #NewStructure
        -- =========================================================================================
        
        -- Tạo bảng tạm chứa cấu trúc lý tưởng
        CREATE TABLE #NewStructure (
            TempId INT IDENTITY(1,1) PRIMARY KEY,           -- ID tạm để quản lý quan hệ cha-con
            TempCapChaId INT,                               -- ID cha tạm (tham chiếu TempId)
            BieuTieuChiId INT NULL,                         -- ID từ BCDT_Bieu_TieuChi (template node)
            TieuChiId INT NOT NULL,                         -- ID tiêu chí từ BCDT_DanhMuc_TieuChi
            SoThuTu INT,                                    -- Số thứ tự sắp xếp
            SoThuTuHienThi NVARCHAR(50),                   -- Số thứ tự hiển thị (1.1, 1.2, ...)
            MaTieuChi NVARCHAR(50),                        -- Mã tiêu chí
            TenTieuChi NVARCHAR(2000),                     -- Tên tiêu chí
            Style NVARCHAR(500),                           -- Style hiển thị (CSS)
            ThamChieuId INT,                               -- ID tham chiếu (nếu có)
            MaThamChieu NVARCHAR(100),                     -- Mã tham chiếu
            TenThamChieu NVARCHAR(2000),                   -- Tên tham chiếu
            LinhVucId INT,                                 -- ID lĩnh vực
            LaTieuChiThamDinh BIT,                         -- Có phải tiêu chí thẩm định không
            IsDynamic BIT NOT NULL,                        -- Cờ đánh dấu tiêu chí động (để tính SoThuTuHienThi)
            CauTrucGUID UNIQUEIDENTIFIER NULL,             -- GUID duy nhất cho mỗi node
            ParentCauTrucGUID UNIQUEIDENTIFIER NULL,       -- GUID của node cha
            DonViTinh NVARCHAR(100),                       -- Đơn vị tính
            LaTieuChiTongHop BIT,                           -- Có phải tiêu chí tổng hợp không
			SoThuTuBieuTieuChi INT,
			ColumnMerge NVARCHAR(200)
        );
        
        -- Tạo index cho bảng tạm để tăng tốc truy vấn
        CREATE NONCLUSTERED INDEX IX_NewStructure_TempCapChaId ON #NewStructure (TempCapChaId);
        CREATE NONCLUSTERED INDEX IX_NewStructure_TieuChiId ON #NewStructure (TieuChiId);
        CREATE NONCLUSTERED INDEX IX_NewStructure_BieuTieuChiId ON #NewStructure (BieuTieuChiId);

        -- Tạo Queue để duyệt cây theo chiều rộng (BFS - Breadth-First Search)
        CREATE TABLE #Queue (
            QueueId INT IDENTITY(1,1) PRIMARY KEY,         -- ID queue
            BieuTieuChiId INT NOT NULL,                    -- ID từ BCDT_Bieu_TieuChi
            OutputParentTempId INT,                        -- TempId của cha trong #NewStructure
            SortPath NVARCHAR(MAX) NOT NULL,                -- Đường dẫn sắp xếp để đảm bảo thứ tự
			SoThuTuBieuTieuChi INT,
			ColumnMerge NVARCHAR(200)
        );
        
        -- Khởi tạo Queue với các node gốc (không có cha)
        INSERT INTO #Queue (BieuTieuChiId, OutputParentTempId, SortPath, SoThuTuBieuTieuChi, ColumnMerge)
        SELECT Id, NULL, FORMAT(SoThuTu, 'D10'), ISNULL(SoThuTu, 0), ColumnMerge
        FROM BCDT_Bieu_TieuChi WITH (NOLOCK)
        WHERE BieuMauId = @BieuMauId AND CapChaId IS NULL AND BitDaXoa = 0 
        ORDER BY SoThuTu;

        -- Duyệt Queue cho đến khi hết
        DECLARE @CurrentQueueId INT, @FlagTempDynamicSoThuTuBieuTieuChi INT = 0;
        WHILE (SELECT COUNT(*) FROM #Queue) > 0
        BEGIN
			
            -- Lấy item đầu tiên theo thứ tự SortPath
            SELECT TOP 1 @CurrentQueueId = QueueId FROM #Queue ORDER BY SortPath, QueueId;
            
            -- Lấy thông tin từ Queue
            DECLARE @BieuTieuChiId INT, @OutputParentTempId INT, @CurrentSortPath NVARCHAR(MAX), @SoThuTuBieuTieuChi INT, @TempDynamicSoThuTuBieuTieuChi INT, @ColumnMerge NVARCHAR(200);
            SELECT @BieuTieuChiId = BieuTieuChiId, @OutputParentTempId = OutputParentTempId, @CurrentSortPath = SortPath, @SoThuTuBieuTieuChi = SoThuTuBieuTieuChi, @TempDynamicSoThuTuBieuTieuChi = SoThuTuBieuTieuChi, @ColumnMerge = ColumnMerge
            FROM #Queue WHERE QueueId = @CurrentQueueId;
            
            -- Xử lý tiêu chí cố định (TieuChiCoDinhId IS NOT NULL)
            IF EXISTS (
                SELECT 1 FROM BCDT_Bieu_TieuChi btc WITH (NOLOCK)
                WHERE btc.Id = @BieuTieuChiId AND btc.TieuChiCoDinhId IS NOT NULL
            )
            BEGIN
                DECLARE @SoThuTu_Fixed INT;
                DECLARE @GeneratedDisplayOrder_Fixed NVARCHAR(100);
                DECLARE @DisplayOrder_From_BTC NVARCHAR(50), @DisplayOrder_From_DMTC NVARCHAR(50), @CapChaCDId INT;

                -- Lấy thông tin số thứ tự hiển thị
                SELECT 
                    @SoThuTu_Fixed = btc.SoThuTu,
                    @DisplayOrder_From_BTC = btc.SoThuTuHienThi,
                    @DisplayOrder_From_DMTC = tc.SoThuTuHienThi,
					@CapChaCDId = btc.CapChaId
                FROM BCDT_Bieu_TieuChi btc WITH (NOLOCK)
                JOIN BCDT_DanhMuc_TieuChi tc WITH (NOLOCK) ON btc.TieuChiCoDinhId = tc.Id
                WHERE btc.Id = @BieuTieuChiId;
                
				IF @CapChaCDId IS NOT NULL AND EXISTS(SELECT 1 FROM BCDT_Bieu_TieuChi WITH (NOLOCK) WHERE Id = @CapChaCDId AND ThamChieuId IS NOT NULL)
				BEGIN
					SET @SoThuTuBieuTieuChi = @FlagTempDynamicSoThuTuBieuTieuChi; 
				END
				ELSE
				BEGIN
					SET @SoThuTuBieuTieuChi = @TempDynamicSoThuTuBieuTieuChi; 
				END

                -- Tính toán số thứ tự hiển thị
                SET @GeneratedDisplayOrder_Fixed = COALESCE(NULLIF(@DisplayOrder_From_BTC, ''), @DisplayOrder_From_DMTC);

                -- Nếu chưa có số thứ tự hiển thị, tự động tạo dựa trên cha
                IF @GeneratedDisplayOrder_Fixed IS NULL
                BEGIN
                    DECLARE @ParentDisplayOrder_Fixed NVARCHAR(50);
                    SELECT @ParentDisplayOrder_Fixed = SoThuTuHienThi FROM #NewStructure WHERE TempId = @OutputParentTempId;
                    
                    IF ISNULL(@ParentDisplayOrder_Fixed, '') = ''
                        SET @GeneratedDisplayOrder_Fixed = '' --CAST(@SoThuTu_Fixed AS NVARCHAR(10));
                    ELSE
                        SET @GeneratedDisplayOrder_Fixed = @ParentDisplayOrder_Fixed + '.' + CAST(@SoThuTu_Fixed AS NVARCHAR(10));
                END

                -- Thêm vào #NewStructure
                INSERT INTO #NewStructure(
                    TempCapChaId, BieuTieuChiId, TieuChiId, SoThuTu, SoThuTuHienThi, MaTieuChi, TenTieuChi, 
                    Style, ThamChieuId, MaThamChieu, TenThamChieu, LinhVucId, LaTieuChiThamDinh, DonViTinh, 
                    IsDynamic, LaTieuChiTongHop, SoThuTuBieuTieuChi, ColumnMerge
                )
                SELECT TOP(1) 
                    @OutputParentTempId,
                    @BieuTieuChiId,
                    btc.TieuChiCoDinhId, 
                    btc.SoThuTu, 
                    @GeneratedDisplayOrder_Fixed, 
                    tc.MaTieuChi, tc.TenTieuChi, btc.Style, ttc.ThamChieuId, th.MaThamChieu, th.TenThamChieu, 
                    tc.LinhVucId, btc.LaTieuChiThamDinh, 
                    COALESCE(NULLIF(btc.DonViTinh, ''), tc.DonViTinh), 
                    0,  -- IsDynamic = 0 (tiêu chí cố định)
                    ISNULL(btc.LaTieuChiTongHop, 0),
					@SoThuTuBieuTieuChi,
					@ColumnMerge
                FROM BCDT_Bieu_TieuChi btc WITH (NOLOCK)
                JOIN BCDT_DanhMuc_TieuChi tc WITH (NOLOCK) ON btc.TieuChiCoDinhId = tc.Id 
                LEFT JOIN BCDT_ThamChieu_TieuChi ttc WITH (NOLOCK) ON tc.Id = ttc.TieuChiId AND ttc.BitDaXoa = 0
                LEFT JOIN BCDT_DanhMuc_ThamChieu th WITH (NOLOCK) ON ttc.ThamChieuId = th.Id
                WHERE btc.Id = @BieuTieuChiId;
                
                -- Lấy ID của record vừa thêm để làm cha cho các con
                DECLARE @NewOutputTempId INT = SCOPE_IDENTITY();
                
                -- Thêm các con của tiêu chí hiện tại vào Queue
                INSERT INTO #Queue (BieuTieuChiId, OutputParentTempId, SortPath, SoThuTuBieuTieuChi, ColumnMerge)
                SELECT Id, @NewOutputTempId, @CurrentSortPath + '.' + FORMAT(SoThuTu, 'D10'), @SoThuTuBieuTieuChi, ColumnMerge
                FROM BCDT_Bieu_TieuChi WITH (NOLOCK)
                WHERE BieuMauId = @BieuMauId AND CapChaId = @BieuTieuChiId AND BitDaXoa = 0 
                ORDER BY SoThuTu;
            END
            -- Xử lý tiêu chí động (ThamChieuId IS NOT NULL)
            ELSE IF EXISTS (
                SELECT 1 FROM BCDT_Bieu_TieuChi btc WITH (NOLOCK)
                WHERE btc.Id = @BieuTieuChiId AND btc.ThamChieuId IS NOT NULL
            )
            BEGIN
                -- Lấy thông tin tham chiếu
                DECLARE @MaThamChieu_Dynamic NVARCHAR(100), @IdThamChieu_Dynamic INT, @DoSauDeQuy INT, @PlaceholderStyle NVARCHAR(500), @PlaceholderLaTieuChiThamDinh BIT, @TempSoThuTu INT, @TempSoThuTuBieuTieuChi INT, @CapChaId INT, @ColumnMerge_Dynamic NVARCHAR(200);
                				
                SELECT @MaThamChieu_Dynamic = MaThamChieu, @IdThamChieu_Dynamic = ThamChieuId , @DoSauDeQuy = DoSauDeQuy, @PlaceholderStyle = Style, @PlaceholderLaTieuChiThamDinh = LaTieuChiThamDinh, @TempSoThuTu = SoThuTu, @TempSoThuTuBieuTieuChi = SoThuTu, @CapChaId = CapChaId, @ColumnMerge_Dynamic = ColumnMerge
                FROM BCDT_Bieu_TieuChi WITH (NOLOCK) WHERE Id = @BieuTieuChiId;

				--PRINT '@CapChaId: '+CAST(@CapChaId as nvarchar(100)) +' - @BieuTieuChiId: '+CAST(@BieuTieuChiId as nvarchar(100))

				--PRINT '@SoThuTuBieuTieuChi 1 : '+CAST(@TempSoThuTuBieuTieuChi as nvarchar(100))

				-- Kiểm tra xem bản ghi tham chiếu này có cấp cha không, nếu có thì lấy số thứ tự của cấp cha để làm @TempSoThuTuBieuTieuChi thay vì lấy trực tiếp số thứ tự của tham chiếu
				IF @CapChaId IS NOT NULL
				BEGIN
					SET @TempSoThuTuBieuTieuChi = (SELECT SoThuTu FROM BCDT_Bieu_TieuChi WITH (NOLOCK) WHERE Id = @CapChaId); 
				END
				--PRINT '@SoThuTuBieuTieuChi 2 : '+CAST(@TempSoThuTuBieuTieuChi as nvarchar(100))

				--Lay so thu tu cho con co dinh vong lap tiep theo (do cuoi vong lap se xoa item cha)
				SET @FlagTempDynamicSoThuTuBieuTieuChi = @TempSoThuTuBieuTieuChi;

                -- Sử dụng SP_BCDT_TaoDieuKienLoc thay vì hardcoded logic
				DECLARE @ParentTieuChiId INT = NULL;
				IF @OutputParentTempId IS NOT NULL
					SELECT @ParentTieuChiId = TieuChiId 
					FROM #NewStructure 
					WHERE TempId = @OutputParentTempId;
                DECLARE @FilterClause NVARCHAR(MAX);
                EXEC SP_BCDT_TaoDieuKienLoc
                    @BieuMauId = @BieuMauId,
                    @ThamChieuId = @IdThamChieu_Dynamic,
					@BieuTieuChiId   = @BieuTieuChiId,
                    @ParentTieuChiId = @ParentTieuChiId,
					@ContextParams = @ContextParams,
                    @FilterClause = @FilterClause OUTPUT;
				
				DECLARE @FilterClause_Recursive nvarchar(max) = REPLACE(@FilterClause, 'tc.', 'child.');
                -- Sử dụng Dynamic SQL để nhúng filter clause an toàn
				CREATE TABLE #DynamicSubTree (Id INT, CapChaId INT, SoThuTu INT, TieuChiId INT, MaTieuChi NVARCHAR(50), TenTieuChi NVARCHAR(2000), Style NVARCHAR(500), ThamChieuId INT, MaThamChieu NVARCHAR(100), TenThamChieu NVARCHAR(2000), LinhVucId INT, LaTieuChiThamDinh BIT, Level INT, SubSortPath NVARCHAR(MAX), DonViTinh NVARCHAR(100), LaTieuChiTongHop BIT, SoThuTuBieuTieuChi INT, ColumnMerge_Dynamic NVARCHAR(200));
                DECLARE @CTESql NVARCHAR(MAX) = '
                WITH OptimizedDynamicTreeCTE AS (
                    -- Anchor: Lay cac node goc (CapChaId IS NULL)
					-- AND tc.BitHieuLuc = 1 bo check hieu luc (V25GFX02223-112)
                    SELECT 
                        tc.Id, tc.CapChaId, 
                        (@TempSoThuTu - 1) + ROW_NUMBER() OVER(PARTITION BY tc.CapChaId, tc.LinhVucId ORDER BY tc.SoThuTu, tc.Id) AS SoThuTu, 
                        tc.Id AS TieuChiId, tc.MaTieuChi, tc.TenTieuChi, @PlaceholderStyle AS Style, 
                        ttc.ThamChieuId, th.MaThamChieu, th.TenThamChieu, tc.LinhVucId, @PlaceholderLaTieuChiThamDinh AS LaTieuChiThamDinh, 
                        1 AS Level, CAST(FORMAT(tc.SoThuTu, ''D10'') AS NVARCHAR(MAX)) AS SubSortPath, 
                        tc.DonViTinh as DonViTinh, tc.LaTieuChiTongHop, @TempSoThuTuBieuTieuChi AS SoThuTuBieuTieuChi, @ColumnMerge_Dynamic AS ColumnMerge_Dynamic
                    FROM BCDT_DanhMuc_TieuChi tc WITH (NOLOCK)
                    JOIN BCDT_ThamChieu_TieuChi ttc WITH (NOLOCK) ON tc.Id = ttc.TieuChiId AND ttc.BitDaXoa = 0
                    JOIN BCDT_DanhMuc_ThamChieu th WITH (NOLOCK) ON ttc.ThamChieuId = th.Id
                    WHERE ttc.ThamChieuId = @IdThamChieu_Dynamic 
                      AND tc.CapChaId IS NULL 
                      AND (tc.DonViId = @DonViId OR tc.DonViId IS NULL)
                      AND tc.BitDaXoa = 0 
                      AND (' + @FilterClause + ')
                    
                    UNION ALL
                    
                    -- Recursive: Lay cac node con
					-- AND child.BitHieuLuc = 1 (V25GFX02223-112)
                    SELECT 
                        child.Id, child.CapChaId, NULL AS SoThuTu, child.Id AS TieuChiId, child.MaTieuChi, child.TenTieuChi, 
                        parent.Style, ttc_child.ThamChieuId, th_child.MaThamChieu, th_child.TenThamChieu, 
                        child.LinhVucId, parent.LaTieuChiThamDinh, parent.Level + 1 AS Level, 
                        CAST(parent.SubSortPath + ''.'' + FORMAT(child.SoThuTu, ''D10'') AS NVARCHAR(MAX)) AS SubSortPath, 
                        child.DonViTinh as DonViTinh, child.LaTieuChiTongHop, @TempSoThuTuBieuTieuChi AS SoThuTuBieuTieuChi, @ColumnMerge_Dynamic AS ColumnMerge_Dynamic
                    FROM BCDT_DanhMuc_TieuChi child WITH (NOLOCK)
                    JOIN OptimizedDynamicTreeCTE parent ON child.CapChaId = parent.Id
                    JOIN BCDT_ThamChieu_TieuChi ttc_child WITH (NOLOCK) ON child.Id = ttc_child.TieuChiId AND ttc_child.BitDaXoa = 0
                    JOIN BCDT_DanhMuc_ThamChieu th_child WITH (NOLOCK) ON ttc_child.ThamChieuId = th_child.Id
                    WHERE ttc_child.ThamChieuId = @IdThamChieu_Dynamic 
                      AND parent.Level < ISNULL(@DoSauDeQuy, 10)
                      AND child.BitDaXoa = 0
                      AND (' + @FilterClause_Recursive + ')
                )
                -- save to CTE
                INSERT INTO #DynamicSubTree
                SELECT * FROM OptimizedDynamicTreeCTE ORDER BY SubSortPath, Id OPTION(RECOMPILE);';
				
				---- DEBUG: EXEC sp_executesql
				--DECLARE @ParamDef nvarchar(4000) = 
				--	N'@IdThamChieu_Dynamic INT, @DonViId INT, @TempSoThuTu INT, @PlaceholderStyle NVARCHAR(500), @PlaceholderLaTieuChiThamDinh BIT, @DoSauDeQuy INT';

				--DECLARE @ExecText nvarchar(max) =
				--	N'EXEC sys.sp_executesql ' + CHAR(10) +
				--	N'   N''' + REPLACE(@CTESql, '''', '''''') + N''',' + CHAR(10) +
				--	N'   N''' + REPLACE(@ParamDef, '''', '''''') + N''',' + CHAR(10) +
				--	N'   @IdThamChieu_Dynamic=' + CAST(@IdThamChieu_Dynamic AS nvarchar(20)) + N',' + CHAR(10) +
				--	N'   @DonViId=' + CAST(@DonViId AS nvarchar(20)) + N',' + CHAR(10) +
				--	N'   @TempSoThuTu=' + CAST(@TempSoThuTu AS nvarchar(20)) + N',' + CHAR(10) +
				--	N'   @PlaceholderStyle=N''' + REPLACE(ISNULL(@PlaceholderStyle,N''), '''', '''''') + N''',' + CHAR(10) +
				--	N'   @PlaceholderLaTieuChiThamDinh=' + CAST(ISNULL(@PlaceholderLaTieuChiThamDinh,0) AS nvarchar(1)) + N',' + CHAR(10) +
				--	N'   @DoSauDeQuy=' + CASE WHEN @DoSauDeQuy IS NULL THEN N'NULL' ELSE CAST(@DoSauDeQuy AS nvarchar(20)) END + N';';

				--DECLARE @p int = 1, @part nvarchar(4000);
				--WHILE @p <= LEN(@ExecText)
				--BEGIN
				--	SET @part = SUBSTRING(@ExecText, @p, 4000);
				--	PRINT @part;
				--	SET @p += 4000;
				--END
				---- END DEBUG: EXEC sp_executesql

                -- Execute CTE với Dynamic SQL và parameters
                EXEC sp_executesql @CTESql, 
                    N'@IdThamChieu_Dynamic INT, @DonViId INT, @TempSoThuTu INT, @PlaceholderStyle NVARCHAR(500), @PlaceholderLaTieuChiThamDinh BIT, @DoSauDeQuy INT, @TempSoThuTuBieuTieuChi INT, @ColumnMerge_Dynamic NVARCHAR(200)',
                    @IdThamChieu_Dynamic, @DonViId, @TempSoThuTu, @PlaceholderStyle, @PlaceholderLaTieuChiThamDinh, @DoSauDeQuy, @TempSoThuTuBieuTieuChi, @ColumnMerge_Dynamic;

                -- Xử lý từng node trong cây con
                DECLARE @ParentTempId INT = @OutputParentTempId;
                DECLARE @SubTreeTieuChiId INT, @SubTreeCapChaId INT, @SubTreeSoThuTu INT;
                DECLARE @SubTreeMaTieuChi NVARCHAR(50), @SubTreeTenTieuChi NVARCHAR(2000), @SubTreeStyle NVARCHAR(500);
                DECLARE @SubTreeThamChieuId INT, @SubTreeMaThamChieu NVARCHAR(100), @SubTreeTenThamChieu NVARCHAR(2000);
                DECLARE @SubTreeLinhVucId INT, @SubTreeLaTieuChiThamDinh BIT, @SubTreeDonViTinh NVARCHAR(100), @SubTreeLaTieuChiTongHop BIT;
                DECLARE @SubTreeSubSortPath NVARCHAR(MAX);
				DECLARE @SubSoThuTuBieuTieuChi INT;
				DECLARE @SubColumnMerge_Dynamic NVARCHAR(200);
                
                DECLARE subtree_cursor CURSOR FOR
                SELECT TieuChiId, CapChaId, SoThuTu, MaTieuChi, TenTieuChi, Style, ThamChieuId, MaThamChieu, TenThamChieu, LinhVucId, LaTieuChiThamDinh, DonViTinh, LaTieuChiTongHop, SubSortPath, SoThuTuBieuTieuChi, ColumnMerge_Dynamic
                FROM #DynamicSubTree ORDER BY SubSortPath;
                
                OPEN subtree_cursor;
                FETCH NEXT FROM subtree_cursor INTO @SubTreeTieuChiId, @SubTreeCapChaId, @SubTreeSoThuTu, @SubTreeMaTieuChi, @SubTreeTenTieuChi, @SubTreeStyle, @SubTreeThamChieuId, @SubTreeMaThamChieu, @SubTreeTenThamChieu, @SubTreeLinhVucId, @SubTreeLaTieuChiThamDinh, @SubTreeDonViTinh, @SubTreeLaTieuChiTongHop, @SubTreeSubSortPath, @SubSoThuTuBieuTieuChi, @SubColumnMerge_Dynamic;
                
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Xác định TempId của cha trong #NewStructure
                    DECLARE @CurrentParentTempId INT;
                    
                    IF @SubTreeCapChaId IS NULL
                        SET @CurrentParentTempId = @ParentTempId;
                    ELSE
                        -- Tìm cha trong các node đã thêm
                        SELECT @CurrentParentTempId = TempId FROM #NewStructure WHERE TieuChiId = @SubTreeCapChaId AND IsDynamic = 1;
                    
                    -- Thêm vào #NewStructure
                    INSERT INTO #NewStructure (
                        TempCapChaId, BieuTieuChiId, TieuChiId, SoThuTu, SoThuTuHienThi, MaTieuChi, TenTieuChi, 
                        Style, ThamChieuId, MaThamChieu, TenThamChieu, LinhVucId, LaTieuChiThamDinh, DonViTinh, 
                        IsDynamic, LaTieuChiTongHop, SoThuTuBieuTieuChi, ColumnMerge
                    )
                    VALUES (
                        @CurrentParentTempId, 
                        @BieuTieuChiId,
                        @SubTreeTieuChiId, 
                        @SubTreeSoThuTu, 
                        NULL,  -- SoThuTuHienThi sẽ tính sau
                        @SubTreeMaTieuChi, @SubTreeTenTieuChi, @SubTreeStyle, 
                        @SubTreeThamChieuId, @SubTreeMaThamChieu, @SubTreeTenThamChieu, 
                        @SubTreeLinhVucId, @SubTreeLaTieuChiThamDinh, @SubTreeDonViTinh, 
                        1,  -- IsDynamic = 1 (tiêu chí động)
                        ISNULL(@SubTreeLaTieuChiTongHop, 0),
						@SubSoThuTuBieuTieuChi,
						@SubColumnMerge_Dynamic
                    );
                    
                    FETCH NEXT FROM subtree_cursor INTO @SubTreeTieuChiId, @SubTreeCapChaId, @SubTreeSoThuTu, @SubTreeMaTieuChi, @SubTreeTenTieuChi, @SubTreeStyle, @SubTreeThamChieuId, @SubTreeMaThamChieu, @SubTreeTenThamChieu, @SubTreeLinhVucId, @SubTreeLaTieuChiThamDinh, @SubTreeDonViTinh, @SubTreeLaTieuChiTongHop, @SubTreeSubSortPath, @SubSoThuTuBieuTieuChi, @SubColumnMerge_Dynamic;
                END
                
                CLOSE subtree_cursor;
                DEALLOCATE subtree_cursor;

                -- Thêm các con của tiêu chí động vào Queue (chỉ cho các node lá)
                INSERT INTO #Queue (BieuTieuChiId, OutputParentTempId, SortPath, SoThuTuBieuTieuChi)
                SELECT btc.Id, ns.TempId, ISNULL(@CurrentSortPath + '.' + dst.SubSortPath + '.' + FORMAT(btc.SoThuTu, 'D10'), @CurrentSortPath + '.' + FORMAT(btc.SoThuTu, 'D10')), btc.SoThuTu
                FROM BCDT_Bieu_TieuChi btc WITH (NOLOCK)
                JOIN #DynamicSubTree dst ON 1=1
                JOIN #NewStructure ns ON ns.TieuChiId = dst.TieuChiId AND ns.IsDynamic = 1
                WHERE btc.CapChaId = @BieuTieuChiId AND btc.BitDaXoa = 0 
                  AND NOT EXISTS(SELECT 1 FROM #DynamicSubTree dst2 WHERE dst2.CapChaId = dst.TieuChiId)
                ORDER BY btc.SoThuTu;

                -- Dọn dẹp bảng tạm
                DROP TABLE #DynamicSubTree;
            END

            -- Xóa item đã xử lý khỏi Queue
            DELETE FROM #Queue WHERE QueueId = @CurrentQueueId;
        END;	

        -- TÍNH TOÁN SoThuTuHienThi CHO CÁC DÒNG ĐỘNG (IsDynamic = 1)
        WITH DisplayOrderCTE AS (
            -- Anchor: Lấy các node có SoThuTuHienThi sẵn (tiêu chí cố định)
            SELECT TempId, CAST(SoThuTuHienThi AS NVARCHAR(MAX)) AS CalculatedDisplayOrder
            FROM #NewStructure WHERE IsDynamic = 0 AND SoThuTuHienThi IS NOT NULL
            UNION ALL
            -- Recursive: Tính toán cho các node con
            SELECT child.TempId, CAST(parent.CalculatedDisplayOrder + '.' + CAST(child.SiblingOrder AS NVARCHAR(10)) AS NVARCHAR(MAX))
            FROM (
                -- Tính thứ tự anh em trong cùng cấp
                SELECT TempId, TempCapChaId, ISNULL(SoThuTu, ROW_NUMBER() OVER(PARTITION BY TempCapChaId, LinhVucId ORDER BY SoThuTu)) AS SiblingOrder
                FROM #NewStructure WHERE IsDynamic = 1
            ) child
            JOIN DisplayOrderCTE parent ON child.TempCapChaId = parent.TempId
        )
        -- Cập nhật SoThuTuHienThi cho các node động
        UPDATE ns SET ns.SoThuTuHienThi = REPLACE(REPLACE(cte.CalculatedDisplayOrder,'+.',''), '-.','')
        FROM #NewStructure ns JOIN DisplayOrderCTE cte ON ns.TempId = cte.TempId
        WHERE ns.IsDynamic = 1 OPTION (MAXRECURSION 0);

		--select * from #NewStructure

        -- =========================================================================================
        -- BƯỚC 2: ĐỒNG BỘ GUID
        -- =========================================================================================
        
        -- Tạo bảng tạm chứa cấu trúc hiện có
        CREATE TABLE #OldStructure (Id INT, TieuChiId INT, CauTrucGUID UNIQUEIDENTIFIER, ParentCauTrucGUID UNIQUEIDENTIFIER, BitDaXoa BIT, SoThuTuBieuTieuChi INT);
        
        -- Lấy dữ liệu cấu trúc hiện có từ database
        INSERT INTO #OldStructure (Id, TieuChiId, CauTrucGUID, ParentCauTrucGUID, BitDaXoa, SoThuTuBieuTieuChi)
        SELECT Id, TieuChiId, CauTrucGUID, ParentCauTrucGUID, BitDaXoa, SoThuTuBieuTieuChi 
        FROM BCDT_CauTruc_BieuMau WITH (NOLOCK)
        WHERE DonViId = @DonViId AND KeHoachId = @KeHoachId AND BieuMauId = @BieuMauId;

        -- Xử lý các node GỐC (level 0): Tìm GUID cũ dựa trên TieuChiId
        UPDATE new SET new.CauTrucGUID = old.CauTrucGUID 
        FROM #NewStructure new
        JOIN #OldStructure old ON new.TieuChiId = old.TieuChiId AND old.ParentCauTrucGUID IS NULL AND new.SoThuTuBieuTieuChi = old.SoThuTuBieuTieuChi
        WHERE new.TempCapChaId IS NULL;

        -- Tạo GUID mới cho các node gốc chưa có GUID
        UPDATE #NewStructure SET CauTrucGUID = NEWID() WHERE TempCapChaId IS NULL AND CauTrucGUID IS NULL;
		
        -- Xử lý các node con theo từng cấp
        DECLARE @MaxLevels INT = 10, @CurrentLevel INT = 0;
        WHILE EXISTS (SELECT 1 FROM #NewStructure WHERE CauTrucGUID IS NULL) AND @CurrentLevel < @MaxLevels
        BEGIN
            -- Bước 1: Cập nhật ParentCauTrucGUID cho các node con
            UPDATE child SET child.ParentCauTrucGUID = parent.CauTrucGUID 
            FROM #NewStructure child
            JOIN #NewStructure parent ON child.TempCapChaId = parent.TempId
            WHERE child.CauTrucGUID IS NULL AND parent.CauTrucGUID IS NOT NULL;
            
            -- Bước 2: Tìm GUID cũ dựa trên (ParentCauTrucGUID, TieuChiId)
            UPDATE new SET new.CauTrucGUID = old.CauTrucGUID 
            FROM #NewStructure new
            JOIN #OldStructure old ON new.TieuChiId = old.TieuChiId AND new.ParentCauTrucGUID = old.ParentCauTrucGUID AND new.SoThuTuBieuTieuChi = old.SoThuTuBieuTieuChi
            WHERE new.CauTrucGUID IS NULL AND new.ParentCauTrucGUID IS NOT NULL;

            -- Bước 3: Tạo GUID mới cho những node còn lại ở cấp này
            UPDATE #NewStructure SET CauTrucGUID = NEWID() WHERE CauTrucGUID IS NULL AND ParentCauTrucGUID IS NOT NULL;
            
            SET @CurrentLevel = @CurrentLevel + 1;
        END
        -- =========================================================================================
        -- BƯỚC 3: BULK OPERATIONS
        -- =========================================================================================
		--select * from #NewStructure
        -- Tạo bảng log để theo dõi các thay đổi
        CREATE TABLE #HistoryLog(HanhDong VARCHAR(10), CauTrucGUID UNIQUEIDENTIFIER);

		--select * from #NewStructure where ColumnMerge is not null

        -- BƯỚC 3.1: XỬ LÝ UPDATE
        UPDATE target SET 
            target.BieuTieuChiId = source.BieuTieuChiId,
            target.ParentCauTrucGUID = source.ParentCauTrucGUID,
            target.SoThuTu = source.SoThuTu,
            target.SoThuTuHienThi = source.SoThuTuHienThi,
            target.TenTieuChi = source.TenTieuChi,
            target.Style = source.Style,
            target.LaTieuChiThamDinh = source.LaTieuChiThamDinh,
            target.DonViTinh = source.DonViTinh,
            target.LaTieuChiTongHop = source.LaTieuChiTongHop,
            target.LinhVucId = source.LinhVucId,
            target.NgaySua = GETDATE(),
            target.BitDaXoa = 0,
			target.SoThuTuBieuTieuChi = source.SoThuTuBieuTieuChi,
			target.ColumnMerge = source.ColumnMerge
        FROM BCDT_CauTruc_BieuMau AS target
        JOIN #NewStructure AS source ON target.CauTrucGUID = source.CauTrucGUID
        WHERE (
            ISNULL(target.BieuTieuChiId, -1) <> ISNULL(source.BieuTieuChiId, -1)
            OR ISNULL(target.ParentCauTrucGUID, '00000000-0000-0000-0000-000000000000') <> ISNULL(source.ParentCauTrucGUID, '00000000-0000-0000-0000-000000000000')
            OR ISNULL(target.SoThuTu, -1) <> ISNULL(source.SoThuTu, -1)
            OR ISNULL(target.SoThuTuHienThi, '') <> ISNULL(source.SoThuTuHienThi, '')
            OR ISNULL(target.TenTieuChi, '') <> ISNULL(source.TenTieuChi, '')
            OR ISNULL(target.Style, '') <> ISNULL(source.Style, '')
            OR ISNULL(target.LaTieuChiThamDinh, 0) <> ISNULL(source.LaTieuChiThamDinh, 0)
            OR ISNULL(target.DonViTinh, '') <> ISNULL(source.DonViTinh, '')
            OR ISNULL(target.LaTieuChiTongHop, 0) <> ISNULL(source.LaTieuChiTongHop, 0)
            OR ISNULL(target.LinhVucId, -1) <> ISNULL(source.LinhVucId, -1)
			OR ISNULL(target.SoThuTuBieuTieuChi, 0) <> ISNULL(source.SoThuTuBieuTieuChi, 0)
			OR ISNULL(target.ColumnMerge, '') <> ISNULL(source.ColumnMerge, '')
            OR target.BitDaXoa = 1
        );

        -- Tạo bảng tạm chứa dữ liệu để insert/update
        CREATE TABLE #InsertData (
            OrderId INT IDENTITY(1,1) PRIMARY KEY,
            DonViId INT, KeHoachId INT, BieuMauId INT, MaBieuMau NVARCHAR(50),
            BieuTieuChiId INT,
            TieuChiId INT, MaTieuChi NVARCHAR(50), TenTieuChi NVARCHAR(2000),
            CauTrucGUID UNIQUEIDENTIFIER, ParentCauTrucGUID UNIQUEIDENTIFIER,
            SoThuTu INT, SoThuTuHienThi NVARCHAR(50), Style NVARCHAR(500),
            ThamChieuId INT, MaThamChieu NVARCHAR(100), TenThamChieu NVARCHAR(2000),
            LinhVucId INT, LaTieuChiThamDinh BIT, DonViTinh NVARCHAR(100), LaTieuChiTongHop BIT,
			SoThuTuBieuTieuChi INT, ColumnMerge NVARCHAR(200)
        );

        -- Chèn dữ liệu cần INSERT theo đúng thứ tự TempId
        INSERT INTO #InsertData (
            DonViId, KeHoachId, BieuMauId, MaBieuMau, 
            BieuTieuChiId,
            TieuChiId, MaTieuChi, TenTieuChi, 
            CauTrucGUID, ParentCauTrucGUID, SoThuTu, SoThuTuHienThi, Style, 
            ThamChieuId, MaThamChieu, TenThamChieu, 
            LinhVucId, LaTieuChiThamDinh, DonViTinh, LaTieuChiTongHop,
			SoThuTuBieuTieuChi, ColumnMerge
        )
        SELECT 
            @DonViId, @KeHoachId, @BieuMauId, 
            (SELECT MaBieuMau FROM BCDT_DanhMuc_BieuMau WHERE Id = @BieuMauId),
            source.BieuTieuChiId,
            source.TieuChiId, source.MaTieuChi, source.TenTieuChi,
            source.CauTrucGUID, source.ParentCauTrucGUID, source.SoThuTu, source.SoThuTuHienThi,
            source.Style, source.ThamChieuId, source.MaThamChieu, source.TenThamChieu,
            source.LinhVucId, source.LaTieuChiThamDinh, source.DonViTinh, source.LaTieuChiTongHop,
			source.SoThuTuBieuTieuChi, source.ColumnMerge
        FROM #NewStructure source
        WHERE NOT EXISTS (
            SELECT 1 FROM #OldStructure target 
            WHERE target.CauTrucGUID = source.CauTrucGUID
        )
        ORDER BY source.TempId;

        -- Insert dữ liệu mới
        INSERT INTO BCDT_CauTruc_BieuMau (
            DonViId, KeHoachId, BieuMauId, MaBieuMau, 
            BieuTieuChiId,
            TieuChiId, MaTieuChi, TenTieuChi,
            CauTrucGUID, ParentCauTrucGUID, SoThuTu, SoThuTuHienThi, Style,
            ThamChieuId, MaThamChieu, TenThamChieu, LinhVucId, LaTieuChiThamDinh,
            BitDaXoa, NgayTao, NgaySua, DonViTinh, LaTieuChiTongHop, SoThuTuBieuTieuChi, ColumnMerge
        )
        SELECT 
            DonViId, KeHoachId, BieuMauId, MaBieuMau, 
            BieuTieuChiId,
            TieuChiId, MaTieuChi, TenTieuChi,
            CauTrucGUID, ParentCauTrucGUID, SoThuTu, SoThuTuHienThi, Style,
            ThamChieuId, MaThamChieu, TenThamChieu, LinhVucId, LaTieuChiThamDinh,
            0, GETDATE(), GETDATE(), DonViTinh, LaTieuChiTongHop, SoThuTuBieuTieuChi, ColumnMerge
        FROM #InsertData 
        ORDER BY OrderId;

        -- BƯỚC 3.4: XỬ LÝ DELETE (Xóa mềm)
        UPDATE target SET target.BitDaXoa = 1, target.NgaySua = GETDATE()
        FROM BCDT_CauTruc_BieuMau AS target
        WHERE NOT EXISTS (SELECT 1 FROM #NewStructure source WHERE source.CauTrucGUID = target.CauTrucGUID)
          AND target.DonViId = @DonViId AND target.KeHoachId = @KeHoachId AND target.BieuMauId = @BieuMauId AND target.BitDaXoa = 0;

        -- Dọn dẹp
        DROP TABLE #InsertData;

        -- =========================================================================================
        -- BƯỚC 4: TÍNH TOÁN LẠI CÁC GIÁ TRỊ PHỤ THUỘC
        -- =========================================================================================
        
        -- Cập nhật CapChaId dựa trên ParentCauTrucGUID
        UPDATE child SET child.CapChaId = parent.Id 
        FROM BCDT_CauTruc_BieuMau child WITH (NOLOCK)
        JOIN BCDT_CauTruc_BieuMau parent WITH (NOLOCK) ON child.ParentCauTrucGUID = parent.CauTrucGUID
        WHERE child.DonViId = @DonViId AND child.KeHoachId = @KeHoachId AND child.BieuMauId = @BieuMauId;
        
        -- Đặt CapChaId = NULL cho các node gốc
        UPDATE BCDT_CauTruc_BieuMau SET CapChaId = NULL 
        WHERE ParentCauTrucGUID IS NULL AND DonViId = @DonViId AND KeHoachId = @KeHoachId AND BieuMauId = @BieuMauId;

        -- Tính toán PathId
        WITH PathCTE AS (
            -- Anchor: Các node gốc
            SELECT Id, CAST(FORMAT(Id, 'D10') AS NVARCHAR(MAX)) AS NewPath 
            FROM BCDT_CauTruc_BieuMau WITH (NOLOCK)
            WHERE CapChaId IS NULL AND DonViId = @DonViId AND KeHoachId = @KeHoachId AND BieuMauId = @BieuMauId AND BitDaXoa = 0
            UNION ALL
            -- Recursive: Các node con
            SELECT r.Id, CAST(cte.NewPath + '.' + FORMAT(r.Id, 'D10') AS NVARCHAR(MAX)) 
            FROM BCDT_CauTruc_BieuMau r WITH (NOLOCK)
            JOIN PathCTE cte ON r.CapChaId = cte.Id 
            WHERE r.BitDaXoa = 0
        )
        UPDATE ctb SET ctb.PathId = p.NewPath 
        FROM BCDT_CauTruc_BieuMau ctb 
        JOIN PathCTE p ON ctb.Id = p.Id 
        OPTION (MAXRECURSION 0);
        
        -- Tính toán lại SoThuTu cuối cùng
        WITH SortedFinal AS (
            SELECT Id, ROW_NUMBER() OVER (ORDER BY PathId) AS FinalSoThuTu 
            FROM BCDT_CauTruc_BieuMau WITH (NOLOCK)
            WHERE DonViId = @DonViId AND KeHoachId = @KeHoachId AND BieuMauId = @BieuMauId AND BitDaXoa = 0 AND PathId IS NOT NULL
        )
        UPDATE ctb SET ctb.SoThuTu = sf.FinalSoThuTu, ctb.SoThuTuHienThi = ISNULL(ctb.SoThuTuHienThi, CAST(ctb.SoThuTu as nvarchar(100))) 
        FROM BCDT_CauTruc_BieuMau ctb 
        JOIN SortedFinal sf ON ctb.Id = sf.Id;

        -- Dọn dẹp các bảng tạm
        DROP TABLE #NewStructure; 
        DROP TABLE #OldStructure; 
        DROP TABLE #Queue; 
        DROP TABLE #HistoryLog;

        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        -- Rollback nếu có lỗi
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Lấy thông tin lỗi
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
        
        -- Dọn dẹp bảng tạm nếu còn tồn tại
        IF OBJECT_ID('tempdb..#NewStructure') IS NOT NULL DROP TABLE #NewStructure;
        IF OBJECT_ID('tempdb..#OldStructure') IS NOT NULL DROP TABLE #OldStructure;
        IF OBJECT_ID('tempdb..#Queue') IS NOT NULL DROP TABLE #Queue;
        IF OBJECT_ID('tempdb..#HistoryLog') IS NOT NULL DROP TABLE #HistoryLog;
        IF OBJECT_ID('tempdb..#DynamicSubTree') IS NOT NULL DROP TABLE #DynamicSubTree;
        IF OBJECT_ID('tempdb..#InsertData') IS NOT NULL DROP TABLE #InsertData;
        
        -- Ném lại lỗi với thông tin chi tiết
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_TaoCongThuc]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================================================
-- STORED PROCEDURE: SP_BCDT_TaoCongThuc
-- Version:       1
-- Purpose:       Generates Excel formulas by parsing advanced formula templates.
-- Features:
--     Supports multi-column placeholders: {RELATIONSHIP:COLUMN}.
--     Supports conditional formulas (IF) via JSON templates.
--     Supports lookup formulas (VLOOKUP) via JSON templates.
--     Supports contextual parameters passed at runtime: [CONTEXT:ParamName].
--     Retains optimizations like SUM(range) for AUTO_DETECT_CHILDREN.
-- =============================================================================
CREATE     PROCEDURE [dbo].[SP_BCDT_TaoCongThuc]
    @BieuMauId     INT,
    @DonViId       INT,
    @KeHoachId     INT,
    @ContextParams NVARCHAR(MAX) = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

    BEGIN TRY
        BEGIN TRANSACTION;
        PRINT N'--- Bắt đầu SP_BCDT_TaoCongThuc ---';
		PRINT N'[0/4] XÓA KẾT QUẢ CŨ CHO NGỮ CẢNH NÀY.';

        DELETE FROM BCDT_CauTruc_BieuMau_CongThuc
        WHERE CauTrucGUID IN (
            SELECT CauTrucGUID
            FROM BCDT_CauTruc_BieuMau
            WHERE BieuMauId=@BieuMauId AND DonViId=@DonViId AND KeHoachId=@KeHoachId AND BitDaXoa=0
        );

        /*===============================================================        
		- Mở rộng TIÊU CHÍ: CROSS APPLY dbo.fn_BCDT_Scope_ExpandCriteria(...)
		- Mở rộng CỘT    : CROSS APPLY dbo.fn_BCDT_Scope_ExpandCols(...)
        - TargetCol:  cột đích ƯU TIÊN từ map.ViTri_Cot; nếu rỗng -> pos.ExcelColumn.
        - TargetAddr: TargetCol + ExcelRow (địa chỉ ô đích).
        ===============================================================*/
        CREATE TABLE #FormulaGeneration (
            Id               INT IDENTITY(1,1) PRIMARY KEY,
            CauTrucGUID      UNIQUEIDENTIFIER,
            BieuTieuChiId    INT,
            CongThucId       INT,
            LoaiCongThuc     NVARCHAR(50),
            CongThuc_Mau     NVARCHAR(MAX),
            ViTri_Cot        NVARCHAR(5),
            ExcelRow         INT,
            ParentCauTrucGUID UNIQUEIDENTIFIER,
            ChildrenCount    INT,
            TargetCol        NVARCHAR(5),
            TargetAddr       NVARCHAR(16),
            SheetName        NVARCHAR(128) NULL,
            CongThuc_Final   NVARCHAR(MAX),
			ScopeJson NVARCHAR(MAX) NULL
        );

        INSERT INTO #FormulaGeneration
        (
            CauTrucGUID, BieuTieuChiId, CongThucId, LoaiCongThuc, CongThuc_Mau,
            ViTri_Cot, ExcelRow, ParentCauTrucGUID, ChildrenCount, TargetCol, 
			TargetAddr, SheetName, ScopeJson
        )
        SELECT
            ctb.CauTrucGUID,
            ctb.BieuTieuChiId,
            lib.Id,
            lib.LoaiCongThuc,
            lib.CongThuc_Mau,
            UPPER(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), '')) AS ViTri_Cot,
            pos.ExcelRow,
            ctb.ParentCauTrucGUID,
            pos.ChildrenCount,
            -- TargetCol sau khi mở rộng theo JSON (fallback = map.ViTri_Cot hoặc pos.ExcelColumn)
			ca.Col AS TargetCol,
			-- TargetAddr = Col đã mở rộng + ExcelRow
			CONCAT(ca.Col, CAST(pos.ExcelRow AS NVARCHAR(10))) AS TargetAddr,
            NULLIF(map.SheetName, ''),  -- nếu bạn có cột SheetName trong map, giữ lại; nếu không có có thể bỏ
			map.ScopeJson
        FROM BCDT_Bieu_TieuChi_CongThuc map
		JOIN BCDT_DanhMuc_CongThuc lib
		  ON lib.Id = map.CongThucId
		 AND lib.IsActive = 1
		CROSS APPLY dbo.fn_BCDT_Scope_ExpandCriteria(
		  map.ScopeJson,
		  map.BieuTieuChiId,         -- tiêu chí mặc định của rule
		  @BieuMauId, @DonViId, @KeHoachId
		) sc
		JOIN BCDT_CauTruc_BieuMau ctb
		  ON ctb.BieuTieuChiId = sc.BieuTieuChiId
		 AND ctb.BieuMauId=@BieuMauId
		 AND ctb.DonViId=@DonViId
		 AND ctb.KeHoachId=@KeHoachId
		 AND ctb.BitDaXoa=0
		JOIN BCDT_CauTruc_BieuMau_ViTriExcel pos
		  ON pos.CauTrucGUID = ctb.CauTrucGUID
		CROSS APPLY dbo.fn_BCDT_Scope_ExpandCols(
		  map.ScopeJson,
		  UPPER(COALESCE(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), ''), NULLIF(LTRIM(RTRIM(pos.ExcelColumn)), '')))
		) ca
		WHERE map.IsActive = 1
		  AND map.BitDaXoa = 0;

        DECLARE @cnt INT = @@ROWCOUNT;
        PRINT N'[1/4] Chuẩn bị ' + CAST(@cnt AS NVARCHAR) + N' công thức.';

        /*===============================================================
          [1.1] VALIDATE: TargetCol phải hợp lệ (A..XFD)
        ===============================================================*/
        IF EXISTS (
            SELECT 1 FROM #FormulaGeneration
            WHERE (TargetCol IS NULL) OR (TargetCol NOT LIKE '[A-Za-z]' AND TargetCol NOT LIKE '[A-Za-z][A-Za-z]' AND TargetCol NOT LIKE '[A-Za-z][A-Za-z][A-Za-z]')
        )
        BEGIN
            RAISERROR (N'ViTri_Cot/TargetCol không hợp lệ (phải là A..XFD).', 16, 1);
        END

        /*===============================================================
          [2] TẠO CÔNG THỨC
        ===============================================================*/
        PRINT N'[2/4] Bắt đầu xử lý công thức...';

        DECLARE 
            @CurrentId INT,
            @CurrentGUID UNIQUEIDENTIFIER,
            @CongThucMau NVARCHAR(MAX),
            @LoaiCongThuc NVARCHAR(50),
            @ExcelRow INT,
            @ParentGUID UNIQUEIDENTIFIER,
            @GeneratedFormula NVARCHAR(MAX),
            @ProcessedFormula NVARCHAR(MAX),
            @CurrentCol NVARCHAR(5),
			@Flow TINYINT;  -- PATCH: state machine cho IF JSON (0: normal, 1: after condition, 2: after true, 3: after false)

        DECLARE formula_cursor CURSOR FOR
            SELECT Id, CauTrucGUID, CongThuc_Mau, LoaiCongThuc, ExcelRow, ParentCauTrucGUID, TargetCol
            FROM #FormulaGeneration ORDER BY Id;

        OPEN formula_cursor;
        FETCH NEXT FROM formula_cursor INTO @CurrentId, @CurrentGUID, @CongThucMau, @LoaiCongThuc, @ExcelRow, @ParentGUID, @CurrentCol;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @GeneratedFormula = NULL;
            SET @ProcessedFormula = @CongThucMau;
			SET @Flow = 0;  -- PATCH: init state

            /*-------------------- NHÁNH ĐẶC BIỆT ---------------------*/
            IF @LoaiCongThuc = 'AGGREGATE' AND @ProcessedFormula = 'AUTO_DETECT_CHILDREN' GOTO GenerateAutoSum;
            IF @LoaiCongThuc = 'CONDITIONAL' AND ISJSON(@ProcessedFormula) > 0       GOTO ProcessConditional;
            IF @LoaiCongThuc = 'LOOKUP'      AND ISJSON(@ProcessedFormula) > 0       GOTO ProcessLookup;
			IF @LoaiCongThuc = 'AGGREGATE'  AND ISJSON(@ProcessedFormula) = 1 AND JSON_VALUE(@ProcessedFormula, '$.type') = N'PARENTS_RANGE_SUM' GOTO ProcessAggregateJson;
			IF @LoaiCongThuc = 'CALCULATION' AND CHARINDEX('{{COLS_CHAIN}}', @ProcessedFormula) > 0 GOTO ProcessCalcColsChain;

            /*------------------ THAY PLACEHOLDER CHUNG ----------------*/
			ProcessCalcColsChain:
				DECLARE @scopeCC NVARCHAR(MAX), @chainCC NVARCHAR(MAX);
				SELECT @scopeCC = ScopeJson FROM #FormulaGeneration WHERE Id = @CurrentId;

				-- UDF tự đọc $.args.join_op (nếu có); nếu không có thì mặc định '-'
				SET @chainCC = dbo.fn_BCDT_RenderColsChain(@scopeCC, @CurrentCol, NULL);

				IF @chainCC IS NULL GOTO ProcessPlaceholders;

				SET @ProcessedFormula = REPLACE(@ProcessedFormula, '{{COLS_CHAIN}}', @chainCC);
				GOTO ProcessPlaceholders;
            ProcessPlaceholders:
				DECLARE 
					@placeholder NVARCHAR(500),
					@refType NVARCHAR(100),
					@refCol NVARCHAR(200),
					@start INT,
					@end INT,
					@split INT,
					@targetGUID UNIQUEIDENTIFIER,
					@targetRow INT;

				WHILE CHARINDEX('{', @ProcessedFormula) > 0
				BEGIN
					SET @start = CHARINDEX('{', @ProcessedFormula);
					SET @end   = CHARINDEX('}', @ProcessedFormula, @start);
					SET @placeholder = SUBSTRING(@ProcessedFormula, @start + 1, @end - @start - 1);
					SET @split = CHARINDEX(':', @placeholder);
					-- PATCH: placeholder an toàn khi thiếu dấu ':'
					IF @split = 0
					BEGIN
						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, '#BAD_PLACEHOLDER');
						CONTINUE;
					END

					SET @refType = LEFT(@placeholder, @split - 1);
					SET @refCol  = SUBSTRING(@placeholder, @split + 1, LEN(@placeholder));
					-- Chuẩn hoá macro cột hiện tại: COL / THIS_COL
					DECLARE @refColTrim NVARCHAR(200) = UPPER(LTRIM(RTRIM(@refCol)));
					IF @refColTrim IN ('COL', '{{COL}}', 'THIS_COL', '{{THIS_COL}}')
						SET @refCol = @CurrentCol;

					SET @targetGUID = NULL;
					SET @targetRow  = NULL;

					/* ====== ALIAS → AGG (gom tất cả tổng hợp theo cột) ====== */
					IF @refType IN ('ALL_ROWS_SUM','ALL_ROWS_AVG','ALL_ROWS_MAX','ALL_ROWS_MIN','ALL_ROWS_COUNT','ALL_ROWS_COUNTA','SIBLINGS_SUM')
					BEGIN
						DECLARE @AggFunc NVARCHAR(10) = CASE @refType
							WHEN 'ALL_ROWS_SUM'     THEN 'SUM'
							WHEN 'ALL_ROWS_AVG'     THEN 'AVG'
							WHEN 'ALL_ROWS_MAX'     THEN 'MAX'
							WHEN 'ALL_ROWS_MIN'     THEN 'MIN'
							WHEN 'ALL_ROWS_COUNT'   THEN 'COUNT'
							WHEN 'ALL_ROWS_COUNTA'  THEN 'COUNTA'
							WHEN 'SIBLINGS_SUM'     THEN 'SUM'
						END;

						DECLARE @AggScope NVARCHAR(10) =
								CASE 
									WHEN @refType LIKE 'SIBLINGS_%' THEN 'SIBLINGS'
									WHEN @refType LIKE 'ALL_ROWS_%' THEN 'ALL'
									ELSE 'ALL'
								END;

						DECLARE @refColAgg NVARCHAR(8) = @refCol;
						IF UPPER(LTRIM(RTRIM(@refColAgg))) IN ('COL','{{COL}}','THIS_COL','{{THIS_COL}}')
							SET @refColAgg = @CurrentCol;

						DECLARE @sheetAgg NVARCHAR(128);
						SELECT @sheetAgg = SheetName FROM #FormulaGeneration WHERE Id=@CurrentId;

						DECLARE @bodyAgg NVARCHAR(MAX) =
							dbo.fn_BCDT_RenderAgg(
								@BieuMauId,@DonViId,@KeHoachId,
								CASE WHEN @AggScope='SIBLINGS' THEN @ParentGUID ELSE NULL END,          -- cha của tổng
								@CurrentGUID,         -- chính dòng tổng
								@sheetAgg,@AggFunc,@AggScope,@refColAgg,
								1                     -- tham số loại trừ bản thân (giữ như bạn đang dùng)
							);

						-- Fallback nếu rỗng (tránh ra "0" cứng)
						IF NULLIF(@bodyAgg,'') IS NULL SET @bodyAgg = 'SUM(0)';

						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, @bodyAgg);
						CONTINUE;
					END

					/* ====== RANGE_TO_CURRENT: lũy kế từ hàng đầu tiên đến hàng hiện tại ====== */
					IF @refType='RANGE_TO_CURRENT'
					BEGIN
						DECLARE @refColRTC NVARCHAR(8) = @refCol;
						IF UPPER(LTRIM(RTRIM(@refColRTC))) IN ('COL','{{COL}}','THIS_COL','{{THIS_COL}}')
							SET @refColRTC = @CurrentCol;

						DECLARE @sheetRTC NVARCHAR(128); SELECT @sheetRTC = SheetName FROM #FormulaGeneration WHERE Id=@CurrentId;
						DECLARE @bodyRTC NVARCHAR(MAX) = dbo.fn_BCDT_RangeToCurrent(@BieuMauId,@DonViId,@KeHoachId,@sheetRTC,@refColRTC,@ExcelRow);

						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, @bodyRTC);
						CONTINUE;
					END

					/* ====== SIBLINGS_RANGE: tập ô của anh em cùng cấp (phục vụ RANK, MAX/AVG nhóm) ====== */
					IF @refType='SIBLINGS_RANGE'
					BEGIN
						DECLARE @refColSR NVARCHAR(8) = @refCol;
						IF UPPER(LTRIM(RTRIM(@refColSR))) IN ('COL','{{COL}}','THIS_COL','{{THIS_COL}}')
							SET @refColSR = @CurrentCol;

						DECLARE @sheetSR NVARCHAR(128); SELECT @sheetSR = SheetName FROM #FormulaGeneration WHERE Id=@CurrentId;
						DECLARE @rngSR NVARCHAR(MAX) = dbo.fn_BCDT_SiblingsRange(@BieuMauId,@DonViId,@KeHoachId,@ParentGUID,@sheetSR,@refColSR);

						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, @rngSR);
						CONTINUE;
					END

					-- CHILDREN_SUM:<COL> -> cộng từng con theo COL chỉ định
					IF @refType = 'CHILDREN_SUM'
					BEGIN
						DECLARE @sum_expr NVARCHAR(MAX);
						SELECT @sum_expr = STUFF((
							SELECT '+' + @refCol + CAST(pos.ExcelRow AS NVARCHAR(10))
							FROM BCDT_CauTruc_BieuMau ctb
							JOIN BCDT_CauTruc_BieuMau_ViTriExcel pos ON pos.CauTrucGUID = ctb.CauTrucGUID
							WHERE ctb.ParentCauTrucGUID = @CurrentGUID AND ctb.BitDaXoa=0
							ORDER BY pos.ExcelRow
							FOR XML PATH('')
						), 1, 1, '');

						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, ISNULL(@sum_expr, '0'));
						CONTINUE;
					END
					ELSE IF @refType LIKE 'SIBLING_%'
					BEGIN
						DECLARE @offset INT = TRY_CAST(REPLACE(@refType, 'SIBLING_', '') AS INT);

						SELECT TOP 1 @targetGUID = s.CauTrucGUID
						FROM BCDT_CauTruc_BieuMau s
						JOIN BCDT_CauTruc_BieuMau_ViTriExcel p ON p.CauTrucGUID = s.CauTrucGUID
						WHERE s.ParentCauTrucGUID = @ParentGUID AND s.BitDaXoa=0
						  AND ((@offset < 0 AND p.ExcelRow < @ExcelRow) OR (@offset > 0 AND p.ExcelRow > @ExcelRow))
						ORDER BY CASE WHEN @offset < 0 THEN p.ExcelRow END DESC,
								 CASE WHEN @offset > 0 THEN p.ExcelRow END ASC;
					END
					ELSE
					BEGIN
						IF @refType = 'CURRENT' SET @targetGUID = @CurrentGUID;
						IF @refType = 'PARENT'  SET @targetGUID = @ParentGUID;

						IF @refType LIKE 'TIEUCHI_%'
						BEGIN
							-- 1) Tách cột và option sau '@'
							DECLARE @col NVARCHAR(8) = @refCol;
							DECLARE @opt NVARCHAR(200) = NULL;

							IF CHARINDEX('@', @refCol) > 0
							BEGIN
								SET @opt = SUBSTRING(@refCol, CHARINDEX('@', @refCol) + 1, 200);
								SET @col = LEFT(@refCol, CHARINDEX('@', @refCol) - 1);
							END

							-- 1.1) Nếu @col là macro cột hiện tại => thay bằng @CurrentCol
							DECLARE @colTrim NVARCHAR(200) = UPPER(LTRIM(RTRIM(@col)));
							IF @colTrim IN ('COL', '{{COL}}', 'THIS_COL', '{{THIS_COL}}')
								SET @col = @CurrentCol;

							-- 2) Mặc định
							DECLARE @IndexN INT = 1;
							DECLARE @Scope NVARCHAR(20) = N'SAME_PARENT';
							DECLARE @ParentCode NVARCHAR(100) = NULL;

							-- 3) Parse option "INDEX=" và "SCOPE="
							IF @opt IS NOT NULL
							BEGIN
								DECLARE @p INT = 1, @semi INT, @tok NVARCHAR(200);
								WHILE @p <= LEN(@opt) + 1
								BEGIN
									SET @semi = CHARINDEX(';', @opt, @p);
									IF @semi = 0 SET @semi = LEN(@opt) + 1;

									SET @tok = LTRIM(RTRIM(SUBSTRING(@opt, @p, @semi - @p)));

									IF LEFT(@tok, 6) = N'INDEX='
										SET @IndexN = TRY_CAST(SUBSTRING(@tok, 7, 20) AS INT);

									IF LEFT(@tok, 6) = N'SCOPE='
									BEGIN
										-- Cho phép: SAME_PARENT | ANY | BY_PARENT_CODE:<MaCha>
										DECLARE @val NVARCHAR(150) = SUBSTRING(@tok, 7, 150);
										IF @val LIKE N'BY_PARENT_CODE:%'
										BEGIN
											SET @Scope = N'BY_PARENT_CODE';
											SET @ParentCode = SUBSTRING(@val, LEN('BY_PARENT_CODE:') + 1, 100);
										END
										ELSE
											SET @Scope = UPPER(@val);
									END

									SET @p = @semi + 1;
								END
							END

							-- 4) Lấy mã tiêu chí
							DECLARE @maTieuChi NVARCHAR(100) = REPLACE(@refType, 'TIEUCHI_', '');

							-- 5) Resolve row theo rule mới
							SET @targetRow = dbo.fn_BCDT_ResolveTieuChiRow_ByIndex(
								@BieuMauId, @DonViId, @KeHoachId,
								@maTieuChi,
								@ParentGUID,          -- SAME_PARENT dùng tham số này
								@Scope, @IndexN,
								@ParentCode           -- chỉ dùng khi BY_PARENT_CODE
							);
							--PRINT '@maTieuChi: ' + CAST(@maTieuChi as nvarchar(1000));
							--PRINT '@ParentGUID: ' +CAST(@ParentGUID as nvarchar(1000));
							--PRINT '@Scope: '+CAST(@Scope as nvarchar(1000));
							--PRINT '@IndexN: '+CAST(@IndexN as nvarchar(1000));
							--PRINT '@ParentCode: '+ CAST(@ParentCode as nvarchar(1000));
							--PRINT '@targetRow: '+CAST(@targetRow as nvarchar(100));

							-- 6) Thay placeholder hoặc #REF!
							IF @targetRow IS NOT NULL
								SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, @col + CAST(@targetRow AS NVARCHAR(10)));
							ELSE
								SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, '#REF!');

							CONTINUE; -- → chuyển sang placeholder tiếp theo (bỏ qua logic chung)
						END
					END

					IF @targetGUID IS NOT NULL
						SELECT @targetRow = ExcelRow FROM BCDT_CauTruc_BieuMau_ViTriExcel WHERE CauTrucGUID=@targetGUID;

					IF @targetRow IS NOT NULL
						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, @refCol + CAST(@targetRow AS NVARCHAR(10)));
					ELSE
						SET @ProcessedFormula = STUFF(@ProcessedFormula, @start, @end - @start + 1, '#REF!');
				END

				-- PATCH: Hoàn tất một lượt thay placeholder (điều phối theo state @Flow)
				IF @Flow = 1 GOTO AfterProcessPlaceholders_IF;       -- vừa xử lý condition
				IF @Flow = 2 GOTO AfterProcessPlaceholders_TRUE;     -- vừa xử lý true
				IF @Flow = 3 GOTO AfterProcessPlaceholders_FALSE;    -- vừa xử lý false
				IF @LoaiCongThuc = 'CONDITIONAL' GOTO AfterProcessPlaceholders_IF;  -- lần đầu với IF
				IF @LoaiCongThuc = 'LOOKUP'      GOTO AfterProcessPlaceholders_VLOOKUP;
				SET @GeneratedFormula = @ProcessedFormula;

				/*------------------ THAY [CONTEXT:...] --------------------*/
				IF @ContextParams IS NOT NULL AND ISJSON(@ContextParams) > 0 AND CHARINDEX('[', @GeneratedFormula) > 0
				BEGIN
					DECLARE @c_start INT, @c_end INT, @ctx NVARCHAR(200), @ctxVal NVARCHAR(MAX);
					WHILE CHARINDEX('[CONTEXT:', @GeneratedFormula) > 0
					BEGIN
						SET @c_start = CHARINDEX('[CONTEXT:', @GeneratedFormula);
						SET @c_end   = CHARINDEX(']', @GeneratedFormula, @c_start);
						SET @ctx     = SUBSTRING(@GeneratedFormula, @c_start + 9, @c_end - @c_start - 9);
						SET @ctxVal  = JSON_VALUE(@ContextParams, '$."' + @ctx + '"');
						SET @GeneratedFormula = STUFF(@GeneratedFormula, @c_start, @c_end - @c_start + 1, COALESCE(@ctxVal, '0'));
					END
				END
				GOTO EndOfProcessing;

            /*==================== NHÁNH JSON SPECIAL ===================*/
            ProcessConditional:
                DECLARE
                    @condition NVARCHAR(MAX) = JSON_VALUE(@ProcessedFormula, '$.condition'),
                    @true_val  NVARCHAR(MAX) = JSON_VALUE(@ProcessedFormula, '$.true'),
                    @false_val NVARCHAR(MAX) = JSON_VALUE(@ProcessedFormula, '$.false');

                -- PATCH: Pass 1 - condition
                SET @ProcessedFormula = @condition; 
                SET @Flow = 1;
                GOTO ProcessPlaceholders;

            AfterProcessPlaceholders_IF:
                -- PATCH: Sau Pass 1 - giữ lại condition đã thay
                SET @condition = @ProcessedFormula;

                -- PATCH: Pass 2 - true branch
                SET @ProcessedFormula = @true_val;  
                SET @Flow = 2;
                GOTO ProcessPlaceholders;

            AfterProcessPlaceholders_TRUE:
                -- PATCH: Sau Pass 2 - giữ lại true đã thay
                SET @true_val = @ProcessedFormula;

                -- PATCH: Pass 3 - false branch
                SET @ProcessedFormula = @false_val; 
                SET @Flow = 3;
                GOTO ProcessPlaceholders;

            AfterProcessPlaceholders_FALSE:
                -- PATCH: Sau Pass 3 - ghép IF hoàn chỉnh
                SET @false_val = @ProcessedFormula;

                SET @GeneratedFormula = '=IF(' + @condition + ',' + @true_val + ',' + @false_val + ')';
                GOTO EndOfProcessing;

            ProcessLookup:
                DECLARE
                    @lookup_val NVARCHAR(MAX) = JSON_VALUE(@ProcessedFormula, '$.value'),
                    @source     NVARCHAR(MAX) = JSON_VALUE(@ProcessedFormula, '$.source'),
                    @col_index  INT           = JSON_VALUE(@ProcessedFormula, '$.column'),
                    @match_type NVARCHAR(10)  = CASE WHEN JSON_VALUE(@ProcessedFormula, '$.match') = 'EXACT' THEN 'FALSE' ELSE 'TRUE' END;

                SET @ProcessedFormula = @lookup_val; 
				GOTO ProcessPlaceholders;

            AfterProcessPlaceholders_VLOOKUP:
                SET @lookup_val = @ProcessedFormula;
				-- PATCH (tùy chọn): nếu source có khoảng trắng, bọc bằng ''
                IF CHARINDEX(' ', @source) > 0 AND LEFT(@source,1) <> ''''
                    SET @source = '''' + @source + '''';
                SET @GeneratedFormula = '=VLOOKUP(' + @lookup_val + ',' + @source + ',' + CAST(@col_index AS NVARCHAR) + ',' + @match_type + ')';
                GOTO EndOfProcessing;

			ProcessAggregateJson:
				-- Lấy type và scope
				DECLARE @aggType  NVARCHAR(50) = JSON_VALUE(@ProcessedFormula, '$.type');
				DECLARE @sheetAG  NVARCHAR(128);
				DECLARE @scopeAG  NVARCHAR(MAX);

				SELECT @sheetAG = SheetName, @scopeAG = ScopeJson
				FROM #FormulaGeneration
				WHERE Id = @CurrentId;

				-- 2.1 Validate type chính xác
				IF @aggType <> N'PARENTS_RANGE_SUM'
					GOTO ProcessPlaceholders;  -- không đúng type → về luồng chuẩn

				-- 2.2 Validate ScopeJson có args.parents (phải là mảng có ít nhất 1 phần tử)
				IF @scopeAG IS NULL OR ISJSON(@scopeAG) <> 1
					GOTO ProcessPlaceholders;

				IF NOT EXISTS (
					SELECT 1
					FROM OPENJSON(@scopeAG, '$.args.parents')  -- tồn tại ít nhất 1 parent
				)
					GOTO ProcessPlaceholders;

				-- 2.3 (Tuỳ chọn) Validate depth nếu có: phải CAST được về INT
				DECLARE @depthRaw NVARCHAR(50) = JSON_VALUE(@scopeAG, '$.args.depth');
				IF @depthRaw IS NOT NULL AND TRY_CAST(@depthRaw AS INT) IS NULL
					GOTO ProcessPlaceholders;

				-- 2.4 Render công thức bằng hàm depth tổng quát
				SET @GeneratedFormula = dbo.fn_BCDT_ParentsRanges_SumDepth(
					  @BieuMauId, @DonViId, @KeHoachId
					, @sheetAG
					, @CurrentCol
					, @scopeAG
					, 1   -- defaultDepth = 1 nếu không khai báo
				);

				-- Nếu không dựng được (ví dụ không có hàng nào) → trả về flow chuẩn để placeholder khác (nếu có) còn hoạt động
				IF @GeneratedFormula IS NULL
					GOTO EndOfProcessing;

				GOTO EndOfProcessing;

            /*==================== AUTO_DETECT_CHILDREN =================*/
            GenerateAutoSum:
                DECLARE @minRow INT, @maxRow INT, @childCount INT;
                SELECT @childCount = ChildrenCount FROM #FormulaGeneration WHERE Id=@CurrentId;

                IF @childCount > 0
                BEGIN
                    SELECT @minRow = MIN(pos.ExcelRow), @maxRow = MAX(pos.ExcelRow)
                    FROM BCDT_CauTruc_BieuMau ctb
                    JOIN BCDT_CauTruc_BieuMau_ViTriExcel pos ON pos.CauTrucGUID = ctb.CauTrucGUID
                    WHERE ctb.ParentCauTrucGUID = @CurrentGUID AND ctb.BitDaXoa=0;

                    IF @childCount > 1 AND @childCount = (@maxRow - @minRow + 1)
                        SET @GeneratedFormula = '=SUM(' + @CurrentCol + CAST(@minRow AS NVARCHAR) + ':' + @CurrentCol + CAST(@maxRow AS NVARCHAR) + ')';
                    ELSE
                    BEGIN
                        DECLARE @childPositions NVARCHAR(MAX);
                        SELECT @childPositions = STUFF((
                            SELECT '+' + @CurrentCol + CAST(pos.ExcelRow AS NVARCHAR(10))
                            FROM BCDT_CauTruc_BieuMau ctb
                            JOIN BCDT_CauTruc_BieuMau_ViTriExcel pos ON pos.CauTrucGUID = ctb.CauTrucGUID
                            WHERE ctb.ParentCauTrucGUID = @CurrentGUID AND ctb.BitDaXoa=0
                            ORDER BY pos.ExcelRow
                            FOR XML PATH('')
                        ), 1, 1, '');
                        IF @childPositions IS NOT NULL SET @GeneratedFormula = '=' + @childPositions;
                    END
                END

            /*----------------- GHI KẾT QUẢ VÀO TEMP -------------------*/
            EndOfProcessing:
                UPDATE #FormulaGeneration
                SET CongThuc_Final = @GeneratedFormula
                WHERE Id=@CurrentId;

                FETCH NEXT FROM formula_cursor INTO @CurrentId, @CurrentGUID, @CongThucMau, @LoaiCongThuc, @ExcelRow, @ParentGUID, @CurrentCol;
        END

        CLOSE formula_cursor;
        DEALLOCATE formula_cursor;

        PRINT N'[3/4] Đã tạo xong chuỗi công thức.';

        /*===============================================================
          [3] LƯU VÀO BẢNG KẾT QUẢ
              - ViTri dùng TargetAddr (VD: D7), KHÔNG dùng pos.ExcelPosition (C7).
        ===============================================================*/
        INSERT INTO BCDT_CauTruc_BieuMau_CongThuc
        (
            CauTrucGUID, LoaiCongThuc, CongThuc, ViTri, SheetName,
            MoTa, IsActive, BitDaXoa, NguoiTao, NguoiSua, NgayTao, NgaySua
        )
        SELECT
            fg.CauTrucGUID,
            fg.LoaiCongThuc,
            CAST(ISNULL(fg.CongThuc_Final,'') AS NVARCHAR(1000)) AS CongThuc,
            fg.TargetAddr,
            fg.SheetName,
            N'Auto-generated from CongThucId=' + CAST(fg.CongThucId AS NVARCHAR),
            1, 0, -1, -1, GETDATE(), GETDATE()
        FROM #FormulaGeneration fg
        WHERE fg.CongThuc_Final IS NOT NULL;

        PRINT N'[4/4] Đã lưu ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' công thức.';
        DROP TABLE #FormulaGeneration;

        PRINT N'--- SP_BCDT_TaoCongThuc HOÀN THÀNH ---';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#FormulaGeneration') IS NOT NULL DROP TABLE #FormulaGeneration;

        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_TaoDieuKienLoc]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_BCDT_TaoDieuKienLoc]
    @BieuMauId INT,
    @ThamChieuId INT,
    @BieuTieuChiId INT = NULL,
    @ParentTieuChiId INT = NULL,
    @ContextParams NVARCHAR(MAX) = NULL,
    @FilterClause NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @FilterClause = N'1=1';

    /* =====================================================
       STEP 1: Load filters (SPECIFIC + GLOBAL with offset)
       ===================================================== */
    DECLARE @Filters TABLE (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ColumnName NVARCHAR(100),
        Operator NVARCHAR(20),
        FilterValue NVARCHAR(MAX),
        ValueSource NVARCHAR(20),
        LogicOperator NVARCHAR(10),
        Priority INT,
        ParentTraversalDepth INT,
        ContextParameter NVARCHAR(100),
        FilterMode NVARCHAR(20),
        ExtensionTableName NVARCHAR(255),
        PrimaryKeyName NVARCHAR(128),
        ForeignKeyName NVARCHAR(128),
        DataType NVARCHAR(20),
        ColumnList NVARCHAR(MAX) NULL,
        MultiColMode VARCHAR(10) NULL,     -- 'ANY' | 'ALL' | 'EXPR'
        ExprTemplate NVARCHAR(MAX) NULL
    );

    -- SPECIFIC
    IF @BieuTieuChiId IS NOT NULL
    BEGIN
        INSERT INTO @Filters (ColumnName, Operator, FilterValue, ValueSource, LogicOperator, Priority,
                              ParentTraversalDepth, ContextParameter, FilterMode, ExtensionTableName,
                              PrimaryKeyName, ForeignKeyName, DataType, ColumnList, MultiColMode, ExprTemplate)
        SELECT ft.ColumnName, f.Operator, f.FilterValue, f.ValueSource, f.LogicOperator, f.Priority,
               f.ParentTraversalDepth, f.ContextParameter, ft.FilterMode, ft.ExtensionTableName,
               ft.PrimaryKeyName, ft.ForeignKeyName, ft.DataType,
               ft.ColumnList, ft.MultiColMode, ft.ExprTemplate
        FROM dbo.BCDT_Bieu_ThamChieu_BoLoc f
        JOIN dbo.BCDT_DanhMuc_BoLoc ft ON f.BoLocId = ft.Id AND ft.IsActive = 1
        WHERE f.BieuMauId = @BieuMauId
          AND f.ThamChieuId = @ThamChieuId
          AND f.BieuTieuChiId = @BieuTieuChiId
          AND f.IsActive = 1;
    END

    -- GLOBAL
    INSERT INTO @Filters (ColumnName, Operator, FilterValue, ValueSource, LogicOperator, Priority,
                          ParentTraversalDepth, ContextParameter, FilterMode, ExtensionTableName,
                          PrimaryKeyName, ForeignKeyName, DataType, ColumnList, MultiColMode, ExprTemplate)
    SELECT ft.ColumnName, f.Operator, f.FilterValue, f.ValueSource, f.LogicOperator, f.Priority + 100000,
           f.ParentTraversalDepth, f.ContextParameter, ft.FilterMode, ft.ExtensionTableName,
           ft.PrimaryKeyName, ft.ForeignKeyName, ft.DataType,
           ft.ColumnList, ft.MultiColMode, ft.ExprTemplate
    FROM dbo.BCDT_Bieu_ThamChieu_BoLoc f
    JOIN dbo.BCDT_DanhMuc_BoLoc ft ON f.BoLocId = ft.Id AND ft.IsActive = 1
    WHERE f.BieuMauId = @BieuMauId
      AND f.ThamChieuId = @ThamChieuId
      AND f.BieuTieuChiId IS NULL
      AND f.IsActive = 1;

    IF NOT EXISTS (SELECT 1 FROM @Filters) RETURN;

    /* =====================================================
       STEP 2: Build @FinalClause
       ===================================================== */
    DECLARE @FinalClause NVARCHAR(MAX) = N'';

    DECLARE
        @ColumnName NVARCHAR(100), @Operator NVARCHAR(20), @FilterValue NVARCHAR(MAX),
        @ValueSource NVARCHAR(20), @LogicOperator NVARCHAR(10),
        @ParentTraversalDepth INT, @ContextParameter NVARCHAR(100), @FilterMode NVARCHAR(20),
        @ExtTable NVARCHAR(255), @PkName NVARCHAR(128), @FkName NVARCHAR(128), @DataType NVARCHAR(20),
        @ColumnList NVARCHAR(MAX), @MultiColMode VARCHAR(10), @ExprTemplate NVARCHAR(MAX);

    DECLARE @Vals     TABLE (Ord INT IDENTITY(1,1) PRIMARY KEY, Raw NVARCHAR(MAX));
    DECLARE @ValsNorm TABLE (Ord INT PRIMARY KEY, Val NVARCHAR(MAX));
    DECLARE @Cols     TABLE (Col NVARCHAR(500));
    DECLARE @COUNT INT, @LIST NVARCHAR(MAX);

    DECLARE filter_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT ColumnName, Operator, FilterValue, ValueSource, LogicOperator, ParentTraversalDepth,
               ContextParameter, FilterMode, ExtensionTableName, PrimaryKeyName, ForeignKeyName,
               DataType, ColumnList, MultiColMode, ExprTemplate
        FROM @Filters
        ORDER BY Priority, Id;

    OPEN filter_cursor;
    FETCH NEXT FROM filter_cursor INTO
        @ColumnName, @Operator, @FilterValue, @ValueSource, @LogicOperator, @ParentTraversalDepth,
        @ContextParameter, @FilterMode, @ExtTable, @PkName, @FkName, @DataType, @ColumnList, @MultiColMode, @ExprTemplate;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DELETE FROM @Vals; DELETE FROM @ValsNorm; DELETE FROM @Cols;
        SET @COUNT = 0; SET @LIST = NULL;

        DECLARE @Condition NVARCHAR(MAX) = NULL;
        DECLARE @Many NVARCHAR(MAX) = N'';
        DECLARE @JoinOp NVARCHAR(5) = CASE WHEN UPPER(ISNULL(@MultiColMode,''))='ALL' THEN ' AND ' ELSE ' OR ' END;

        DECLARE @Skip BIT = 0;
        DECLARE @RawValue NVARCHAR(MAX) = @FilterValue;
        DECLARE @ResolvedValue NVARCHAR(MAX) = NULL;

        /* 2.1 Resolve value from PARENT / CONTEXT / STATIC */
        IF @ValueSource = 'PARENT' AND @ParentTieuChiId IS NOT NULL
        BEGIN
            DECLARE @TargetTieuChiId INT = @ParentTieuChiId, @TraversalLevel INT = 0;
            WHILE @TraversalLevel < ISNULL(@ParentTraversalDepth, 0) AND @TargetTieuChiId IS NOT NULL
            BEGIN
                SELECT @TargetTieuChiId = CapChaId FROM dbo.BCDT_DanhMuc_TieuChi WHERE Id = @TargetTieuChiId AND BitDaXoa = 0;
                SET @TraversalLevel += 1;
            END

            IF @TargetTieuChiId IS NOT NULL
            BEGIN
                SELECT @RawValue =
                    CASE @ColumnName
                        WHEN 'LinhVucId' THEN CAST(LinhVucId AS NVARCHAR(MAX))
                        WHEN 'DonViId'   THEN CAST(DonViId   AS NVARCHAR(MAX))
                        ELSE NULL
                    END
                FROM dbo.BCDT_DanhMuc_TieuChi
                WHERE Id = @TargetTieuChiId AND BitDaXoa = 0;
            END
            ELSE SET @RawValue = NULL;
        END
        ELSE IF @ValueSource = 'CONTEXT' AND @ContextParams IS NOT NULL AND ISJSON(@ContextParams) > 0
        BEGIN
            IF @Operator = 'BETWEEN'
            BEGIN
                DECLARE @vraw1 NVARCHAR(MAX), @vraw2 NVARCHAR(MAX);

                IF ISJSON(@FilterValue) = 1 AND JSON_QUERY(@FilterValue) IS NOT NULL
                BEGIN
                    ;WITH arr AS (SELECT [key] AS Ord, [value] AS K FROM OPENJSON(@FilterValue))
                    SELECT
                        @vraw1 = JSON_VALUE(@ContextParams, dbo.fn_BCDT_JsonPathKey((SELECT TOP 1 K FROM arr WHERE Ord=0))),
                        @vraw2 = JSON_VALUE(@ContextParams, dbo.fn_BCDT_JsonPathKey((SELECT TOP 1 K FROM arr WHERE Ord=1)));
                END
                ELSE
                BEGIN
                    DECLARE @commaPos INT = CHARINDEX(',', @FilterValue);
                    DECLARE @paramName1 NVARCHAR(200) = LTRIM(RTRIM(LEFT(@FilterValue, @commaPos - 1)));
                    DECLARE @paramName2 NVARCHAR(200) = LTRIM(RTRIM(SUBSTRING(@FilterValue, @commaPos + 1, LEN(@FilterValue))));

                    SET @vraw1 = JSON_VALUE(@ContextParams, dbo.fn_BCDT_JsonPathKey(@paramName1));
                    SET @vraw2 = JSON_VALUE(@ContextParams, dbo.fn_BCDT_JsonPathKey(@paramName2));
                END

                IF @vraw1 IS NULL OR @vraw2 IS NULL SET @Skip = 1 ELSE SET @RawValue = @vraw1 + N',' + @vraw2;
            END
            ELSE
            BEGIN
                SET @RawValue = JSON_VALUE(@ContextParams, dbo.fn_BCDT_JsonPathKey(@FilterValue));
                IF @RawValue IS NULL AND @Operator NOT IN ('IS','IS NOT') SET @Skip = 1;
            END
        END
        -- else: STATIC giữ nguyên @RawValue

        /* 2.2 Normalize single-value forms */
        SET @ResolvedValue = @RawValue;
        IF @DataType IN ('NVARCHAR','VARCHAR','CHAR','NCHAR','DATE','DATETIME','DATETIME2','SMALLDATETIME','TIME') AND @RawValue IS NOT NULL
        BEGIN
            IF @Operator = 'BETWEEN'
            BEGIN
                DECLARE @cPos INT = CHARINDEX(',', @RawValue);
                DECLARE @v1 NVARCHAR(MAX) = N'''' + REPLACE(LEFT(@RawValue, @cPos - 1), '''', '''''') + N'''';
                DECLARE @v2 NVARCHAR(MAX) = N'''' + REPLACE(SUBSTRING(@RawValue, @cPos + 1, LEN(@RawValue)), '''', '''''') + N'''';
                SET @ResolvedValue = @v1 + N',' + @v2;
            END
            ELSE IF @Operator <> 'IN'
            BEGIN
                SET @ResolvedValue = N'''' + REPLACE(@RawValue, '''', '''''') + N'''';
            END
        END

        /* 2.3 Build multi-value arrays for IN/EXPR  — HỖ TRỢ MIXED (STATIC + CONTEXT) */
        IF @Operator IN ('IN','=','BETWEEN')
           OR (UPPER(ISNULL(@MultiColMode,''))='EXPR' AND @ExprTemplate IS NOT NULL)
        BEGIN
            -- Làm sạch queue
            DELETE FROM @Vals; DELETE FROM @ValsNorm;
			
            IF ISJSON(@FilterValue) = 1 AND JSON_QUERY(@FilterValue) IS NOT NULL
            BEGIN
                /* Phần tử mảng hỗ trợ:
                   - {"ctx":"Param"}  → lấy từ @ContextParams
                   - {"val":"abc"}    → literal tĩnh
                   - "Param" | 123    → nếu @ValueSource='CONTEXT' → coi là tên param; ngược lại coi là literal
                */
                INSERT INTO @Vals(Raw)
                SELECT
                    CASE
                        WHEN JSON_VALUE(v.value,'$.ctx') IS NOT NULL
                            THEN JSON_VALUE(@ContextParams,
                                    dbo.fn_BCDT_JsonPathKey(JSON_VALUE(v.value,'$.ctx')))
                        WHEN JSON_VALUE(v.value,'$.val') IS NOT NULL
                            THEN JSON_VALUE(v.value,'$.val')
                        WHEN @ValueSource = 'CONTEXT'
                            THEN JSON_VALUE(@ContextParams,
                                    dbo.fn_BCDT_JsonPathKey(JSON_VALUE(v.value,'$')))
                        ELSE
                            JSON_VALUE(v.value,'$')
                    END
                FROM OPENJSON(@FilterValue) v;
            END
            ELSE
            BEGIN
                -- Chuỗi phân tách dấu phẩy: giữ nguyên hành vi cũ cho STATIC/CONTEXT
                ;WITH x AS (SELECT CAST('<x><i>' + REPLACE(@FilterValue, ',', '</i><i>') + '</i></x>' AS XML) AS xm)
                INSERT INTO @Vals(Raw)
                SELECT
                    CASE WHEN @ValueSource='CONTEXT'
                           THEN JSON_VALUE(@ContextParams,
                                    dbo.fn_BCDT_JsonPathKey(LTRIM(RTRIM(T.c.value('.','nvarchar(max)')))))
                         ELSE LTRIM(RTRIM(T.c.value('.','nvarchar(max)')))
                    END
                FROM x CROSS APPLY xm.nodes('/x/i') AS T(c);
            END

            INSERT INTO @ValsNorm(Ord,Val)
            SELECT	
					ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS Ord,
					CASE
                     WHEN Raw IS NULL THEN NULL
                     WHEN @DataType IN ('NVARCHAR','VARCHAR','CHAR','NCHAR','DATE','DATETIME','DATETIME2','SMALLDATETIME','TIME')
                          THEN N'''' + REPLACE(CAST(Raw AS NVARCHAR(MAX)), '''', '''''') + N''''
                     ELSE LTRIM(RTRIM(Raw))
                   END
            FROM @Vals;

            SELECT @COUNT = COUNT(*) FROM @ValsNorm WHERE Val IS NOT NULL;
            SELECT @LIST  = STRING_AGG(Val, ',') WITHIN GROUP (ORDER BY Ord)
                           FROM @ValsNorm WHERE Val IS NOT NULL;
        END

        /* 2.4 Build @Condition for PRIMARY / EXTENSION with multi-column support */
        IF @ColumnList IS NOT NULL AND LEN(LTRIM(RTRIM(@ColumnList))) > 0
        BEGIN
            IF ISJSON(@ColumnList) = 1 AND JSON_QUERY(@ColumnList) IS NOT NULL
                INSERT INTO @Cols(Col) SELECT LTRIM(RTRIM([value])) FROM OPENJSON(@ColumnList);
            ELSE
                INSERT INTO @Cols(Col) SELECT LTRIM(RTRIM([value])) FROM STRING_SPLIT(@ColumnList, ',');
        END
        ELSE INSERT INTO @Cols(Col) VALUES (@ColumnName);

        DECLARE @Col NVARCHAR(300);
        DECLARE col_cur CURSOR LOCAL FAST_FORWARD FOR SELECT Col FROM @Cols;
        OPEN col_cur; FETCH NEXT FROM col_cur INTO @Col;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @PrefCol NVARCHAR(400);
            IF @FilterMode = 'PRIMARY'
                SET @PrefCol = CASE WHEN CHARINDEX('.', @Col) > 0 THEN @Col
                                    WHEN LEFT(@Col,1)='[' AND RIGHT(@Col,1)=']' THEN 'tc.' + @Col
                                    ELSE 'tc.' + QUOTENAME(@Col) END;
            ELSE
                SET @PrefCol = CASE WHEN CHARINDEX('.', @Col) > 0 THEN @Col
                                    WHEN LEFT(@Col,1)='[' AND RIGHT(@Col,1)=']' THEN 'ext.' + @Col
                                    ELSE 'ext.' + QUOTENAME(@Col) END;

            DECLARE @One NVARCHAR(MAX) = NULL;

            IF UPPER(ISNULL(@MultiColMode,'')) = 'EXPR' AND @ExprTemplate IS NOT NULL
            BEGIN
				PRINT '@ExprTemplate: '+ @ExprTemplate;
                DECLARE @T NVARCHAR(MAX) = @ExprTemplate;
                SET @T = REPLACE(@T, '{COL}', @PrefCol);
                SET @T = REPLACE(@T, '{LIST}', ISNULL(@LIST,'NULL'));
                SET @T = REPLACE(@T, '{COUNT}', CAST(ISNULL(@COUNT,0) AS NVARCHAR(10)));
                DECLARE @i INT = 1;
                WHILE @i <= 9
                BEGIN
                    DECLARE @ValN NVARCHAR(MAX) = (SELECT Val FROM @ValsNorm WHERE Ord = @i);
                    SET @T = REPLACE(@T, '{VAL'+CAST(@i AS NVARCHAR(10))+'}', ISNULL(@ValN,'NULL'));
                    SET @i += 1;
                END
                /* Thêm macro {CTX:ParamName} → lấy từ @ContextParams và tự quote theo @DataType */
                DECLARE @s INT, @e INT, @p NVARCHAR(200), @ctxVal NVARCHAR(MAX);
                SET @s = CHARINDEX('{CTX:', @T);
                WHILE @s > 0
                BEGIN
                    SET @e = CHARINDEX('}', @T, @s+5);
                    IF @e IS NULL BREAK;
                    SET @p = SUBSTRING(@T, @s+5, @e-(@s+5));
					--PRINT '@p:' + CAST(@p as nvarchar(1000));
                    SET @ctxVal = JSON_VALUE(@ContextParams, dbo.fn_BCDT_JsonPathKey(@p));
                    SET @ctxVal = CASE
                                    WHEN @ctxVal IS NULL THEN N'NULL'
                                    WHEN @DataType IN ('NVARCHAR','VARCHAR','CHAR','NCHAR','DATE','DATETIME','DATETIME2','SMALLDATETIME','TIME')
                                         THEN N'''' + REPLACE(@ctxVal, '''', '''''') + N''''
                                    ELSE @ctxVal
                                  END;
                    SET @T = STUFF(@T, @s, @e-@s+1, @ctxVal);
                    SET @s = CHARINDEX('{CTX:', @T);
                END
                SET @One = '(' + @T + ')';
            END
            ELSE
            BEGIN
                IF @ResolvedValue IS NULL
                BEGIN
                    IF @Operator IN ('=','IS')      SET @One = @PrefCol + N' IS NULL';
                    ELSE IF @Operator IN ('!=','<>','IS NOT') SET @One = @PrefCol + N' IS NOT NULL';
                    ELSE SET @One = N'1=0';
                END
                ELSE
                BEGIN
                    IF @Operator = 'IN'
                    BEGIN
                        DECLARE @ListForIn NVARCHAR(MAX) = @LIST;
                        IF @ListForIn IS NULL SET @ListForIn = @ResolvedValue;
                        SET @One = @PrefCol + N' IN (' + @ListForIn + N')';
                    END
                    ELSE IF @Operator = 'LIKE'
                    BEGIN
                        SET @One = @PrefCol + N' LIKE N' + @ResolvedValue;
                    END
                    ELSE IF @Operator = 'BETWEEN'
                    BEGIN
                        SET @One = @PrefCol + N' BETWEEN ' + REPLACE(@ResolvedValue, ',', ' AND ');
                    END
                    ELSE
                    BEGIN
                        SET @One = @PrefCol + N' ' + @Operator + N' ' + @ResolvedValue;
                    END
                END
            END

            SET @Many = CASE WHEN LEN(@Many)=0 THEN @One ELSE @Many + @JoinOp + @One END;
            FETCH NEXT FROM col_cur INTO @Col;
        END
        CLOSE col_cur; DEALLOCATE col_cur;

        IF @FilterMode = 'PRIMARY'
            SET @Condition = '(' + @Many + ')';
        ELSE IF @FilterMode = 'EXTENSION'
        BEGIN
            IF @ExtTable IS NOT NULL AND @PkName IS NOT NULL AND @FkName IS NOT NULL AND @Many IS NOT NULL
            BEGIN
                DECLARE @extRaw NVARCHAR(255) = @ExtTable;
                IF LEFT(@extRaw,1)='[' AND RIGHT(@extRaw,1)=']' SET @extRaw = SUBSTRING(@extRaw,2,LEN(@extRaw)-2);
                DECLARE @extSchema SYSNAME = ISNULL(PARSENAME(@extRaw,2),'dbo');
                DECLARE @extObject SYSNAME = PARSENAME(@extRaw,1);
                IF @extObject IS NULL
                BEGIN
                    RAISERROR(N'ExtensionTableName không hợp lệ: %s',16,1,@ExtTable);
                    RETURN;
                END
                DECLARE @extTwoPart NVARCHAR(520) = QUOTENAME(@extSchema)+N'.'+QUOTENAME(@extObject);
                DECLARE @fk SYSNAME = @FkName, @pk SYSNAME = @PkName;
                IF LEFT(@fk,1)='[' AND RIGHT(@fk,1)=']' SET @fk = SUBSTRING(@fk,2,LEN(@fk)-2);
                IF LEFT(@pk,1)='[' AND RIGHT(@pk,1)=']' SET @pk = SUBSTRING(@pk,2,LEN(@pk)-2);

                SET @Condition = FORMATMESSAGE(
                    N'EXISTS (SELECT 1 FROM %s ext WHERE ext.%s = tc.%s AND (%s))',
                    @extTwoPart, QUOTENAME(@fk), QUOTENAME(@pk), @Many
                );
            END
            ELSE SET @Condition = N'1=0';
        END

        IF @Skip = 1 OR @Condition IS NULL OR LEN(@Condition)=0 GOTO NextFilter;

        IF LEN(@FinalClause)=0
            SET @FinalClause = '(' + @Condition + ')';
        ELSE
            SET @FinalClause = @FinalClause + N' ' + ISNULL(NULLIF(@LogicOperator,''), 'AND') + N' (' + @Condition + N')';

NextFilter:
        FETCH NEXT FROM filter_cursor INTO
            @ColumnName, @Operator, @FilterValue, @ValueSource, @LogicOperator, @ParentTraversalDepth,
            @ContextParameter, @FilterMode, @ExtTable, @PkName, @FkName, @DataType, @ColumnList, @MultiColMode, @ExprTemplate;
    END
    CLOSE filter_cursor; DEALLOCATE filter_cursor;

    /* =====================================================
       STEP 3: Safety guard & output
       ===================================================== */
    IF LEN(@FinalClause) > 0
    BEGIN
        IF @FinalClause LIKE '%;%' OR @FinalClause LIKE '%--%' OR @FinalClause LIKE '%/*%' OR @FinalClause LIKE '%*/%'
           OR @FinalClause LIKE '% DROP %' OR @FinalClause LIKE '% ALTER %' OR @FinalClause LIKE '% INSERT %'
        BEGIN
            RAISERROR(N'FilterClause chứa thành phần không an toàn.', 16, 1);
            RETURN;
        END
        SET @FilterClause = @FinalClause;
    END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_TaoViTriExcel]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- CREATE SP: Calculate Excel Position
-- =============================================
CREATE PROCEDURE [dbo].[SP_BCDT_TaoViTriExcel]
    @BieuMauId   INT,
    @DonViId     INT,
    @KeHoachId   INT,
    @StartRow    INT = 3,              -- Row bắt đầu data (sau header)
    @DataColumn  NVARCHAR(5) = 'C'     -- Column chứa số liệu chính
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage  NVARCHAR(4000),
            @ErrorSeverity INT,
            @ErrorState    INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT N'================================================';
        PRINT N'SP_BCDT_TaoViTriExcel (patched - sort by SoThuTuBieuTieuChi, PathId)';
        PRINT N'================================================';
        PRINT N'Params:';
        PRINT N'  BieuMauId:   ' + CAST(@BieuMauId AS NVARCHAR);
        PRINT N'  DonViId:     ' + CAST(@DonViId AS NVARCHAR);
        PRINT N'  KeHoachId:   ' + CAST(@KeHoachId AS NVARCHAR);
        PRINT N'  StartRow:    ' + CAST(@StartRow AS NVARCHAR);
        PRINT N'  DataColumn:  ' + @DataColumn;
        PRINT N'';

        -- [1/4] XÓA DỮ LIỆU CŨ
        PRINT N'[1/4] Xóa dữ liệu cũ...';
        DELETE FROM dbo.BCDT_CauTruc_BieuMau_ViTriExcel
        WHERE BieuMauId = @BieuMauId
          AND DonViId   = @DonViId
          AND KeHoachId = @KeHoachId;
        PRINT N'   Đã xóa ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' records cũ';
        PRINT N'';

        -- [2/4] TÍNH TOÁN EXCEL POSITION THEO THỨ TỰ HIỂN THỊ MỚI
        PRINT N'[2/4] Tính toán Excel Position (ROW_NUMBER over SoThuTuBieuTieuChi, PathId)...';

        CREATE TABLE #TempPosition (
            Id                    INT,
            CauTrucGUID           UNIQUEIDENTIFIER,
            ParentCauTrucGUID     UNIQUEIDENTIFIER,
            SoThuTuNguon          INT,              -- SoThuTu hiện có trong CT_BieuMau (giữ để debug)
            SoThuTuBieuTieuChi    INT,
            RowNum                INT,              -- THỨ TỰ HIỂN THỊ MỚI
            ExcelRow              INT,              -- = @StartRow - 1 + RowNum
            Level                 INT,
            PathId                NVARCHAR(400),
            IsLeaf                BIT,
            ChildrenCount         INT DEFAULT 0
        );

        ;WITH SRC AS (
            SELECT
                ctb.Id,
                ctb.CauTrucGUID,
                ctb.ParentCauTrucGUID,
                ctb.SoThuTu           AS SoThuTuNguon,
                ctb.SoThuTuBieuTieuChi,
                ctb.PathId,
                CASE WHEN ctb.CapChaId IS NULL THEN 0
                     ELSE 1 + (LEN(ctb.PathId) - LEN(REPLACE(ctb.PathId, '.', '')))
                END AS Level,
                CASE WHEN EXISTS (SELECT 1 FROM dbo.BCDT_CauTruc_BieuMau child
                                  WHERE child.CapChaId = ctb.Id AND child.BitDaXoa = 0)
                     THEN 0 ELSE 1 END AS IsLeaf
            FROM dbo.BCDT_CauTruc_BieuMau ctb
            WHERE ctb.BieuMauId = @BieuMauId
              AND ctb.DonViId   = @DonViId
              AND ctb.KeHoachId = @KeHoachId
              AND ctb.BitDaXoa  = 0
        ),
        RN AS (
            SELECT
                s.*,
                ROW_NUMBER() OVER(
                    ORDER BY ISNULL(s.SoThuTuBieuTieuChi, 2147483647), s.PathId
                ) AS RowNum
            FROM SRC s
        )
        INSERT INTO #TempPosition (
            Id, CauTrucGUID, ParentCauTrucGUID,
            SoThuTuNguon, SoThuTuBieuTieuChi,
            RowNum, ExcelRow, Level, PathId, IsLeaf
        )
        SELECT
            r.Id, r.CauTrucGUID, r.ParentCauTrucGUID,
            r.SoThuTuNguon, r.SoThuTuBieuTieuChi,
            r.RowNum,
            @StartRow - 1 + r.RowNum AS ExcelRow,
            r.Level, r.PathId, r.IsLeaf
        FROM RN r
        ORDER BY r.RowNum;

        DECLARE @CalcCount INT = @@ROWCOUNT;
        PRINT N'   Đã tính toán ' + CAST(@CalcCount AS NVARCHAR) + N' positions theo RowNum';
        PRINT N'';

        -- [3/4] TÍNH CHILDREN COUNT
        PRINT N'[3/4] Tính toán ChildrenCount...';
        UPDATE p
           SET p.ChildrenCount = c.Cnt
        FROM #TempPosition p
        OUTER APPLY (
            SELECT COUNT(*) AS Cnt
            FROM #TempPosition child
            WHERE child.ParentCauTrucGUID = p.CauTrucGUID
        ) c;
        PRINT N'   Đã tính toán ChildrenCount';
        PRINT N'';

        -- [4/4] GHI VÀO BCDT_CauTruc_BieuMau_ViTriExcel
        PRINT N'[4/4] Lưu vào BCDT_CauTruc_BieuMau_ViTriExcel...';

        INSERT INTO dbo.BCDT_CauTruc_BieuMau_ViTriExcel (
            DonViId,
            KeHoachId,
            BieuMauId,
            CauTrucGUID,
            ExcelRow,
            ExcelColumn,
            ExcelPosition,
            ParentCauTrucGUID,
            Level,
            SoThuTu,       -- sử dụng RowNum để sorting theo đúng thứ tự đổ Excel
            PathId,
            IsLeaf,
            ChildrenCount
        )
        SELECT
            @DonViId,
            @KeHoachId,
            @BieuMauId,
            tp.CauTrucGUID,
            tp.ExcelRow,
            @DataColumn,
            @DataColumn + CAST(tp.ExcelRow AS NVARCHAR(10)),
            tp.ParentCauTrucGUID,
            tp.Level,
            tp.RowNum,      -- <== quan trọng: SoThuTu = RowNum (KHÔNG dùng SoThuTuNguon)
            tp.PathId,
            tp.IsLeaf,
            tp.ChildrenCount
        FROM #TempPosition tp
        ORDER BY tp.RowNum;

        DECLARE @InsertedCount INT = @@ROWCOUNT;

        DROP TABLE #TempPosition;

        -- SUMMARY
        PRINT N' SUMMARY:';
        PRINT N'─────────────────────────────────────────';
        PRINT N' Total positions:  ' + CAST(@InsertedCount AS NVARCHAR);
        PRINT N' Start Row:        ' + CAST(@StartRow AS NVARCHAR);
        PRINT N' Data Column:      ' + @DataColumn;
        PRINT N' Position Range:   ' + @DataColumn + CAST(@StartRow AS NVARCHAR) + N' - ' + @DataColumn + CAST(@StartRow + @InsertedCount - 1 AS NVARCHAR);
        PRINT N'';
        PRINT N' Calculate Excel Position HOÀN THÀNH !';
        PRINT N'';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT
            @ErrorMessage  = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState    = ERROR_STATE();

        IF OBJECT_ID('tempdb..#TempPosition') IS NOT NULL DROP TABLE #TempPosition;

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_ThayDoi_DanhMuc_TieuChi]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		thiennd
-- Create date: 25/06/2025
-- Description:	Xử lý thay đổi cấu trúc khi thêm/sửa/xoá tiêu chí (Đã tối ưu)
-- Change log:
--  - [Tối ưu] Gộp các bước xác định biểu mẫu và cấu trúc bị ảnh hưởng vào một truy vấn CTE duy nhất.
--  - [Tối ưu] Sử dụng OPTION(RECOMPILE) để xử lý hiệu quả truy vấn có tham số tùy chọn.
-- =============================================
CREATE   PROCEDURE [dbo].[SP_BCDT_ThayDoi_DanhMuc_TieuChi]
    @Action NVARCHAR(10),        -- Hành động: 'INSERT', 'UPDATE', 'DELETE'
    @TieuChiId INT,              -- ID của tiêu chí bị tác động
    @OldMaThamChieu NVARCHAR(100) = NULL -- Cần cho 'DELETE' hoặc 'UPDATE' thay đổi tham chiếu
AS
BEGIN
    SET NOCOUNT ON;

    -- Bảng tạm để chứa các cặp (BieuMauId, DonViId, KeHoachId) cần tái tạo
    DECLARE @AffectedInstances TABLE (BieuMauId INT, DonViId INT, KeHoachId INT, PRIMARY KEY (BieuMauId, DonViId, KeHoachId));

    -- =========================================================================
    -- [TỐI ƯU] GỘP BƯỚC 1 VÀ 2: TÌM CÁC CẤU TRÚC CẦN TÁI TẠO BẰNG MỘT TRUY VẤN
    -- =========================================================================
    
    -- Lấy thông tin của tiêu chí bị thay đổi
    DECLARE @AffectedDonViId INT, @CurrentMaThamChieu NVARCHAR(100);
    SELECT 
        @AffectedDonViId = ISNULL(DonViId, 0), 
        @CurrentMaThamChieu = c.MaThamChieu 
    FROM dbo.BCDT_DanhMuc_TieuChi a
	JOIN dbo.BCDT_ThamChieu_TieuChi b ON a.Id = b.TieuChiId
	JOIN dbo.BCDT_DanhMuc_ThamChieu c ON c.Id = b.ThamChieuId
    WHERE a.Id = @TieuChiId;

	--print @AffectedDonViId

    -- Nếu hành động là DELETE, thực hiện xóa mềm trước để CTE có thể lấy được các biểu mẫu đã từng dùng nó
    IF @Action = 'DELETE'
    BEGIN
        UPDATE BCDT_Bieu_TieuChi SET BitDaXoa = 1, NgaySua = GETDATE() WHERE TieuChiCoDinhId = @TieuChiId AND BitDaXoa = 0;
    END

    -- CTE để xác định tất cả các BieuMauId bị ảnh hưởng bởi thay đổi
    ;WITH AffectedBieuMau AS (
        -- Trường hợp 1: Tiêu chí được gán cứng vào biểu mẫu (ảnh hưởng bởi UPDATE, DELETE)
        SELECT BieuMauId FROM BCDT_Bieu_TieuChi
        WHERE @Action IN ('UPDATE', 'DELETE') AND TieuChiCoDinhId = @TieuChiId
        
        UNION -- UNION sẽ tự động loại bỏ trùng lặp BieuMauId

        -- Trường hợp 2: Tiêu chí thuộc về một tham chiếu (ảnh hưởng bởi INSERT, UPDATE)
        SELECT BieuMauId FROM BCDT_Bieu_TieuChi
        WHERE @Action IN ('INSERT', 'UPDATE') AND MaThamChieu = @CurrentMaThamChieu AND BitDaXoa = 0

        UNION

        -- Trường hợp 3: Tiêu chí bị thay đổi hoặc xóa khỏi một tham chiếu cũ (ảnh hưởng bởi UPDATE, DELETE)
        SELECT BieuMauId FROM BCDT_Bieu_TieuChi
        WHERE @Action IN ('UPDATE', 'DELETE') AND @OldMaThamChieu IS NOT NULL AND MaThamChieu = @OldMaThamChieu AND BitDaXoa = 0
    )
    -- Chèn các cấu trúc (BieuMauId, DonViId, KeHoachId) bị ảnh hưởng vào bảng tạm
    INSERT INTO @AffectedInstances(BieuMauId, DonViId, KeHoachId)
    SELECT DISTINCT ctb.BieuMauId, ctb.DonViId, ctb.KeHoachId
    FROM BCDT_CauTruc_BieuMau ctb
    JOIN AffectedBieuMau abm ON ctb.BieuMauId = abm.BieuMauId
	--JOIN BCDT_KeHoach_TongHop khth ON ctb.KeHoachId = khth.KeHoachId AND khth.TrangThai = 1000 --Chi trang thai dang cap nhat (1000) thi moi duoc cap nhat cau truc bieu mau
    WHERE 
        ctb.BitDaXoa = 0 
        -- Bộ lọc động:
        -- Nếu @AffectedDonViId là 0 (tiêu chí chung), điều kiện này luôn đúng, sẽ lấy tất cả đơn vị.
        -- Nếu @AffectedDonViId có giá trị, sẽ chỉ lấy các cấu trúc của đúng đơn vị đó.
        AND (@AffectedDonViId = 0 OR ctb.DonViId = @AffectedDonViId);

	INSERT INTO BCDT_ThayDoi_DanhMuc_TieuChi(BieuMauId, KeHoachId, DonViId)
	SELECT DISTINCT BieuMauId, KeHoachId, DonViId FROM @AffectedInstances;

	SELECT DISTINCT BieuMauId, DonViId, KeHoachId FROM @AffectedInstances    
    
    SET NOCOUNT OFF;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_ThemSua_Bieu_ThamChieu_BoLoc]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[SP_BCDT_ThemSua_Bieu_ThamChieu_BoLoc]
    @BieuMauId             INT,
    @ThamChieuId           INT,
    @BieuTieuChiId         INT              = NULL,         -- NULL = áp dụng toàn biểu
    @BoLocId               INT              = NULL,         -- cho phép NULL nếu truyền FilterCode
    @FilterCode            NVARCHAR(50)     = NULL,         -- thay cho BoLocId
    @Operator              NVARCHAR(20),
    @FilterValue           NVARCHAR(1000),                  -- STATIC: literal/CSV/JSON; CONTEXT: key|["k1","k2"]
    @ValueSource           NVARCHAR(20),                    -- STATIC|PARENT|CONTEXT
    @LogicOperator         NVARCHAR(10)     = N'AND',       -- AND|OR
    @Priority              INT              = 100,
    @ParentTraversalDepth  INT              = 0,
    @ContextParameter      NVARCHAR(100)    = NULL,
    @IsActive              BIT              = 1,
    @IfExistsBehavior      NVARCHAR(10)     = N'SKIP',      -- SKIP|UPDATE|ERROR
    @NguoiThucHien         INT              = -1,
    @OutId                 INT              OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resolve BoLocId từ FilterCode nếu cần
    IF (@BoLocId IS NULL AND @FilterCode IS NULL)
    BEGIN
        RAISERROR(N'Phải cung cấp BoLocId hoặc FilterCode.', 16, 1);
        RETURN;
    END

    IF @BoLocId IS NULL
    BEGIN
        SELECT @BoLocId = Id FROM dbo.BCDT_DanhMuc_BoLoc WHERE UPPER(FilterCode)=UPPER(LTRIM(RTRIM(@FilterCode)));
        IF @BoLocId IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy BoLoc theo FilterCode.', 16, 1);
            RETURN;
        END
    END

    -- Kiểm tra AllowedOperators (nếu có cấu hình)
    DECLARE @Allowed NVARCHAR(200) = (SELECT AllowedOperators FROM dbo.BCDT_DanhMuc_BoLoc WHERE Id=@BoLocId);
    IF @Allowed IS NOT NULL AND @Allowed <> N''
    BEGIN
        IF CHARINDEX(@Operator, @Allowed) = 0
        BEGIN
            -- Không cứng ràng buộc, nhưng cảnh báo hợp lệ hoá:
             RAISERROR(N'Operator không nằm trong AllowedOperators.', 16, 1);
             RETURN;
        END
    END

    -- Chuẩn hoá
    IF @LogicOperator IS NULL OR @LogicOperator = N'' SET @LogicOperator = N'AND';
    SET @IfExistsBehavior = UPPER(LTRIM(RTRIM(@IfExistsBehavior)));

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @ExistsId INT = (
            SELECT TOP(1) Id
            FROM dbo.BCDT_Bieu_ThamChieu_BoLoc WITH (UPDLOCK, HOLDLOCK)
            WHERE BieuMauId=@BieuMauId AND ThamChieuId=@ThamChieuId
              AND ISNULL(BieuTieuChiId,0)=ISNULL(@BieuTieuChiId,0)
              AND BoLocId=@BoLocId
        );

        IF @ExistsId IS NOT NULL
        BEGIN
            IF @IfExistsBehavior = N'ERROR'
            BEGIN
                RAISERROR(N'Bản ghi đã tồn tại.', 16, 1);
                ROLLBACK; RETURN;
            END
            ELSE IF @IfExistsBehavior = N'UPDATE'
            BEGIN
                UPDATE dbo.BCDT_Bieu_ThamChieu_BoLoc
                SET Operator = @Operator,
                    FilterValue = @FilterValue,
                    ValueSource = @ValueSource,
                    LogicOperator = @LogicOperator,
                    Priority = @Priority,
                    ParentTraversalDepth = @ParentTraversalDepth,
                    ContextParameter = @ContextParameter,
                    IsActive = @IsActive
                WHERE Id = @ExistsId;

                SET @OutId = @ExistsId;
                COMMIT; RETURN;
            END
            ELSE -- SKIP
            BEGIN
                SET @OutId = @ExistsId;
                COMMIT; RETURN;
            END
        END

        -- Chèn mới
        INSERT dbo.BCDT_Bieu_ThamChieu_BoLoc
        (BieuMauId, ThamChieuId, BieuTieuChiId, BoLocId,
         Operator, FilterValue, ValueSource, LogicOperator, Priority,
         ParentTraversalDepth, ContextParameter, IsActive)
        VALUES
        (@BieuMauId, @ThamChieuId, @BieuTieuChiId, @BoLocId,
         @Operator, @FilterValue, @ValueSource, @LogicOperator, @Priority,
         @ParentTraversalDepth, @ContextParameter, @IsActive);

        SET @OutId = SCOPE_IDENTITY();

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @msg NVARCHAR(4000)=ERROR_MESSAGE(), @sev INT=ERROR_SEVERITY(), @st INT=ERROR_STATE();
        RAISERROR(@msg, @sev, @st);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_ThemSua_Bieu_TieuChi_CongThuc]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[SP_BCDT_ThemSua_Bieu_TieuChi_CongThuc]
    @BieuTieuChiId INT,                 -- bắt buộc
    @MaCongThuc    NVARCHAR(50),        -- bắt buộc (resolve -> CongThucId)
    @ViTri_Cot     NVARCHAR(5),         -- bắt buộc (A..XFD)
    @SheetName     NVARCHAR(100) = N'Sheet1',
    @ScopeJson     NVARCHAR(MAX) = NULL,
    @ThuTuUuTien   INT = 1,
    @IsActive      BIT = 1,
    @GhiChu        NVARCHAR(500) = NULL,
    @NguoiThucHien INT = -1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @Now DATETIME = GETDATE();

        -- 1) Resolve CongThucId từ MaCongThuc
        DECLARE @CongThucId INT;
        SELECT @CongThucId = Id
        FROM dbo.BCDT_DanhMuc_CongThuc
        WHERE MaCongThuc = @MaCongThuc;

        IF @CongThucId IS NULL
            RAISERROR(N'Không tìm thấy MaCongThuc = %s trong BCDT_DanhMuc_CongThuc.', 16, 1, @MaCongThuc);

        -- 2) Validate đầu vào
        SET @ViTri_Cot = UPPER(LTRIM(RTRIM(@ViTri_Cot)));
        IF NULLIF(@ViTri_Cot, N'') IS NULL
            RAISERROR(N'ViTri_Cot là bắt buộc.', 16, 1);

        IF NOT (
               @ViTri_Cot LIKE '[A-Z]'
            OR @ViTri_Cot LIKE '[A-Z][A-Z]'
            OR @ViTri_Cot LIKE '[A-Z][A-Z][A-Z]'
        )
            RAISERROR(N'ViTri_Cot không hợp lệ. Chỉ chấp nhận A..XFD.', 16, 1);

        IF NULLIF(LTRIM(RTRIM(@SheetName)), N'') IS NULL SET @SheetName = N'Sheet1';

        -- 3) UPSERT theo UQ (BieuTieuChiId, CongThucId, ViTri_Cot, SheetName)
        IF EXISTS (
            SELECT 1
            FROM dbo.BCDT_Bieu_TieuChi_CongThuc WITH (UPDLOCK, HOLDLOCK)
            WHERE BieuTieuChiId = @BieuTieuChiId
              AND CongThucId    = @CongThucId
              AND ViTri_Cot     = @ViTri_Cot
              AND ISNULL(SheetName, N'Sheet1') = ISNULL(@SheetName, N'Sheet1')
        )
        BEGIN
            UPDATE dbo.BCDT_Bieu_TieuChi_CongThuc
               SET ScopeJson   = @ScopeJson,
                   ThuTuUuTien = @ThuTuUuTien,
                   IsActive    = @IsActive,
                   GhiChu      = @GhiChu,
                   NguoiSua    = @NguoiThucHien,
                   NgaySua     = @Now
             WHERE BieuTieuChiId = @BieuTieuChiId
               AND CongThucId    = @CongThucId
               AND ViTri_Cot     = @ViTri_Cot
               AND ISNULL(SheetName, N'Sheet1') = ISNULL(@SheetName, N'Sheet1');

            SELECT 'U' AS Op, T.*
            FROM dbo.BCDT_Bieu_TieuChi_CongThuc T
            WHERE T.BieuTieuChiId = @BieuTieuChiId
              AND T.CongThucId    = @CongThucId
              AND T.ViTri_Cot     = @ViTri_Cot
              AND ISNULL(T.SheetName, N'Sheet1') = ISNULL(@SheetName, N'Sheet1');
        END
        ELSE
        BEGIN
            INSERT INTO dbo.BCDT_Bieu_TieuChi_CongThuc
            (
                BieuTieuChiId, CongThucId, ViTri_Cot, SheetName, ScopeJson,
                ThuTuUuTien, IsActive, GhiChu,
                NguoiTao, NgayTao, NguoiSua, NgaySua, BitDaXoa
            )
            VALUES
            (
                @BieuTieuChiId, @CongThucId, @ViTri_Cot, @SheetName, @ScopeJson,
                @ThuTuUuTien, @IsActive, @GhiChu,
                @NguoiThucHien, @Now, @NguoiThucHien, @Now, 0
            );

            SELECT 'I' AS Op, T.*
            FROM dbo.BCDT_Bieu_TieuChi_CongThuc T
            WHERE T.Id = SCOPE_IDENTITY();
        END
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(N'[SP_BCDT_ThemSua_Bieu_TieuChi_CongThuc] lỗi: %s', 16, 1, @Err);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_BCDT_ThemSua_DanhMuc_BoLoc]    Script Date: 1/26/2026 6:43:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[SP_BCDT_ThemSua_DanhMuc_BoLoc]
    @FilterCode         NVARCHAR(50),
    @FilterName         NVARCHAR(200),
    @ColumnName         NVARCHAR(100),
    @DataType           NVARCHAR(20),           -- INT | NVARCHAR | BIT | DATE | SQL ...
    @AllowedOperators   NVARCHAR(200)    = NULL,
    @Description        NVARCHAR(500)    = NULL,
    @FilterMode         NVARCHAR(20)     = N'PRIMARY',  -- PRIMARY | EXTENSION
    @ExtensionTableName NVARCHAR(255)    = NULL,        -- bắt buộc nếu EXTENSION
    @PrimaryKeyName     NVARCHAR(128)    = N'Id',
    @ForeignKeyName     NVARCHAR(128)    = NULL,        -- bắt buộc nếu EXTENSION
    @IsActive           BIT              = 1,
    @SortOrder          INT              = NULL,
    @ColumnList         NVARCHAR(MAX)    = NULL,        -- CSV hoặc JSON array
    @MultiColMode       VARCHAR(10)      = NULL,        -- ANY|ALL|EXPR
    @ExprTemplate       NVARCHAR(MAX)    = NULL,
    @NguoiThucHien      INT              = -1,
    @BoLocId            INT              OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra đầu vào tối thiểu
    IF @FilterCode IS NULL OR LTRIM(RTRIM(@FilterCode)) = N'' 
       OR @FilterName IS NULL OR LTRIM(RTRIM(@FilterName)) = N''
       OR @ColumnName IS NULL OR LTRIM(RTRIM(@ColumnName)) = N''
       OR @DataType IS NULL OR LTRIM(RTRIM(@DataType)) = N''
       OR @FilterMode IS NULL OR LTRIM(RTRIM(@FilterMode)) = N''
    BEGIN
        RAISERROR(N'Thiếu tham số bắt buộc.', 16, 1);
        RETURN;
    END

    -- Chuẩn hoá
    SET @FilterCode = UPPER(LTRIM(RTRIM(@FilterCode)));
    SET @FilterMode = UPPER(LTRIM(RTRIM(@FilterMode)));
    IF @MultiColMode IS NOT NULL SET @MultiColMode = UPPER(LTRIM(RTRIM(@MultiColMode)));

    -- Ràng buộc EXTENSION
    IF @FilterMode = N'EXTENSION'
    BEGIN
        IF @ExtensionTableName IS NULL OR LTRIM(RTRIM(@ExtensionTableName)) = N''
           OR @ForeignKeyName IS NULL OR LTRIM(RTRIM(@ForeignKeyName)) = N''
        BEGIN
            RAISERROR(N'EXTENSION yêu cầu ExtensionTableName và ForeignKeyName.', 16, 1);
            RETURN;
        END
    END

    -- Ràng buộc MultiColMode (nếu có)
    IF @MultiColMode IS NOT NULL AND @MultiColMode NOT IN ('ANY','ALL','EXPR')
    BEGIN
        RAISERROR(N'MultiColMode chỉ nhận ANY|ALL|EXPR.', 16, 1);
        RETURN;
    END

    DECLARE @Now DATETIME = GETDATE();

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (SELECT 1 FROM dbo.BCDT_DanhMuc_BoLoc WITH (UPDLOCK, HOLDLOCK) WHERE FilterCode=@FilterCode)
        BEGIN
            UPDATE dbo.BCDT_DanhMuc_BoLoc
            SET FilterName         = @FilterName,
                ColumnName         = @ColumnName,
                DataType           = @DataType,
                AllowedOperators   = @AllowedOperators,
                [Description]      = @Description,
                FilterMode         = @FilterMode,
                ExtensionTableName = @ExtensionTableName,
                PrimaryKeyName     = ISNULL(@PrimaryKeyName, N'Id'),
                ForeignKeyName     = @ForeignKeyName,
                IsActive           = @IsActive,
                SortOrder          = @SortOrder,
                ColumnList         = @ColumnList,
                MultiColMode       = @MultiColMode,
                ExprTemplate       = @ExprTemplate,
                NgaySua            = @Now,
                NguoiSua           = @NguoiThucHien
            WHERE FilterCode = @FilterCode;

            SELECT @BoLocId = Id FROM dbo.BCDT_DanhMuc_BoLoc WHERE FilterCode=@FilterCode;
        END
        ELSE
        BEGIN
            INSERT dbo.BCDT_DanhMuc_BoLoc
            (FilterCode, FilterName, ColumnName, DataType, AllowedOperators, [Description],
             FilterMode, ExtensionTableName, PrimaryKeyName, ForeignKeyName,
             IsActive, SortOrder, ColumnList, MultiColMode, ExprTemplate,
             NgayTao, NguoiTao, NgaySua, NguoiSua)
            VALUES
            (@FilterCode, @FilterName, @ColumnName, @DataType, @AllowedOperators, @Description,
             @FilterMode, @ExtensionTableName, ISNULL(@PrimaryKeyName,N'Id'), @ForeignKeyName,
             @IsActive, @SortOrder, @ColumnList, @MultiColMode, @ExprTemplate,
             @Now, @NguoiThucHien, @Now, @NguoiThucHien);

            SET @BoLocId = SCOPE_IDENTITY();
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @msg NVARCHAR(4000)=ERROR_MESSAGE(), @sev INT=ERROR_SEVERITY(), @st INT=ERROR_STATE();
        RAISERROR(@msg, @sev, @st);
    END CATCH
END
GO
