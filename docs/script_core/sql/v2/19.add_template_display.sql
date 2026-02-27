-- Luu template display (JSON Fortune-sheet) va DataStartRow cho sheet.
-- Upload template Excel -> parse -> luu TemplateDisplayJson; dung lam base khi hien thi nhap lieu.

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.BCDT_FormDefinition') AND name = 'TemplateDisplayJson')
BEGIN
  ALTER TABLE [dbo].[BCDT_FormDefinition] ADD [TemplateDisplayJson] NVARCHAR(MAX) NULL;
  PRINT N'Da them BCDT_FormDefinition.TemplateDisplayJson.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.BCDT_FormSheet') AND name = 'DataStartRow')
BEGIN
  ALTER TABLE [dbo].[BCDT_FormSheet] ADD [DataStartRow] INT NULL;
  PRINT N'Da them BCDT_FormSheet.DataStartRow (hang bat dau du lieu, 1-based).';
END
GO
