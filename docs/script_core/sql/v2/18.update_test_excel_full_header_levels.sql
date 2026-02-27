-- Cap nhat TEST_EXCEL_FULL: them ColumnGroupLevel2 de co mau header 3 tang.
-- Chay sau 17.add_form_column_group_levels.sql. Idempotent.

UPDATE c
SET c.[ColumnGroupLevel2] = CASE
  WHEN c.[ExcelColumn] IN (N'A', N'B', N'C') THEN N'Dinh danh'
  WHEN c.[ExcelColumn] IN (N'D', N'E', N'F', N'G', N'H') THEN N'Chi tiet'
  ELSE NULL
END
FROM [dbo].[BCDT_FormColumn] c
INNER JOIN [dbo].[BCDT_FormSheet] s ON s.[Id] = c.[FormSheetId]
INNER JOIN [dbo].[BCDT_FormDefinition] f ON f.[Id] = s.[FormDefinitionId]
WHERE f.[Code] = N'TEST_EXCEL_FULL';
