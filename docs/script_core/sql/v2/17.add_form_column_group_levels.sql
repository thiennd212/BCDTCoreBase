-- Header Excel nhiều tầng: thêm ColumnGroupLevel2, Level3, Level4 (Level1 = ColumnGroupName đã có).
-- Cho phép header 2–4 tầng (merge theo nhóm ở mỗi tầng).

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.BCDT_FormColumn') AND name = 'ColumnGroupLevel2')
BEGIN
  ALTER TABLE [dbo].[BCDT_FormColumn] ADD [ColumnGroupLevel2] NVARCHAR(200) NULL;
  PRINT N'Đã thêm BCDT_FormColumn.ColumnGroupLevel2.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.BCDT_FormColumn') AND name = 'ColumnGroupLevel3')
BEGIN
  ALTER TABLE [dbo].[BCDT_FormColumn] ADD [ColumnGroupLevel3] NVARCHAR(200) NULL;
  PRINT N'Đã thêm BCDT_FormColumn.ColumnGroupLevel3.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.BCDT_FormColumn') AND name = 'ColumnGroupLevel4')
BEGIN
  ALTER TABLE [dbo].[BCDT_FormColumn] ADD [ColumnGroupLevel4] NVARCHAR(200) NULL;
  PRINT N'Đã thêm BCDT_FormColumn.ColumnGroupLevel4.';
END
GO
