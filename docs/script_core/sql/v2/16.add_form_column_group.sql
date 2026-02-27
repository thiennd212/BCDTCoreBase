-- Them cot ColumnGroupName cho header phan cap (cha-con) nhu Excel
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.BCDT_FormColumn') AND name = 'ColumnGroupName')
BEGIN
  ALTER TABLE [dbo].[BCDT_FormColumn] ADD [ColumnGroupName] NVARCHAR(200) NULL;
  PRINT N'Da them BCDT_FormColumn.ColumnGroupName.';
END
GO
