/****** Object:  Table [dbo].[BCDT_Bieu_ThamChieu_BoLoc]    Script Date: 1/26/2026 11:01:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[BieuTieuChiId] [int] NULL,
	[ThamChieuId] [int] NOT NULL,
	[BoLocId] [int] NOT NULL,
	[Operator] [nvarchar](10) NOT NULL,
	[FilterValue] [nvarchar](500) NULL,
	[ValueSource] [nvarchar](50) NOT NULL,
	[ParentTraversalDepth] [int] NULL,
	[ContextParameter] [nvarchar](100) NULL,
	[Priority] [int] NOT NULL,
	[LogicOperator] [nvarchar](5) NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](500) NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_Bieu_ThamChieu_BoLoc] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_Bieu_TieuChi]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_Bieu_TieuChi](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](100) NULL,
	[TieuChiCoDinhId] [int] NULL,
	[MaTieuChiCoDinh] [nvarchar](50) NULL,
	[TenTieuChiCoDinh] [nvarchar](2000) NULL,
	[ThamChieuId] [int] NULL,
	[MaThamChieu] [nvarchar](100) NULL,
	[TenThamChieu] [nvarchar](2000) NULL,
	[SoThuTu] [int] NULL,
	[SoThuTuHienThi] [nvarchar](50) NULL,
	[CapChaId] [int] NULL,
	[GocId] [int] NULL,
	[PathId] [nvarchar](400) NULL,
	[DoSauDeQuy] [int] NULL,
	[GhiChu] [nvarchar](500) NULL,
	[Style] [nvarchar](500) NULL,
	[ColumnMerge] [nvarchar](200) NULL,
	[LaTieuChiThamDinh] [bit] NOT NULL,
	[LaTieuChiTongHop] [bit] NULL,
	[DonViTinh] [nvarchar](100) NULL,
	[BitHieuLuc] [bit] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK__BCDT_B__3214EC075BCDCCFF] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_Bieu_TieuChi_CongThuc]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuTieuChiId] [int] NOT NULL,
	[CongThucId] [int] NOT NULL,
	[ViTri_Cot] [nvarchar](5) NOT NULL,
	[ViTri_Mau]  AS ([ViTri_Cot]+'{ROW_NUMBER}') PERSISTED NOT NULL,
	[SheetName] [nvarchar](100) NULL,
	[ThuTuUuTien] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[GhiChu] [nvarchar](500) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
	[ScopeJson] [nvarchar](max) NULL,
 CONSTRAINT [PK_BCDT_Bieu_TieuChi_CongThuc] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Bieu_TieuChi_CongThuc] UNIQUE NONCLUSTERED 
(
	[BieuTieuChiId] ASC,
	[CongThucId] ASC,
	[ViTri_Cot] ASC,
	[SheetName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_CauTruc_BieuMau]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_CauTruc_BieuMau](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DonViId] [int] NOT NULL,
	[DonViConId] [int] NULL,
	[LinhVucId] [int] NULL,
	[KeHoachId] [int] NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[MaBieuMau] [nvarchar](50) NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[CapChaId] [int] NULL,
	[PathId] [nvarchar](400) NULL,
	[ThamChieuId] [int] NULL,
	[MaThamChieu] [nvarchar](100) NULL,
	[TenThamChieu] [nvarchar](max) NULL,
	[SoThuTu] [int] NULL,
	[SoThuTuHienThi] [nvarchar](50) NULL,
	[Style] [nvarchar](500) NULL,
	[LaTieuChiThamDinh] [bit] NOT NULL,
	[LaTieuChiTongHop] [bit] NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NOT NULL,
	[ParentCauTrucGUID] [uniqueidentifier] NULL,
	[DonViTinh] [nvarchar](100) NULL,
	[BitHieuLuc] [bit] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
	[BieuTieuChiId] [int] NULL,
	[SoThuTuBieuTieuChi] [int] NULL,
	[ColumnMerge] [nvarchar](200) NULL,
 CONSTRAINT [PK__BCDT_C__3214EC07F3BD671F] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BCDT_CauTruc_BieuMau_CauTrucGUID] UNIQUE NONCLUSTERED 
(
	[CauTrucGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_CauTruc_BieuMau_CongThuc]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NOT NULL,
	[LoaiCongThuc] [nvarchar](50) NULL,
	[CongThuc] [nvarchar](1000) NOT NULL,
	[ViTri] [nvarchar](10) NOT NULL,
	[SheetName] [nvarchar](100) NULL,
	[MoTa] [nvarchar](500) NULL,
	[ThuTuUuTien] [int] NULL,
	[TemplateFormulaId] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_CauTruc_BieuMau_CongThuc] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_CauTruc_BieuMau_ViTriExcel]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_CauTruc_BieuMau_ViTriExcel](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DonViId] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[CauTrucGUID] [uniqueidentifier] NOT NULL,
	[ExcelRow] [int] NOT NULL,
	[ExcelColumn] [nvarchar](5) NOT NULL,
	[ExcelPosition] [nvarchar](10) NOT NULL,
	[ParentCauTrucGUID] [uniqueidentifier] NULL,
	[Level] [int] NULL,
	[SoThuTu] [int] NULL,
	[PathId] [nvarchar](400) NULL,
	[IsLeaf] [bit] NOT NULL,
	[ChildrenCount] [int] NOT NULL,
 CONSTRAINT [PK_BCDT_CauTruc_BieuMau_ViTriExcel] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_ViTri_Excel] UNIQUE NONCLUSTERED 
(
	[DonViId] ASC,
	[KeHoachId] ASC,
	[BieuMauId] ASC,
	[CauTrucGUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DanhMuc_BieuMau]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DanhMuc_BieuMau](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MaBieuMau] [nvarchar](50) NOT NULL,
	[TenBieuMau] [nvarchar](2000) NULL,
	[TenVietTat] [nvarchar](100) NULL,
	[TenBieuThamDinh] [nvarchar](2000) NULL,
	[DongBatDau] [int] NULL,
	[BitHieuLuc] [bit] NOT NULL,
	[BitThamDinh] [bit] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
	[IsTongHop] [bit] NOT NULL,
	[LoaiBieuMau] [nvarchar](50) NULL,
 CONSTRAINT [PK__BCDT_D__3214EC07689EE28C] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BCDT_DanhMuc_BieuMau_MaBieuMau] UNIQUE NONCLUSTERED 
(
	[MaBieuMau] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DanhMuc_BoLoc]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DanhMuc_BoLoc](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FilterCode] [nvarchar](50) NOT NULL,
	[FilterName] [nvarchar](200) NOT NULL,
	[ColumnName] [nvarchar](100) NOT NULL,
	[DataType] [nvarchar](20) NOT NULL,
	[AllowedOperators] [nvarchar](200) NULL,
	[Description] [nvarchar](500) NULL,
	[FilterMode] [nvarchar](20) NOT NULL,
	[ExtensionTableName] [nvarchar](255) NULL,
	[PrimaryKeyName] [nvarchar](128) NULL,
	[ForeignKeyName] [nvarchar](128) NULL,
	[IsActive] [bit] NOT NULL,
	[SortOrder] [int] NULL,
	[ColumnList] [nvarchar](max) NULL,
	[MultiColMode] [varchar](10) NULL,
	[ExprTemplate] [nvarchar](max) NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
 CONSTRAINT [PK_BCDT_DanhMuc_BoLoc] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DM_Ma_BoLoc] UNIQUE NONCLUSTERED 
(
	[FilterCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DanhMuc_CongThuc]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DanhMuc_CongThuc](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MaCongThuc] [nvarchar](50) NOT NULL,
	[TenCongThuc] [nvarchar](200) NOT NULL,
	[LoaiCongThuc] [nvarchar](50) NOT NULL,
	[CongThuc_Mau] [nvarchar](1000) NOT NULL,
	[MoTa] [nvarchar](500) NULL,
	[ApDungCho] [nvarchar](200) NULL,
	[ViDu] [nvarchar](500) NULL,
	[Category] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
 CONSTRAINT [PK_BCDT_DanhMuc_CongThuc] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BCDT_DanhMuc_CongThuc_MaCongThuc] UNIQUE NONCLUSTERED 
(
	[MaCongThuc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DanhMuc_ThamChieu]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DanhMuc_ThamChieu](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MaThamChieu] [nvarchar](500) NOT NULL,
	[TenThamChieu] [nvarchar](2000) NULL,
	[LaThamChieuCoDinh] [bit] NOT NULL,
	[LaTieuChiThamDinh] [bit] NOT NULL,
	[BitHieuLuc] [bit] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
	[LoaiDanhMuc] [int] NULL,
	[LoaiLocDuLieu] [int] NULL,
	[LaThamChieuDanhNguon] [bit] NULL,
	[LinhVucId] [nvarchar](500) NULL,
	[SoLuongTieuChiTongHop] [int] NULL,
	[LaThamChieuDonVi] [bit] NULL,
 CONSTRAINT [PK__BCDT_D__3214EC07EAEB4BE0] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BCDT_DanhMuc_ThamChieu_MaThamChieu] UNIQUE NONCLUSTERED 
(
	[MaThamChieu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_DanhMuc_TieuChi]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_DanhMuc_TieuChi](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MaTieuChi] [nvarchar](50) NOT NULL,
	[TenTieuChi] [nvarchar](2000) NULL,
	[CapChaId] [int] NULL,
	[PathId] [nvarchar](400) NULL,
	[DonViId] [int] NULL,
	[SoThuTu] [int] NULL,
	[SoThuTuHienThi] [nvarchar](50) NULL,
	[ThamChieuId] [int] NULL,
	[MaThamChieu] [nvarchar](100) NULL,
	[LaTieuChiCoDinh] [bit] NOT NULL,
	[LaTieuChiThamDinh] [bit] NOT NULL,
	[LaTieuChiTongHop] [bit] NULL,
	[LinhVucId] [int] NULL,
	[DonViTinh] [nvarchar](100) NULL,
	[BitHieuLuc] [bit] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK__BCDT_D__3214EC07AA387C32] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_ThamChieu_TieuChi]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_ThamChieu_TieuChi](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ThamChieuId] [int] NOT NULL,
	[TieuChiId] [int] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NOT NULL,
	[NgaySua] [datetime] NOT NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK__BCDT_T__3214EC0722B608EF] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BCDT_ThamChieu_TieuChi_ThamChieuId_TieuChiId] UNIQUE NONCLUSTERED 
(
	[ThamChieuId] ASC,
	[TieuChiId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_ThayDoi_DanhMuc_TieuChi]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_ThayDoi_DanhMuc_TieuChi](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[KeHoachId] [int] NOT NULL,
	[DonViId] [int] NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_ThayDoi_DanhMuc_TieuChi] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_TieuChi_DuAn]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_TieuChi_DuAn](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[MaDuAn] [nvarchar](100) NULL,
	[TenDuAn] [nvarchar](1000) NULL,
	[LoaiDuAn] [int] NULL,
	[KKTKCN_Id] [int] NULL,
	[KKTKCN_Ma] [nvarchar](50) NULL,
	[LoaiKKTKCN] [int] NULL,
	[DiaChi_Tinh] [nvarchar](50) NULL,
	[DiaChi_Xa] [nvarchar](200) NULL,
	[DiaChi] [nvarchar](2000) NULL,
	[TenNhaDauTu] [nvarchar](1000) NULL,
	[QuocTichDauTu] [nvarchar](200) NULL,
	[TrangThai] [bit] NOT NULL,
	[NganhNghe] [nvarchar](1000) NULL,
	[LoaiHinhId] [nvarchar](50) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_TieuChi_DuAn] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_TieuChi_DuAn_VanBan]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_TieuChi_DuAn_VanBan](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[DuAnId] [int] NOT NULL,
	[LoaiDuAn] [int] NOT NULL,
	[MaDuAn] [nvarchar](100) NULL,
	[LoaiVanBan] [int] NOT NULL,
	[TrangThaiVanBan] [int] NULL,
	[LoaiDieuChinh] [int] NULL,
	[SoKyHieu] [nvarchar](200) NULL,
	[NgayBanHanhStr] [nvarchar](50) NULL,
	[TrichYeu] [nvarchar](4000) NULL,
	[DienTichQuyHoach] [decimal](24, 3) NULL,
	[DienTichThanhLap] [decimal](24, 3) NULL,
	[DienTichThucHien] [decimal](24, 3) NULL,
	[DienTichCNDV] [decimal](24, 3) NULL,
	[VonDauTuNuocNgoai] [decimal](24, 3) NULL,
	[VonDauTuTrongNuoc] [decimal](24, 3) NULL,
	[ThoiHanThueDat] [nvarchar](1000) NULL,
	[NgayBanHanh] [datetime2](7) NULL,
	[NgayBanHanhInt] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_TieuChi_DuAn_VanBan] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_TieuChi_KKTKCN]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_TieuChi_KKTKCN](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[MaKKTKCN] [nvarchar](50) NULL,
	[TenKKTKCN] [nvarchar](2000) NULL,
	[Loai] [int] NULL,
	[LoaiHinhId] [nvarchar](50) NULL,
	[DiaChi_Tinh] [nvarchar](50) NULL,
	[DiaChi_Xa] [nvarchar](200) NULL,
	[DiaChi] [nvarchar](4000) NULL,
	[Thuoc_KKT_Id] [int] NULL,
	[TrangThai] [int] NOT NULL,
	[IsDieuChinh] [bit] NOT NULL,
	[IsCoDuAn] [bit] NOT NULL,
	[NamThanhLap] [int] NULL,
	[TrangThaiVanHanh] [int] NULL,
	[PhanLoaiKCN] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_TieuChi_KKTKCN] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_TieuChi_KKTKCN_VanBan]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_TieuChi_KKTKCN_VanBan](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TieuChiId] [int] NOT NULL,
	[MaTieuChi] [nvarchar](50) NOT NULL,
	[MaKKTKCN] [nchar](10) NOT NULL,
	[KKTKCN_Id] [int] NOT NULL,
	[LoaiVanBan] [int] NULL,
	[TrangThaiVanBan] [int] NULL,
	[SoKyHieu] [nvarchar](200) NULL,
	[NgayBanHanhStr] [nvarchar](100) NULL,
	[TrichYeu] [nvarchar](2000) NULL,
	[TongDienTich] [decimal](24, 3) NULL,
	[KhuPhiThueQuan] [decimal](24, 3) NULL,
	[KhuCheXuatCongNghiep] [decimal](24, 3) NULL,
	[KhuGiaiTriDuLich] [decimal](24, 3) NULL,
	[KhuDoThiDanCu] [decimal](24, 3) NULL,
	[KhuHanhChinhKhac] [decimal](24, 3) NULL,
	[DatKhac] [decimal](24, 3) NULL,
	[DienTichThanhLap] [decimal](24, 3) NULL,
	[DienTichCongNghiepDv] [decimal](24, 3) NULL,
	[NgayBanHanh] [datetime2](7) NULL,
	[NgayBanHanhInt] [int] NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_TieuChi_KKTKCN_VanBan] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_TieuChi_NhaDauTu]    Script Date: 1/26/2026 11:01:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_TieuChi_NhaDauTu](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TieuChiId] [int] NULL,
	[MaTieuChi] [nvarchar](50) NULL,
	[Ma] [nvarchar](50) NULL,
	[Ten] [nvarchar](2000) NULL,
	[MaDinhDanh] [nvarchar](max) NULL,
	[TrangThai] [bit] NULL,
	[MoTa] [nvarchar](2000) NULL,
	[MaQuocGia] [nvarchar](500) NULL,
	[TenQuocGia] [nvarchar](1000) NULL,
	[NguoiTao] [int] NOT NULL,
	[NgayTao] [datetime] NOT NULL,
	[NguoiSua] [int] NULL,
	[NgaySua] [datetime] NULL,
	[BitDaXoa] [bit] NOT NULL,
 CONSTRAINT [PK_BCDT_DanhMuc_NhaDauTu] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__Value__06B3641E]  DEFAULT ('STATIC') FOR [ValueSource]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__Prior__07A78857]  DEFAULT ((1)) FOR [Priority]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__Logic__089BAC90]  DEFAULT ('AND') FOR [LogicOperator]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__IsAct__098FD0C9]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__NgayT__0A83F502]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__Nguoi__0B78193B]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__NgayS__0C6C3D74]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__Nguoi__0D6061AD]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] ADD  CONSTRAINT [DF__BCDT_Bieu__BitDa__0E5485E6]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__DoSau__4BC54675]  DEFAULT ((5)) FOR [DoSauDeQuy]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__LaTie__4CB96AAE]  DEFAULT ((0)) FOR [LaTieuChiThamDinh]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__BitHi__4DAD8EE7]  DEFAULT ((1)) FOR [BitHieuLuc]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__Nguoi__4EA1B320]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__NgayT__4F95D759]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__Nguoi__5089FB92]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__NgayS__517E1FCB]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Bi__BitDa__52724404]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT ('Sheet1') FOR [SheetName]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT ((1)) FOR [ThuTuUuTien]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] ADD  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__LaTie__1554272B]  DEFAULT ((0)) FOR [LaTieuChiThamDinh]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__LaTie__16484B64]  DEFAULT ((0)) FOR [LaTieuChiTongHop]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__CauTr__173C6F9D]  DEFAULT (newid()) FOR [CauTrucGUID]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__BitHi__183093D6]  DEFAULT ((1)) FOR [BitHieuLuc]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__Nguoi__1924B80F]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__NgayT__1A18DC48]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__Nguoi__1B0D0081]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__NgayS__1C0124BA]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Ca__BitDa__1CF548F3]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT ('Sheet1') FOR [SheetName]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT ((1)) FOR [ThuTuUuTien]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] ADD  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_ViTriExcel] ADD  DEFAULT ((0)) FOR [IsLeaf]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_ViTriExcel] ADD  DEFAULT ((0)) FOR [ChildrenCount]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Da__BitHi__31115039]  DEFAULT ((1)) FOR [BitHieuLuc]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF_BCDT_DanhMuc_BieuMau_BitThamDinh]  DEFAULT ((1)) FOR [BitThamDinh]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Da__Nguoi__32057472]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Da__NgayT__32F998AB]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Da__Nguoi__33EDBCE4]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Da__NgayS__34E1E11D]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF__BCDT_Da__BitDa__35D60556]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BieuMau] ADD  CONSTRAINT [DF_BCDT_DanhMuc_BieuMau_IsTongHop]  DEFAULT ((0)) FOR [IsTongHop]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__Filte__46CDE933]  DEFAULT ('PRIMARY') FOR [FilterMode]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__Prima__47C20D6C]  DEFAULT ('Id') FOR [PrimaryKeyName]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__IsAct__01EEAF01]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__NgayT__02E2D33A]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__Nguoi__03D6F773]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__NgayS__04CB1BAC]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] ADD  CONSTRAINT [DF__BCDT_Danh__Nguoi__05BF3FE5]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_CongThuc] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_CongThuc] ADD  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_CongThuc] ADD  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_CongThuc] ADD  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_CongThuc] ADD  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__LaTha__38B27201]  DEFAULT ((0)) FOR [LaThamChieuCoDinh]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__LaTie__39A6963A]  DEFAULT ((0)) FOR [LaTieuChiThamDinh]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__BitHi__3A9ABA73]  DEFAULT ((1)) FOR [BitHieuLuc]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__Nguoi__3B8EDEAC]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__NgayT__3C8302E5]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__Nguoi__3D77271E]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__NgayS__3E6B4B57]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF__BCDT_Da__BitDa__3F5F6F90]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_ThamChieu] ADD  CONSTRAINT [DF_BCDT_DanhMuc_ThamChieu_LaThamChieuDonVi]  DEFAULT ((1)) FOR [LaThamChieuDonVi]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__LaTie__423BDC3B]  DEFAULT ((0)) FOR [LaTieuChiCoDinh]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__LaTie__43300074]  DEFAULT ((0)) FOR [LaTieuChiThamDinh]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__BitHi__442424AD]  DEFAULT ((1)) FOR [BitHieuLuc]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__Nguoi__451848E6]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__NgayT__460C6D1F]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__Nguoi__47009158]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__NgayS__47F4B591]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] ADD  CONSTRAINT [DF__BCDT_Da__BitDa__48E8D9CA]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Th__Nguoi__2772D766]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Th__NgayT__2866FB9F]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Th__Nguoi__295B1FD8]  DEFAULT ((-1)) FOR [NguoiSua]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Th__NgayS__2A4F4411]  DEFAULT (getdate()) FOR [NgaySua]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] ADD  CONSTRAINT [DF__BCDT_Th__BitDa__2B43684A]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_ThayDoi_DanhMuc_TieuChi] ADD  CONSTRAINT [DF_BCDT_ThayDoi_DanhMuc_TieuChi_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_ThayDoi_DanhMuc_TieuChi] ADD  CONSTRAINT [DF_BCDT_ThayDoi_DanhMuc_TieuChi_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_ThayDoi_DanhMuc_TieuChi] ADD  CONSTRAINT [DF_BCDT_ThayDoi_DanhMuc_TieuChi_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_TrangThai]  DEFAULT ((1)) FOR [TrangThai]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_VanBan_IsTang]  DEFAULT ((0)) FOR [LoaiDieuChinh]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_VanBan_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_VanBan_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_DuAn_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_DuAn_VanBan_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_TrangThai]  DEFAULT ((1)) FOR [TrangThai]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_IsDieuChinh]  DEFAULT ((0)) FOR [IsDieuChinh]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_IsCoDuAn]  DEFAULT ((0)) FOR [IsCoDuAn]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_TrangThai1]  DEFAULT ((1)) FOR [TrangThaiVanHanh]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_DanhSach_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_DanhSach_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_DanhSach_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_VanBan_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_VanBan_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_KKTKCN_VanBan] ADD  CONSTRAINT [DF_BCDT_TieuChi_KKTKCN_VanBan_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_NhaDauTu] ADD  CONSTRAINT [DF_BCDT_DanhMuc_NhaDauTu_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_NhaDauTu] ADD  CONSTRAINT [DF_BCDT_DanhMuc_NhaDauTu_NgayTao]  DEFAULT (getdate()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_TieuChi_NhaDauTu] ADD  CONSTRAINT [DF_BCDT_DanhMuc_NhaDauTu_BitDaXoa]  DEFAULT ((0)) FOR [BitDaXoa]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_Bieu_ThamChieu_BoLoc_BCDT_Bieu_TieuChi] FOREIGN KEY([BieuTieuChiId])
REFERENCES [dbo].[BCDT_Bieu_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] CHECK CONSTRAINT [FK_BCDT_Bieu_ThamChieu_BoLoc_BCDT_Bieu_TieuChi]
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc]  WITH CHECK ADD  CONSTRAINT [FK_DM_Loai_BoLoc] FOREIGN KEY([BoLocId])
REFERENCES [dbo].[BCDT_DanhMuc_BoLoc] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_ThamChieu_BoLoc] CHECK CONSTRAINT [FK_DM_Loai_BoLoc]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_Bieu_TieuChi_BCDT_Bieu_TieuChi] FOREIGN KEY([Id])
REFERENCES [dbo].[BCDT_Bieu_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_Bieu_TieuChi_BCDT_Bieu_TieuChi]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_Bieu_TieuChi_BieuMau] FOREIGN KEY([BieuMauId])
REFERENCES [dbo].[BCDT_DanhMuc_BieuMau] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_Bieu_TieuChi_BieuMau]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_Bieu_TieuChi_CapCha] FOREIGN KEY([CapChaId])
REFERENCES [dbo].[BCDT_Bieu_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_Bieu_TieuChi_CapCha]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_Bieu_TieuChi_ThamChieu] FOREIGN KEY([ThamChieuId])
REFERENCES [dbo].[BCDT_DanhMuc_ThamChieu] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_Bieu_TieuChi_ThamChieu]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_Bieu_TieuChi_TieuChiCoDinh] FOREIGN KEY([TieuChiCoDinhId])
REFERENCES [dbo].[BCDT_DanhMuc_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_Bieu_TieuChi_TieuChiCoDinh]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc]  WITH CHECK ADD  CONSTRAINT [FK_Bieu_TieuChi_CongThuc_Bieu_TieuChi] FOREIGN KEY([BieuTieuChiId])
REFERENCES [dbo].[BCDT_Bieu_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] CHECK CONSTRAINT [FK_Bieu_TieuChi_CongThuc_Bieu_TieuChi]
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc]  WITH CHECK ADD  CONSTRAINT [FK_Bieu_TieuChi_CongThuc_Library] FOREIGN KEY([CongThucId])
REFERENCES [dbo].[BCDT_DanhMuc_CongThuc] ([Id])
GO
ALTER TABLE [dbo].[BCDT_Bieu_TieuChi_CongThuc] CHECK CONSTRAINT [FK_Bieu_TieuChi_CongThuc_Library]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_CauTruc_BieuMau_BieuMau] FOREIGN KEY([BieuMauId])
REFERENCES [dbo].[BCDT_DanhMuc_BieuMau] ([Id])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] CHECK CONSTRAINT [FK_BCDT_CauTruc_BieuMau_BieuMau]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_CauTruc_BieuMau_BieuTieuChi] FOREIGN KEY([BieuTieuChiId])
REFERENCES [dbo].[BCDT_Bieu_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] CHECK CONSTRAINT [FK_BCDT_CauTruc_BieuMau_BieuTieuChi]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_CauTruc_BieuMau_CapCha] FOREIGN KEY([CapChaId])
REFERENCES [dbo].[BCDT_CauTruc_BieuMau] ([Id])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] CHECK CONSTRAINT [FK_BCDT_CauTruc_BieuMau_CapCha]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_CauTruc_BieuMau_ThamChieu] FOREIGN KEY([ThamChieuId])
REFERENCES [dbo].[BCDT_DanhMuc_ThamChieu] ([Id])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] CHECK CONSTRAINT [FK_BCDT_CauTruc_BieuMau_ThamChieu]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_CauTruc_BieuMau_TieuChi] FOREIGN KEY([TieuChiId])
REFERENCES [dbo].[BCDT_DanhMuc_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau] CHECK CONSTRAINT [FK_BCDT_CauTruc_BieuMau_TieuChi]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc]  WITH CHECK ADD  CONSTRAINT [FK_CauTruc_BieuMau_CongThuc_CauTruc] FOREIGN KEY([CauTrucGUID])
REFERENCES [dbo].[BCDT_CauTruc_BieuMau] ([CauTrucGUID])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] CHECK CONSTRAINT [FK_CauTruc_BieuMau_CongThuc_CauTruc]
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc]  WITH CHECK ADD  CONSTRAINT [FK_CauTruc_BieuMau_CongThuc_Template] FOREIGN KEY([TemplateFormulaId])
REFERENCES [dbo].[BCDT_Bieu_TieuChi_CongThuc] ([Id])
GO
ALTER TABLE [dbo].[BCDT_CauTruc_BieuMau_CongThuc] CHECK CONSTRAINT [FK_CauTruc_BieuMau_CongThuc_Template]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_DanhMuc_TieuChi_CapCha] FOREIGN KEY([CapChaId])
REFERENCES [dbo].[BCDT_DanhMuc_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] CHECK CONSTRAINT [FK_BCDT_DanhMuc_TieuChi_CapCha]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_DanhMuc_TieuChi_ThamChieu] FOREIGN KEY([ThamChieuId])
REFERENCES [dbo].[BCDT_DanhMuc_ThamChieu] ([Id])
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_TieuChi] CHECK CONSTRAINT [FK_BCDT_DanhMuc_TieuChi_ThamChieu]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_ThamChieu_TieuChi_ThamChieu] FOREIGN KEY([ThamChieuId])
REFERENCES [dbo].[BCDT_DanhMuc_ThamChieu] ([Id])
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_ThamChieu_TieuChi_ThamChieu]
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi]  WITH CHECK ADD  CONSTRAINT [FK_BCDT_ThamChieu_TieuChi_TieuChi] FOREIGN KEY([TieuChiId])
REFERENCES [dbo].[BCDT_DanhMuc_TieuChi] ([Id])
GO
ALTER TABLE [dbo].[BCDT_ThamChieu_TieuChi] CHECK CONSTRAINT [FK_BCDT_ThamChieu_TieuChi_TieuChi]
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc]  WITH NOCHECK ADD  CONSTRAINT [CK_BoLoc_MultiColMode] CHECK  (([MultiColMode]='EXPR' OR [MultiColMode]='ALL' OR [MultiColMode]='ANY'))
GO
ALTER TABLE [dbo].[BCDT_DanhMuc_BoLoc] CHECK CONSTRAINT [CK_BoLoc_MultiColMode]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID của biểu mẫu (scope)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc', @level2type=N'COLUMN',@level2name=N'BieuMauId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID của tham chiếu (scope)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc', @level2type=N'COLUMN',@level2name=N'ThamChieuId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'FK → BCDT_DanhMuc_BoLoc.Id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc', @level2type=N'COLUMN',@level2name=N'BoLocId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'STATIC=giá trị cố định, PARENT=lấy từ parent node, CONTEXT=lấy từ runtime params' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc', @level2type=N'COLUMN',@level2name=N'ValueSource'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Thứ tự ưu tiên (1=cao nhất)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc', @level2type=N'COLUMN',@level2name=N'Priority'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'AND hoặc OR (kết hợp với filter tiếp theo)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc', @level2type=N'COLUMN',@level2name=N'LogicOperator'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Bảng lưu filter configuration cho từng BieuMau + ThamChieu. Admin có thể định nghĩa filters mà không cần thay đổi code.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_ThamChieu_BoLoc'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mapping Tiêu chí nào trong Biểu mẫu nào' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_Bieu_TieuChi'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mã filter (unique). VD: CTMTQG, LINHVUC, TRANGTHAI' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc', @level2type=N'COLUMN',@level2name=N'FilterCode'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Kiểu dữ liệu: INT, NVARCHAR, BIT, DATE, SQL (custom)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc', @level2type=N'COLUMN',@level2name=N'DataType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Chế độ lọc: PRIMARY (trên bảng DuToan_DanhMuc_TieuChi), EXTENSION (trên bảng mở rộng)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc', @level2type=N'COLUMN',@level2name=N'FilterMode'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tên của bảng dữ liệu mở rộng cần join đến' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc', @level2type=N'COLUMN',@level2name=N'ExtensionTableName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tên cột khóa chính trên bảng DuToan_DanhMuc_TieuChi (thường là Id)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc', @level2type=N'COLUMN',@level2name=N'PrimaryKeyName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tên cột khóa ngoại trên bảng mở rộng (tham chiếu về TieuChi)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc', @level2type=N'COLUMN',@level2name=N'ForeignKeyName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Bảng lưu metadata của các loại filter. Admin có thể định nghĩa filter types mới mà không cần thay đổi code.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'BCDT_DanhMuc_BoLoc'
GO
