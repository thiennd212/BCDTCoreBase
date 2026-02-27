/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau1]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau1](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[TieuChiId] [int] NOT NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[SoThuTu] [int] NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[KCN_NamNgoai_KKT] [decimal](24, 3) NULL,
	[KCN_VenBien] [decimal](24, 3) NULL,
	[KCN_CuaKhau] [decimal](24, 3) NULL,
	[KCN_ChuyenBiet] [decimal](24, 3) NULL,
	[TongCong] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau11] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau10]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau10](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NOT NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[SoThuTu] [int] NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[QuyetDinhPheDuyet] [nvarchar](200) NULL,
	[QuyMo] [decimal](24, 3) NULL,
	[KPTQ_QuyMo] [decimal](24, 3) NULL,
	[KPTQ_QuyMoLap] [decimal](24, 3) NULL,
	[KPTQ_QuyMoXayDung] [decimal](24, 3) NULL,
	[KCX_QuyMo] [decimal](24, 3) NULL,
	[KCX_QuyMoLap] [decimal](24, 3) NULL,
	[KCX_QuyMoXayDung] [decimal](24, 3) NULL,
	[KCX_QuyMoChoThue] [decimal](24, 3) NULL,
	[KGT_QuyMo] [decimal](24, 3) NULL,
	[KGT_QuyMoLap] [decimal](24, 3) NULL,
	[KGT_QuyMoXayDung] [decimal](24, 3) NULL,
	[KDT_QuyMo] [decimal](24, 3) NULL,
	[KDT_QuyMoLap] [decimal](24, 3) NULL,
	[KDT_QuyMoXayDung] [decimal](24, 3) NULL,
	[KHC_QuyMo] [decimal](24, 3) NULL,
	[KHC_QuyMoLap] [decimal](24, 3) NULL,
	[KHC_QuyMoXayDung] [decimal](24, 3) NULL,
	[DatKhac] [decimal](24, 3) NULL,
	[ChuaSuDung] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau22] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau11]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau11](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SoThuTu] [int] NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](2000) NULL,
	[DiaDiem] [nvarchar](2000) NULL,
	[VanBanThanhLap] [nvarchar](200) NULL,
	[TenNhaDauTu] [nvarchar](200) NULL,
	[QuocTichNhaDauTu] [nvarchar](200) NULL,
	[TinhTrang] [int] NULL,
	[QuyMoQuyHoach] [decimal](24, 3) NULL,
	[QuyMoThanhLap] [decimal](24, 3) NULL,
	[QuyMoHoatDong] [decimal](24, 3) NULL,
	[NN_VonDauTuDangKy] [decimal](24, 3) NULL,
	[NN_VonDauTu] [decimal](24, 3) NULL,
	[TN_VonDauTuDangKy] [decimal](24, 3) NULL,
	[TN_VonDauTu] [decimal](24, 3) NULL,
	[SXKD_DoanhThu] [decimal](24, 3) NULL,
	[SXKD_XuatKhau] [decimal](24, 3) NULL,
	[SXKD_NhapKhau] [decimal](24, 3) NULL,
	[SXKD_NopNganSach] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau11_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau12]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau12](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[VanBanThanhLap] [nvarchar](200) NULL,
	[VanBanPheDuyet] [nvarchar](200) NULL,
	[QuyMo_DatThanhLap] [decimal](24, 3) NULL,
	[QuyMo_DatCNDV] [decimal](24, 3) NULL,
	[QuyMo_DatCN] [decimal](24, 3) NULL,
	[NN_TongSoDuAn] [int] NULL,
	[NN_VonDauTu_DangKy] [decimal](24, 3) NULL,
	[NN_DuAnSXKD] [int] NULL,
	[NN_VonDauTu_ThucHien] [decimal](24, 3) NULL,
	[NN_DoanhThu] [decimal](24, 3) NULL,
	[NN_XuatKhau] [decimal](24, 3) NULL,
	[NN_NhapKhau] [decimal](24, 3) NULL,
	[NN_NopNganSach] [decimal](24, 3) NULL,
	[NN_LaoDong] [int] NULL,
	[TN_TongSoDuAn] [int] NULL,
	[TN_VonDauTu_DangKy] [decimal](24, 3) NULL,
	[TN_DuAnSXKD] [int] NULL,
	[TN_VonDauTu_ThucHien] [decimal](24, 3) NULL,
	[TN_DoanhThu] [decimal](24, 3) NULL,
	[TN_XuatKhau] [decimal](24, 3) NULL,
	[TN_NhapKhau] [decimal](24, 3) NULL,
	[TN_NopNganSach] [decimal](24, 3) NULL,
	[TN_LaoDong] [int] NULL,
	[XLNT_TinhTrang] [int] NULL,
	[XLNT_CongSuat_ThietKe] [int] NULL,
	[XLNT_CongSuat_HoatDong] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau12_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau13]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau13](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[DonViId] [int] NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](max) NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](200) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[TinhTrangId] [int] NULL,
	[QuyMo] [decimal](24, 3) NULL,
	[NganhNghe] [nvarchar](500) NULL,
	[NN_VonDangKy] [decimal](24, 3) NULL,
	[NN_VonDauTu_ThucHien] [decimal](24, 3) NULL,
	[NN_DoanhThu] [decimal](24, 3) NULL,
	[NN_XuatKhau] [decimal](24, 3) NULL,
	[NN_NhapKhau] [decimal](24, 3) NULL,
	[NN_NopNganSach] [decimal](24, 3) NULL,
	[NN_LaoDong] [int] NULL,
	[TN_VonDangKy] [decimal](24, 3) NULL,
	[TN_VonDauTu_ThucHien] [decimal](24, 3) NULL,
	[TN_DoanhThu] [decimal](24, 3) NULL,
	[TN_XuatKhau] [decimal](24, 3) NULL,
	[TN_NhapKhau] [decimal](24, 3) NULL,
	[TN_NopNganSach] [decimal](24, 3) NULL,
	[TN_LaoDong] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau13_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau14]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau14](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[NhaDauTu_Id] [int] NULL,
	[NhaDauTu_Ma] [nvarchar](50) NULL,
	[TenNhaDauTu] [nvarchar](500) NULL,
	[TK_DuAn_CapMoi] [int] NULL,
	[TK_DuAn_TangVon] [int] NULL,
	[TK_DuAn_GiamVon] [int] NULL,
	[TK_DuAn_ThuHoi] [int] NULL,
	[TK_TongVon_CapMoi] [decimal](24, 3) NULL,
	[TK_TongVon_TangVon] [decimal](24, 3) NULL,
	[TK_TongVon_GiamVon] [decimal](24, 3) NULL,
	[TK_TongVon_ThuHoi] [decimal](24, 3) NULL,
	[LK_DuAn_TrongKCN] [int] NULL,
	[LK_DuAn_VenBien] [int] NULL,
	[LK_DuAn_CuaKhau] [int] NULL,
	[LK_TongVonDK_TrongKCN] [decimal](24, 3) NULL,
	[LK_TongVonDK_VenBien] [decimal](24, 3) NULL,
	[LK_TongVonDK_CuaKhau] [decimal](24, 3) NULL,
	[LK_TongVonTH_TrongKCN] [decimal](24, 3) NULL,
	[LK_TongVonTH_VenBien] [decimal](24, 3) NULL,
	[LK_TongVonTH_CuaKhau] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau14_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau15]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau15](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](500) NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](500) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[KKTKCN] [nvarchar](50) NULL,
	[SoVanBan] [nvarchar](200) NULL,
	[NgayVanBan] [datetime] NULL,
	[NhaDauTu] [nvarchar](200) NULL,
	[VonDieuLe_Tang] [decimal](24, 3) NULL,
	[VonDieuLe_Giam] [decimal](24, 3) NULL,
	[VonDauTu_Tang] [decimal](24, 3) NULL,
	[VonDauTu_Giam] [decimal](24, 3) NULL,
	[QuyMo_Tang] [decimal](24, 3) NULL,
	[QuyMo_Giam] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau15_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau16]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau16](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](500) NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](500) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](1000) NULL,
	[SoVanBan] [nvarchar](200) NULL,
	[TenNhaDauTu] [nvarchar](200) NULL,
	[QuocTichDauTu] [nvarchar](200) NULL,
	[NN_VonDauTu] [decimal](24, 3) NULL,
	[TN_VonDauTu] [decimal](24, 3) NULL,
	[SoVanBan_ThuHoi] [nvarchar](2000) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau16_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau2]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau2](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DonViId] [int] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](1000) NULL,
	[TenKKTKCN] [nvarchar](1000) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[DiaDiem] [nvarchar](4000) NULL,
	[TenNhaDauTu] [nvarchar](1000) NULL,
	[QuocTichDauTu] [nvarchar](200) NULL,
	[TLM_QDChapThuan] [nvarchar](200) NULL,
	[TLM_ChungNhanDangKy] [nvarchar](200) NULL,
	[TLM_QuyMoThanhLap] [decimal](24, 3) NULL,
	[TLM_QuyMoCNDV] [decimal](24, 3) NULL,
	[TLM_ThoiHanThue] [nvarchar](1000) NULL,
	[TLM_VonNuocNgoai] [decimal](24, 3) NULL,
	[TLM_VonTrongNuoc] [decimal](24, 3) NULL,
	[DC_ChungNhanDangKy] [nvarchar](200) NULL,
	[DC_TruocDieuChinh] [decimal](24, 3) NULL,
	[DC_ChungNhanDieuChinh] [nvarchar](200) NULL,
	[DC_SauDieuChinh] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau2_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau3]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau3](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[TieuChiId] [int] NOT NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](2000) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[QuyetDinhChapThuan] [nvarchar](200) NULL,
	[GiayChungNhan] [nvarchar](200) NULL,
	[DiaDiem] [nvarchar](2000) NULL,
	[TenNhaDauTu] [nvarchar](1000) NULL,
	[QuocTichNhaDauTu] [nvarchar](200) NULL,
	[VonDangKy_VonDauTuNN] [decimal](24, 3) NULL,
	[VonDangKy_VonDauTuTN] [decimal](24, 3) NULL,
	[QuyMoThanhLap] [decimal](24, 3) NULL,
	[QuyMoCNDV] [decimal](24, 3) NULL,
	[QuyMoDaChoThue] [decimal](24, 3) NULL,
	[TyLeLapDay] [decimal](24, 3) NULL,
	[MucDoHoanThien] [decimal](24, 3) NULL,
	[TinhTrangHoatDong] [int] NULL,
	[QuyMoDaGiao] [decimal](24, 3) NULL,
	[LuyKe_VonDauTuNN] [decimal](24, 3) NULL,
	[LuyKe_VonDauTuTN] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau12] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau4]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau4](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[DuAnId] [int] NULL,
	[MaDuAn] [nvarchar](50) NULL,
	[TenDuAn] [nvarchar](2000) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
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
	[TN_SoLaoDong] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau14] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau5]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau5](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[TinhTrangQuyHoach] [int] NULL,
	[TinhTrangHoatDong] [int] NULL,
	[CongSuatThietKe] [decimal](24, 3) NULL,
	[CongSuatHoatDong] [decimal](24, 3) NULL,
	[ChatLuongNuocThai] [int] NULL,
	[ChatLuongNuocThaiSauXL] [int] NULL,
	[TinhTrangLapDat] [int] NULL,
	[ChuaCo_NNguyenNhan] [nvarchar](50) NULL,
	[ChuaCo_ThoiGianDuKien] [nvarchar](50) NULL,
	[ChuaCo_GiaiPhapXL] [nvarchar](4000) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau15] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau6]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau6](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[TongSoLD] [int] NULL,
	[GioiTinh_Nam] [int] NULL,
	[GioiTinh_Nu] [int] NULL,
	[TD_PhoThong] [int] NULL,
	[TD_SoCap] [int] NULL,
	[TD_TrungCap] [int] NULL,
	[TD_CaoDang] [int] NULL,
	[TD_DaiHoc] [int] NULL,
	[TD_TrenDaiHoc] [int] NULL,
	[TD_Khac] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMauTT03] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau7]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau7](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[DiaDiem] [nvarchar](2000) NULL,
	[QuyMo] [decimal](24, 3) NULL,
	[VanBanPhuongAn] [nvarchar](200) NULL,
	[VanBanPheDuyet] [nvarchar](200) NULL,
	[VanBanThanhLap] [nvarchar](200) NULL,
	[QuyMoChapThuan] [decimal](24, 3) NULL,
	[QuyMoConLai] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau16] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau8]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau8](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[TongDienTich] [decimal](24, 3) NULL,
	[PhiThueQuan] [decimal](24, 3) NULL,
	[CheXuat] [decimal](24, 3) NULL,
	[GiaiTri] [decimal](24, 3) NULL,
	[DoThi] [decimal](24, 3) NULL,
	[HanhChinh] [decimal](24, 3) NULL,
	[Khac] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMauTT031] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DuLieu_BieuMau9]    Script Date: 1/26/2026 6:44:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DuLieu_BieuMau9](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TieuChiId] [int] NOT NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[SoThuTu] [int] NULL,
	[CauTrucGUID] [uniqueidentifier] NULL,
	[DotKeHoach_Id] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](500) NULL,
	[LoaiHinhKKTKCN_Id] [nvarchar](50) NULL,
	[Ngoai_KCN_Trong_KKT] [decimal](24, 3) NULL,
	[KCN_Trong_KKT] [decimal](24, 3) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DuLieu_BieuMau21] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau1] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau11_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau1] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau11_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau1] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau11_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau10] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau22_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau10] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau22_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau10] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau22_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau11] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau11_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau11] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau11_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau11] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau11_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau12] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau12_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau12] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau12_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau12] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau12_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau13] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau13_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau13] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau13_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau13] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau13_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau14] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau14_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau14] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau14_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau14] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau14_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau15] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau15_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau15] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau15_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau15] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau15_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau16] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau16_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau16] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau16_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau16] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau16_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau2] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau2_NguoiTao_1]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau2] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau2_NgayTao_1]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau2] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau2_BitDaXoa_1]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau3] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau12_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau3] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau12_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau3] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau12_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau4] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau14_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau4] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau14_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau4] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau14_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau5] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau15_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau5] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau15_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau6] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMauTT03_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau6] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMauTT03_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau6] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMauTT03_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau7] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau16_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau7] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau16_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau7] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau16_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau8] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMauTT031_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau8] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMauTT031_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau8] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMauTT031_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau9] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau21_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau9] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau21_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DuLieu_BieuMau9] ADD  CONSTRAINT [DF_BCDT_DuLieu_BieuMau21_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
