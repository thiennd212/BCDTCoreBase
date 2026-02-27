/****** Object:  Table [dbo].[BCDT_BMTH_BieuNguon_Alias]    Script Date: 1/26/2026 6:39:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_BMTH_BieuNguon_Alias](
	[Alias] [sysname] NOT NULL,
	[BieuMauId] [int] NOT NULL,
	[TableName] [sysname] NOT NULL,
	[ValueColumn] [sysname] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[NgayTao] [datetime2](7) NOT NULL,
	[NguoiTao] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Alias] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_BMTH_ColumnExpr]    Script Date: 1/26/2026 6:39:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_BMTH_ColumnExpr](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TongHopBieuMauId] [int] NOT NULL,
	[ExcelCol] [sysname] NOT NULL,
	[ExprText] [nvarchar](max) NOT NULL,
	[RoundDigits] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[NgayTao] [datetime2](7) NOT NULL,
	[NguoiTao] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BMTH_Expr_UniquePerBMTH] UNIQUE NONCLUSTERED 
(
	[TongHopBieuMauId] ASC,
	[ExcelCol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_BMTH_ColumnMap]    Script Date: 1/26/2026 6:39:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_BMTH_ColumnMap](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TongHopBieuMauId] [int] NOT NULL,
	[ExcelCol] [sysname] NOT NULL,
	[RenderMode] [nvarchar](20) NOT NULL,
	[RoundDigits] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[NgayTao] [datetime2](7) NOT NULL,
	[NguoiTao] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_BMTH_CM_UniquePerBMTH] UNIQUE NONCLUSTERED 
(
	[TongHopBieuMauId] ASC,
	[ExcelCol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BCDT_BMTH_ColumnMap_Term]    Script Date: 1/26/2026 6:39:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BCDT_BMTH_ColumnMap_Term](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MapId] [int] NOT NULL,
	[ThuTu] [int] NULL,
	[Alias] [sysname] NOT NULL,
	[DataColumnName] [sysname] NULL,
	[ExcelRow] [int] NULL,
	[AggFn] [nvarchar](10) NOT NULL,
	[Weight] [decimal](18, 6) NOT NULL,
	[Scale] [decimal](18, 6) NOT NULL,
	[UnitScopeMode] [nvarchar](10) NULL,
	[UnitIdsJson] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[NgayTao] [datetime2](7) NOT NULL,
	[NguoiTao] [int] NOT NULL,
	[CriteriaCode] [nvarchar](100) NULL,
	[CriteriaScope] [nvarchar](20) NULL,
	[CriteriaIndex] [int] NULL,
	[CriteriaPickMode] [nvarchar](10) NULL,
	[BTieuChiScopeMode] [nvarchar](10) NULL,
	[BieuTieuChiIdsJson] [nvarchar](max) NULL,
	[TermFiltersJson] [nvarchar](max) NULL,
	[DistinctOn] [sysname] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BCDT_BMTH_BieuNguon_Alias] ADD  CONSTRAINT [DF_BMTH_BNA_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_BMTH_BieuNguon_Alias] ADD  CONSTRAINT [DF_BMTH_BNA_NgayTao]  DEFAULT (sysutcdatetime()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_BieuNguon_Alias] ADD  CONSTRAINT [DF_BMTH_BNA_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnExpr] ADD  CONSTRAINT [DF_BMTH_Expr_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnExpr] ADD  CONSTRAINT [DF_BMTH_Expr_NgayTao]  DEFAULT (sysutcdatetime()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnExpr] ADD  CONSTRAINT [DF_BMTH_Expr_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap] ADD  CONSTRAINT [DF_BMTH_CM_Render]  DEFAULT (N'VALUE') FOR [RenderMode]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap] ADD  CONSTRAINT [DF_BMTH_CM_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap] ADD  CONSTRAINT [DF_BMTH_CM_NgayTao]  DEFAULT (sysutcdatetime()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap] ADD  CONSTRAINT [DF_BMTH_CM_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] ADD  CONSTRAINT [DF_BMTH_Term_Agg]  DEFAULT (N'SUM') FOR [AggFn]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] ADD  CONSTRAINT [DF_BMTH_Term_Weight]  DEFAULT ((1)) FOR [Weight]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] ADD  CONSTRAINT [DF_BMTH_Term_Scale]  DEFAULT ((1)) FOR [Scale]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] ADD  CONSTRAINT [DF_BMTH_Term_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] ADD  CONSTRAINT [DF_BMTH_Term_NgayTao]  DEFAULT (sysutcdatetime()) FOR [NgayTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] ADD  CONSTRAINT [DF_BMTH_Term_NguoiTao]  DEFAULT ((-1)) FOR [NguoiTao]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term]  WITH CHECK ADD  CONSTRAINT [FK_BMTH_Term_ColumnMap] FOREIGN KEY([MapId])
REFERENCES [dbo].[BCDT_BMTH_ColumnMap] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] CHECK CONSTRAINT [FK_BMTH_Term_ColumnMap]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term]  WITH NOCHECK ADD  CONSTRAINT [CK_BMTH_Term_BieuTieuChiIdsJson_Valid] CHECK  (([BTieuChiScopeMode] IS NULL OR upper([BTieuChiScopeMode])='ALL' OR (upper([BTieuChiScopeMode])='EXCLUDE' OR upper([BTieuChiScopeMode])='LIST') AND isjson([BieuTieuChiIdsJson])=(1)))
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] CHECK CONSTRAINT [CK_BMTH_Term_BieuTieuChiIdsJson_Valid]
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term]  WITH NOCHECK ADD  CONSTRAINT [CK_BMTH_Term_BTieuChiScopeMode] CHECK  (([BTieuChiScopeMode] IS NULL OR (upper([BTieuChiScopeMode])='EXCLUDE' OR upper([BTieuChiScopeMode])='LIST' OR upper([BTieuChiScopeMode])='ALL')))
GO
ALTER TABLE [dbo].[BCDT_BMTH_ColumnMap_Term] CHECK CONSTRAINT [CK_BMTH_Term_BTieuChiScopeMode]
GO
