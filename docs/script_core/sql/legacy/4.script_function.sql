/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_BuildTermPredicate]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*==============================================================
  PATCH: fn_BCDT_BuildTermPredicate (robust JSON + NULL-safe)
==============================================================*/
CREATE FUNCTION [dbo].[fn_BCDT_BuildTermPredicate]
(
    @TblAlias        SYSNAME,
    @TermFiltersJson NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @res NVARCHAR(MAX) = N'';
    IF @TermFiltersJson IS NULL RETURN @res;

    /* 1) Làm sạch JSON (loại BOM/zero-width …) */
    DECLARE @j NVARCHAR(MAX) = N'';
    DECLARE @i INT = 1, @len INT = LEN(@TermFiltersJson);
    WHILE @i <= @len
    BEGIN
        DECLARE @ch NCHAR(1) = SUBSTRING(@TermFiltersJson, @i, 1);
        DECLARE @u  INT      = UNICODE(@ch);
        IF @u NOT IN (65279,8203,8204,8205,8206,8207,8234,8235,8236,8237,8238,8294,8295,8296,8297,160,173)
           AND ( @u > 31 OR @u IN (9,10,13) )
            SET @j += @ch;
        SET @i += 1;
    END;
    IF CHARINDEX(N'[', @j) > 1
        SET @j = SUBSTRING(@j, CHARINDEX(N'[', @j), LEN(@j));

    IF ISJSON(@j) <> 1 RETURN @res;

    /* 2) Parse filters */
    DECLARE @F TABLE
    (
      ord INT IDENTITY(1,1) PRIMARY KEY,
      Col SYSNAME,
      Op  NVARCHAR(20),
      ValScalar NVARCHAR(MAX),
      ValArray  NVARCHAR(MAX)
    );

    INSERT INTO @F(Col, Op, ValScalar, ValArray)
    SELECT
      JSON_VALUE(v.value,'$.Column'),
      UPPER(LTRIM(RTRIM(JSON_VALUE(v.value,'$.Operator')))),
      JSON_VALUE(v.value,'$.Value'),
      JSON_QUERY(v.value,'$.Value')
    FROM OPENJSON(@j) v;

    IF NOT EXISTS(SELECT 1 FROM @F) RETURN @res;

    /* 3) Build predicate */
    DECLARE @pred NVARCHAR(MAX) = N'';
    SET @i = 1;
    DECLARE @n INT = (SELECT COUNT(*) FROM @F);

    WHILE @i <= @n
    BEGIN
        DECLARE @col SYSNAME      = (SELECT Col FROM @F WHERE ord=@i);
        DECLARE @op  NVARCHAR(20) = (SELECT Op  FROM @F WHERE ord=@i);
        DECLARE @sv  NVARCHAR(MAX)= (SELECT ValScalar FROM @F WHERE ord=@i);
        DECLARE @av  NVARCHAR(MAX)= (SELECT ValArray  FROM @F WHERE ord=@i);

        IF @col IS NULL OR @op IS NULL
        BEGIN SET @i += 1; CONTINUE; END;

        IF @op NOT IN (N'=',N'<>',N'>',N'<',N'>=',N'<=',N'LIKE',
                       N'IN',N'NOT IN',N'IS NULL',N'IS NOT NULL')
        BEGIN SET @i += 1; CONTINUE; END;

        DECLARE @piece NVARCHAR(MAX) = N'';

        IF @op IN (N'IS NULL',N'IS NOT NULL')
        BEGIN
            SET @piece = QUOTENAME(@TblAlias) + N'.' + QUOTENAME(@col) + N' ' + @op;
        END
		ELSE IF @op IN (N'IN', N'NOT IN')
		BEGIN
			IF ISJSON(@av) = 1
			BEGIN
				-- Dựng danh sách giá trị từ mảng JSON, không dùng JSON_VALUE trên scalar
				DECLARE @list NVARCHAR(MAX) =
				(
					SELECT STRING_AGG(
						CASE 
							WHEN v.[type] IN (2,3,4)               -- number (int/real) hoặc bool
								THEN v.[value]
							WHEN v.[type] = 0                      -- NULL
								THEN N'NULL'
							ELSE                                   -- string
								N'''' + REPLACE(v.[value], '''', '''''') + N''''
						END, N','
					)
					FROM OPENJSON(@av) v
				);
				IF @list IS NULL OR LTRIM(RTRIM(@list)) = N'' SET @list = N'NULL';
				SET @piece = QUOTENAME(@TblAlias) + N'.' + QUOTENAME(@col) + N' ' + @op + N' (' + @list + N')';
			END
			ELSE
			BEGIN
				-- fallback: một giá trị đơn (không phải mảng)
				DECLARE @rhs1 NVARCHAR(MAX) =
					CASE
						WHEN TRY_CONVERT(DECIMAL(38,10), @sv) IS NOT NULL THEN @sv
						WHEN @sv IS NULL THEN N'NULL'
						ELSE N'''' + REPLACE(@sv,'''','''''') + N''''
					END;
				SET @piece = QUOTENAME(@TblAlias) + N'.' + QUOTENAME(@col) + N' ' + @op + N' (' + @rhs1 + N')';
			END
		END
        ELSE
        BEGIN
            /* scalar comparators */
            DECLARE @rhs NVARCHAR(MAX) =
                CASE
                  WHEN TRY_CONVERT(DECIMAL(38,10), @sv) IS NOT NULL THEN @sv
                  WHEN @sv IS NULL THEN N'NULL'
                  ELSE N'''' + REPLACE(@sv,'''','''''') + N''''
                END;
            SET @piece = QUOTENAME(@TblAlias) + N'.' + QUOTENAME(@col) + N' ' + @op + N' ' + @rhs;
        END

        IF @piece <> N''
            SET @pred = @pred + CASE WHEN @pred=N'' THEN N'' ELSE N' AND ' END + @piece;

        SET @i += 1;
    END

    IF @pred <> N''
        SET @res = N' AND (' + @pred + N')';

    RETURN @res;
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_JsonPathKey]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Dựng JSON path dạng $"."<key>" an toàn từ tên tham số (đã strip)
CREATE   FUNCTION [dbo].[fn_BCDT_JsonPathKey] (@name NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @k NVARCHAR(MAX) = dbo.fn_BCDT_StripTsqlLiteral(@name);
    -- nếu sợ có dấu " bên trong tên, có thể REPLACE(@k, '"', '\"') nhưng thường key là tên đơn giản
    RETURN N'$."' + @k + N'"';
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_ParentsRanges_SumDepth]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Tổng con theo danh sách mã cha, depth tham số hoá
-- - Bắt cha theo bt.MaTieuChiCoDinh (khớp với dữ liệu hiện có)
-- - Nếu 1 mã cha không có con theo depth => đóng góp 0
-- - Có thể lọc theo SheetName (nếu @SheetName IS NOT NULL)
CREATE   FUNCTION [dbo].[fn_BCDT_ParentsRanges_SumDepth]
(
    @BieuMauId    INT,
    @DonViId      INT,
    @KeHoachId    INT,
    @SheetName    NVARCHAR(128),  -- NULL => không lọc
    @Column       NVARCHAR(5),    -- ví dụ 'E'
    @ScopeJson    NVARCHAR(MAX),  -- $.args.parents[], $.args.depth
    @DefaultDepth INT = 1         -- 1=con trực tiếp; N>1=N cấp; -1=mọi cấp
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    -- chuẩn hoá col
    SET @Column = UPPER(LTRIM(RTRIM(@Column)));
    IF @Column IS NULL
       OR ( @Column NOT LIKE '[A-Z]'
         AND @Column NOT LIKE '[A-Z][A-Z]'
         AND @Column NOT LIKE '[A-Z][A-Z][A-Z]' )
        RETURN NULL;

    DECLARE @depth INT = COALESCE(TRY_CAST(JSON_VALUE(@ScopeJson, '$.args.depth') AS INT), @DefaultDepth);
    DECLARE @parentsJson NVARCHAR(MAX) = JSON_QUERY(@ScopeJson, '$.args.parents');
    IF @parentsJson IS NULL RETURN NULL;

    -- Danh sách mã cha theo thứ tự
    DECLARE @P TABLE (ord INT IDENTITY(1,1) PRIMARY KEY, ParentCode NVARCHAR(100));
    INSERT INTO @P(ParentCode)
    SELECT value FROM OPENJSON(@parentsJson);

    DECLARE @n INT = (SELECT COUNT(*) FROM @P);
    IF @n = 0 RETURN NULL;

    DECLARE @totalArgs NVARCHAR(MAX) = N'';
    DECLARE @i INT = 1;

    WHILE @i <= @n
    BEGIN
        DECLARE @parentCode NVARCHAR(100);
        SELECT @parentCode = ParentCode FROM @P WHERE ord=@i;

        -- Thu hàng con (theo depth) cho TỪNG mã cha
        DECLARE @Rows TABLE (ExcelRow INT PRIMARY KEY);

        ;WITH ParentNodes AS (
            SELECT DISTINCT ctb.CauTrucGUID
            FROM BCDT_CauTruc_BieuMau ctb
            JOIN BCDT_Bieu_TieuChi bt ON bt.Id = ctb.BieuTieuChiId
            WHERE ctb.BieuMauId=@BieuMauId AND ctb.DonViId=@DonViId AND ctb.KeHoachId=@KeHoachId
              AND ctb.BitDaXoa=0
              AND bt.MaTieuChiCoDinh = @parentCode     -- <<<<<< CHỐT Ở ĐÂY
        ),
        FirstLevel AS ( -- cấp 1 (con trực tiếp)
            SELECT c.CauTrucGUID, 1 AS lvl
            FROM BCDT_CauTruc_BieuMau c
            JOIN ParentNodes pn ON c.ParentCauTrucGUID = pn.CauTrucGUID
            WHERE c.BitDaXoa=0
        ),
        DescTree AS (   -- đệ quy tới depth
            SELECT fl.CauTrucGUID, fl.lvl
            FROM FirstLevel fl
            UNION ALL
            SELECT c2.CauTrucGUID, dt.lvl + 1
            FROM DescTree dt
            JOIN BCDT_CauTruc_BieuMau c2
                 ON c2.ParentCauTrucGUID = dt.CauTrucGUID
                AND c2.BitDaXoa=0
            WHERE (@depth = -1 OR dt.lvl < @depth)
        )
        INSERT INTO @Rows(ExcelRow)
        SELECT DISTINCT pos.ExcelRow
        FROM DescTree dt
        JOIN BCDT_CauTruc_BieuMau_ViTriExcel pos
             ON pos.CauTrucGUID = dt.CauTrucGUID;

        DECLARE @part NVARCHAR(MAX);

        IF EXISTS (SELECT 1 FROM @Rows)
        BEGIN
            -- Gom các hàng liên tiếp thành segment để rút gọn
            DECLARE @Seg TABLE (rmin INT, rmax INT);

            ;WITH R AS (
                SELECT ExcelRow, ROW_NUMBER() OVER (ORDER BY ExcelRow) AS rn
                FROM @Rows
            ),
            G AS (
                SELECT ExcelRow, ExcelRow - rn AS grp
                FROM R
            )
            INSERT INTO @Seg(rmin, rmax)
            SELECT MIN(ExcelRow), MAX(ExcelRow)
            FROM G
            GROUP BY grp;

            SET @part = N'';
            SELECT @part = @part +
                           CASE WHEN rmin = rmax
                                THEN @Column + CAST(rmin AS NVARCHAR(10))
                                ELSE @Column + CAST(rmin AS NVARCHAR(10)) + ':' + @Column + CAST(rmax AS NVARCHAR(10))
                           END + N','
            FROM @Seg
            ORDER BY rmin;

            IF RIGHT(@part,1)=',' SET @part = LEFT(@part, LEN(@part)-1);
        END
        ELSE
        BEGIN
            -- Mã cha không có con theo depth => đóng góp 0
            SET @part = N'0';
        END

        -- Ghép vào tổng theo thứ tự cha
        IF @totalArgs = N'' SET @totalArgs = @part;
        ELSE               SET @totalArgs = @totalArgs + N',' + @part;

        SET @i += 1;
    END

    RETURN N'=SUM(' + @totalArgs + N')';
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_ProtectDivideByZero]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fn_BCDT_ProtectDivideByZero]
(
    @ExprIn        NVARCHAR(MAX),
    @DivZeroAsNull BIT = 1      -- 1: chia 0 -> NULL; 0: chia 0 -> 0 (bọc COALESCE ngoài)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    IF @ExprIn IS NULL OR LEN(@ExprIn) = 0
        RETURN @ExprIn;

    DECLARE @exprOut   NVARCHAR(MAX) = @ExprIn;
    DECLARE @slashPos  INT;
    DECLARE @coStart   INT;
    DECLARE @i         INT;
    DECLARE @len       INT;
    DECLARE @depth     INT;
    DECLARE @innerLen  INT;
    DECLARE @innerExpr NVARCHAR(MAX);
    DECLARE @iter      INT = 0;

    -- Tìm từng mẫu '/COALESCE(' và bọc lại
    SET @slashPos = CHARINDEX(N'/COALESCE(', @exprOut);

    WHILE @slashPos > 0
    BEGIN
        SET @iter += 1;
        IF @iter > 100
        BEGIN
            -- Có gì “bất thường” thì dừng, trả về nguyên văn để không treo
            RETURN @exprOut;
        END

        -- vị trí chữ 'C' của 'COALESCE' (ngay sau '/')
        SET @coStart = @slashPos + 1;
        SET @len     = LEN(@exprOut);
        SET @i       = @coStart;
        SET @depth   = 0;

        -- tìm ngoặc ')' khớp với 'COALESCE(' bằng cách đếm ngoặc
        WHILE @i <= @len
        BEGIN
            DECLARE @ch NCHAR(1) = SUBSTRING(@exprOut, @i, 1);

            IF @ch = N'('
                SET @depth += 1;
            ELSE IF @ch = N')'
            BEGIN
                SET @depth -= 1;
                IF @depth = 0
                    BREAK; -- đây là ')' kết thúc COALESCE(...)
            END

            SET @i += 1;
        END

        -- Nếu không tìm được ngoặc kết thúc -> bỏ qua để an toàn
        IF @depth <> 0 OR @i > @len
        BEGIN
            -- tìm mẫu tiếp theo sau vị trí hiện tại, tránh lặp vô tận
            SET @slashPos = CHARINDEX(N'/COALESCE(', @exprOut, @slashPos + 1);
            CONTINUE;
        END

        -- lấy toàn bộ đoạn "COALESCE(...)" bên phải dấu '/'
        SET @innerLen  = @i - @coStart + 1;
        SET @innerExpr = SUBSTRING(@exprOut, @coStart, @innerLen);

        -- thay "COALESCE(...)" bằng "NULLIF(COALESCE(...),0)"
        SET @exprOut =
            STUFF(
                @exprOut,
                @coStart,            -- bắt đầu từ chữ 'C'
                @innerLen,          -- thay đúng đoạn COALESCE(...)
                N'NULLIF(' + @innerExpr + N',0)'
            );

        -- tìm tiếp mẫu '/COALESCE(' phía sau vị trí hiện tại
        SET @slashPos = CHARINDEX(N'/COALESCE(', @exprOut, @coStart + 1);
    END

    -- Nếu muốn chia 0 ra 0 thay vì NULL thì bọc thêm COALESCE ngoài cùng
    IF @DivZeroAsNull = 0
        SET @exprOut = N'COALESCE((' + @exprOut + N'),0)';

    RETURN @exprOut;
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_RangeToCurrent]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     FUNCTION [dbo].[fn_BCDT_RangeToCurrent]
(
    @BieuMauId   INT,
    @DonViId     INT,
    @KeHoachId   INT,
    @SheetName   NVARCHAR(128) = NULL,
    @Col         NVARCHAR(8),
    @CurrentRow  INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @UCol NVARCHAR(8) = UPPER(LTRIM(RTRIM(@Col)));
    DECLARE @minRow INT;

    SELECT @minRow = MIN(p.ExcelRow)
    FROM dbo.BCDT_CauTruc_BieuMau s
    JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel p ON p.CauTrucGUID=s.CauTrucGUID
    LEFT JOIN dbo.BCDT_Bieu_TieuChi_CongThuc map
           ON map.BieuTieuChiId = s.BieuTieuChiId AND map.IsActive=1 AND map.BitDaXoa=0
    WHERE s.BieuMauId=@BieuMauId AND s.DonViId=@DonViId AND s.KeHoachId=@KeHoachId AND s.BitDaXoa=0
      AND UPPER(COALESCE(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), ''), UPPER(LTRIM(RTRIM(p.ExcelColumn))))) = @UCol
      AND (@SheetName IS NULL OR map.SheetName=@SheetName);

    IF @minRow IS NULL OR @CurrentRow IS NULL RETURN N'0';
    RETURN 'SUM(' + @UCol + CAST(@minRow AS NVARCHAR(10)) + ':' + @UCol + CAST(@CurrentRow AS NVARCHAR(10)) + ')';
END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_RenderAgg]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_BCDT_RenderAgg]
(
    @BieuMauId     INT,
    @DonViId       INT,
    @KeHoachId     INT,
    @ParentGUID    UNIQUEIDENTIFIER,
    @CurrentGUID   UNIQUEIDENTIFIER,
    @SheetName     NVARCHAR(128) = NULL,
    @Func          NVARCHAR(10),             -- SUM|AVG|MAX|MIN|COUNT|COUNTA
    @Scope         NVARCHAR(10),             -- ALL|SIBLINGS
    @Col           NVARCHAR(8),              -- 'D','E','F','G',...
    @ExcludeCurrent BIT = 1
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @UCol NVARCHAR(8) = UPPER(LTRIM(RTRIM(@Col)));
    DECLARE @F NVARCHAR(10) = UPPER(@Func);
    DECLARE @S NVARCHAR(10) = UPPER(@Scope);

    DECLARE @Cnt INT, @MinR INT, @MaxR INT;

    /* --------- Tập nguồn (đếm & min/max) — PHẢI lọc theo cột --------- */
    SELECT 
        @Cnt  = COUNT(*),
        @MinR = MIN(p.ExcelRow),
        @MaxR = MAX(p.ExcelRow)
    FROM dbo.BCDT_CauTruc_BieuMau s
    JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel p
         ON p.CauTrucGUID = s.CauTrucGUID
    LEFT JOIN dbo.BCDT_Bieu_TieuChi_CongThuc map
         ON map.BieuTieuChiId = s.BieuTieuChiId
        AND map.IsActive = 1 AND map.BitDaXoa = 0
    WHERE s.BieuMauId=@BieuMauId
      AND s.DonViId=@DonViId
      AND s.KeHoachId=@KeHoachId
      AND s.BitDaXoa=0
      AND p.ExcelRow IS NOT NULL
      -- Lọc đúng sheet khi có @SheetName
      AND ( @SheetName IS NULL OR map.SheetName = @SheetName OR map.SheetName IS NULL )
      -- Loại trừ chính mình (cho mọi scope)
      AND ( @ExcludeCurrent = 0 OR s.CauTrucGUID <> @CurrentGUID )
      -- Nếu là SIBLINGS thì ràng buộc parent
      AND ( @S <> 'SIBLINGS'
		  OR ( @ParentGUID IS NULL AND s.ParentCauTrucGUID IS NULL )
		  OR s.ParentCauTrucGUID = @ParentGUID )
      -- *** LỌC THEO CỘT ***
      --AND (
      --      -- Trường hợp cấu hình một-cột cổ điển
      --      UPPER(COALESCE(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), ''),
      --                     NULLIF(LTRIM(RTRIM(p.ExcelColumn)), ''))) = @UCol
      --      -- Hoặc cột nằm trong danh sách mở rộng apply_cols (nếu có)
      --   OR EXISTS (
      --          SELECT 1
      --          FROM dbo.fn_BCDT_Scope_ExpandCols(
      --                  map.ScopeJson,
      --                  UPPER(COALESCE(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), ''),
      --                                 NULLIF(LTRIM(RTRIM(p.ExcelColumn)), '')))
      --               ) ec
      --          WHERE ec.Col = @UCol
      --      )
      --)

    IF ISNULL(@Cnt,0) = 0 RETURN N'0';

    DECLARE @IsContig BIT = CASE WHEN @Cnt = (@MaxR - @MinR + 1) THEN 1 ELSE 0 END;
    DECLARE @range NVARCHAR(64) = @UCol + CAST(@MinR AS NVARCHAR(10)) + ':' + @UCol + CAST(@MaxR AS NVARCHAR(10));
    DECLARE @csv NVARCHAR(MAX);

    IF @IsContig = 0
    BEGIN
        /* Build ranges + lẻ: gom các đoạn liên tiếp thành A7:A15, phần còn lại là A18,A20,... */
        ;WITH Rows AS (
            SELECT DISTINCT p.ExcelRow
            FROM dbo.BCDT_CauTruc_BieuMau s
            JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel p ON p.CauTrucGUID = s.CauTrucGUID
            LEFT JOIN dbo.BCDT_Bieu_TieuChi_CongThuc map
                   ON map.BieuTieuChiId = s.BieuTieuChiId
                  AND map.IsActive = 1 AND map.BitDaXoa = 0
            WHERE s.BieuMauId=@BieuMauId
              AND s.DonViId=@DonViId
              AND s.KeHoachId=@KeHoachId
              AND s.BitDaXoa=0
              AND p.ExcelRow IS NOT NULL
              AND ( @SheetName IS NULL OR map.SheetName = @SheetName OR map.SheetName IS NULL )
              AND ( @ExcludeCurrent = 0 OR s.CauTrucGUID <> @CurrentGUID )
              AND ( @S <> 'SIBLINGS'
                    OR ( @ParentGUID IS NULL AND s.ParentCauTrucGUID IS NULL )
                    OR s.ParentCauTrucGUID = @ParentGUID )
        ),
        Mark AS (
            SELECT ExcelRow,
                   ExcelRow - ROW_NUMBER() OVER (ORDER BY ExcelRow) AS grp
            FROM Rows
        ),
        Blocks AS (
            SELECT MIN(ExcelRow) AS r1, MAX(ExcelRow) AS r2
            FROM Mark
            GROUP BY grp
        )
        SELECT @csv = STUFF((
            SELECT
                CASE WHEN r1 = r2
                     THEN ',' + @UCol + CAST(r1 AS NVARCHAR(10))
                     ELSE ',' + @UCol + CAST(r1 AS NVARCHAR(10)) + ':' + @UCol + CAST(r2 AS NVARCHAR(10))
                END
            FROM Blocks
            ORDER BY r1
            FOR XML PATH(''), TYPE).value('.','nvarchar(max)'),1,1,'');
    END

    DECLARE @expr NVARCHAR(MAX);
    IF @IsContig = 1
        SET @expr = CASE @F
            WHEN 'SUM'    THEN 'SUM('    + @range + ')'
            WHEN 'AVG'    THEN 'AVERAGE('+ @range + ')'
            WHEN 'MAX'    THEN 'MAX('    + @range + ')'
            WHEN 'MIN'    THEN 'MIN('    + @range + ')'
            WHEN 'COUNT'  THEN 'COUNT('  + @range + ')'
            WHEN 'COUNTA' THEN 'COUNTA(' + @range + ')'
            ELSE 'SUM(' + @range + ')'
        END;
    ELSE
        SET @expr = CASE @F
            WHEN 'SUM'    THEN 'SUM('    + @csv + ')'
            WHEN 'AVG'    THEN 'AVERAGE('+ @csv + ')'
            WHEN 'MAX'    THEN 'MAX('    + @csv + ')'
            WHEN 'MIN'    THEN 'MIN('    + @csv + ')'
            WHEN 'COUNT'  THEN 'COUNT('  + @csv + ')'
            WHEN 'COUNTA' THEN 'COUNTA(' + @csv + ')'
            ELSE 'SUM(' + @csv + ')'
        END;

    RETURN @expr;  -- KHÔNG có dấu '='
END


GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_RenderColsChain]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[fn_BCDT_RenderColsChain]
(
    @ScopeJson  NVARCHAR(MAX),
    @CurrentCol NVARCHAR(5),
    @JoinOp     NVARCHAR(1) = NULL      -- NULL => đọc từ ScopeJson.args.join_op; nếu vẫn NULL => '-'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    IF @ScopeJson IS NULL OR ISJSON(@ScopeJson) <> 1
        RETURN NULL;

    -- lấy join_op từ JSON nếu tham số không truyền
    DECLARE @op NVARCHAR(1) = COALESCE(@JoinOp, JSON_VALUE(@ScopeJson, '$.args.join_op'), N'-');

    -- chỉ cho phép 1 kí tự trong tập + - * /
    IF @op NOT IN (N'+', N'-', N'*', N'/') SET @op = N'-';

    -- phải có mảng args.cols
    IF ISJSON(JSON_QUERY(@ScopeJson, '$.args.cols')) <> 1
        RETURN NULL;

    DECLARE @Cols TABLE (ord INT PRIMARY KEY, col NVARCHAR(5));

    INSERT INTO @Cols(ord, col)
    SELECT
        TRY_CAST([key] AS INT) AS ord,
        CASE
            WHEN UPPER(LTRIM(RTRIM([value]))) IN ('COL','{{COL}}','THIS_COL','{{THIS_COL}}')
                THEN UPPER(LTRIM(RTRIM(@CurrentCol)))
            ELSE UPPER(LTRIM(RTRIM([value])))
        END
    FROM OPENJSON(@ScopeJson, '$.args.cols');

    -- lọc hợp lệ: A..XFD
    DELETE FROM @Cols
    WHERE col IS NULL OR LEN(col) NOT BETWEEN 1 AND 3 OR col LIKE '%[^A-Z]%';

    IF NOT EXISTS (SELECT 1 FROM @Cols) RETURN NULL;

    DECLARE @chain NVARCHAR(MAX);
    SELECT @chain = STRING_AGG('{CURRENT:' + col + '}', @op)
                    WITHIN GROUP (ORDER BY ord)
    FROM @Cols;

    RETURN @chain;
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_ResolveTieuChiRow_ByIndex]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* ===========================================================
   1) Function: Resolve ExcelRow theo @INDEX & @SCOPE (+ MaCha)
   =========================================================== */
CREATE   FUNCTION [dbo].[fn_BCDT_ResolveTieuChiRow_ByIndex]
(
    @BieuMauId           INT,
    @DonViId             INT,
    @KeHoachId           INT,
    @MaTieuChi           NVARCHAR(100),
    @CurrentParentGUID   UNIQUEIDENTIFIER = NULL,          -- dùng cho SCOPE=SAME_PARENT
    @Scope               NVARCHAR(20) = N'SAME_PARENT',    -- SAME_PARENT | ANY | BY_PARENT_CODE
    @IndexN              INT = 1,                          -- 1-based
    @ParentCodeInToken   NVARCHAR(100) = NULL              -- dùng khi SCOPE=BY_PARENT_CODE:<MaCha>
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT = NULL;
    IF @IndexN IS NULL OR @IndexN < 1 SET @IndexN = 1;

    DECLARE @FilterParentGUID UNIQUEIDENTIFIER = NULL;

    -- Xác định ParentGUID theo SCOPE
    IF @Scope = N'SAME_PARENT'
    BEGIN
        SET @FilterParentGUID = @CurrentParentGUID;
    END
    ELSE IF @Scope = N'BY_PARENT_CODE'
    BEGIN
        IF @ParentCodeInToken IS NOT NULL
        BEGIN
            SELECT TOP (1) @FilterParentGUID = ctb.CauTrucGUID
            FROM dbo.BCDT_CauTruc_BieuMau ctb
            WHERE ctb.BieuMauId=@BieuMauId AND ctb.DonViId=@DonViId AND ctb.KeHoachId=@KeHoachId
              AND ctb.BitDaXoa=0 AND ctb.MaTieuChi=@ParentCodeInToken
            ORDER BY ctb.SoThuTu; -- hoặc theo ExcelRow nếu muốn
        END
    END

    ;WITH Cands AS (
        SELECT pos.ExcelRow
        FROM dbo.BCDT_CauTruc_BieuMau c
        JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel pos
          ON pos.CauTrucGUID = c.CauTrucGUID
        WHERE c.BieuMauId=@BieuMauId AND c.DonViId=@DonViId AND c.KeHoachId=@KeHoachId
          AND c.BitDaXoa=0 AND c.MaTieuChi=@MaTieuChi
          AND (
                @Scope = N'ANY'
             OR (@Scope = N'SAME_PARENT'     AND (@FilterParentGUID IS NULL OR c.ParentCauTrucGUID = @FilterParentGUID))
             OR (@Scope = N'BY_PARENT_CODE'  AND (@FilterParentGUID IS NULL OR c.ParentCauTrucGUID = @FilterParentGUID))
          )
    ),
    Ordered AS (
        SELECT ExcelRow, ROW_NUMBER() OVER(ORDER BY ExcelRow ASC) AS rn
        FROM Cands
    )
    SELECT @Result = ExcelRow
    FROM Ordered
    WHERE rn = @IndexN;

    RETURN @Result;  -- NULL nếu không có ứng viên
END;

GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_Scope_ExpandCols]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[fn_BCDT_Scope_ExpandCols]
(
    @ScopeJson   NVARCHAR(MAX),   -- JSON trong cột BCDT_Bieu_TieuChi_CongThuc.ScopeJson
    @DefaultCol  NVARCHAR(8)      -- cột mặc định (map.ViTri_Cot hoặc pos.ExcelColumn)
)
RETURNS @Cols TABLE (Col NVARCHAR(8) NOT NULL)
AS
BEGIN
    DECLARE @Def NVARCHAR(8) = UPPER(LTRIM(RTRIM(@DefaultCol)));
    DECLARE @J NVARCHAR(MAX) = NULLIF(LTRIM(RTRIM(@ScopeJson)), '');

    -- Không có JSON hoặc JSON invalid -> giữ logic cũ: trả 1 cột mặc định
    IF @J IS NULL OR ISJSON(@J) = 0
    BEGIN
        INSERT INTO @Cols(Col) VALUES (@Def);
        RETURN;
    END

    ----------------------------------------------------------------
    -- 1) Nếu apply_cols có "ALL" hoặc "*" -> bung theo dải
    --    Dải chỉ định qua $.all_cols_range = "C:G"
    --    Nếu không có, mặc định "A:XFD"
    ----------------------------------------------------------------
    IF EXISTS (
        SELECT 1 FROM OPENJSON(@J, '$.apply_cols')
        WHERE UPPER(LTRIM(RTRIM([value]))) IN ('ALL','*')
    )
    BEGIN
        DECLARE @rng NVARCHAR(15) = NULLIF(LTRIM(RTRIM(JSON_VALUE(@J, '$.all_cols_range'))), '');
        DECLARE @from NVARCHAR(3), @to NVARCHAR(3);

        IF @rng IS NOT NULL AND CHARINDEX(':', @rng) > 0
        BEGIN
            SET @from = UPPER(LTRIM(RTRIM(LEFT(@rng, CHARINDEX(':', @rng)-1))));
            SET @to   = UPPER(LTRIM(RTRIM(SUBSTRING(@rng, CHARINDEX(':', @rng)+1, 10))));
        END
        ELSE
        BEGIN
            -- mặc định full Excel
            SET @from = 'A';
            SET @to   = 'XFD';
        END

        -- Chuẩn hoá: nếu from/to null/empty thì fallback
        IF (@from IS NULL OR @from = '') SET @from = 'A';
        IF (@to   IS NULL OR @to   = '') SET @to   = 'XFD';

        -- Chuyển tên cột -> chỉ số (A=1, ..., XFD=16384)
        ;WITH NameToIndex AS (
            SELECT
                @from AS FromName, @to AS ToName,
                CASE LEN(@from)
                    WHEN 1 THEN (UNICODE(@from)-64)
                    WHEN 2 THEN ((UNICODE(SUBSTRING(@from,1,1))-64)*26
                                +(UNICODE(SUBSTRING(@from,2,1))-64))
                    ELSE      ((UNICODE(SUBSTRING(@from,1,1))-64)*26*26
                              +(UNICODE(SUBSTRING(@from,2,1))-64)*26
                              +(UNICODE(SUBSTRING(@from,3,1))-64))
                END AS FromIdx,
                CASE LEN(@to)
                    WHEN 1 THEN (UNICODE(@to)-64)
                    WHEN 2 THEN ((UNICODE(SUBSTRING(@to,1,1))-64)*26
                                +(UNICODE(SUBSTRING(@to,2,1))-64))
                    ELSE      ((UNICODE(SUBSTRING(@to,1,1))-64)*26*26
                              +(UNICODE(SUBSTRING(@to,2,1))-64)*26
                              +(UNICODE(SUBSTRING(@to,3,1))-64))
                END AS ToIdx
        ),
        -- Tạo dãy số 1..16384 (không dùng đệ quy)
        B AS (SELECT 0 AS b UNION ALL SELECT 1),
        N7 AS (
            SELECT (b0.b
                + b1.b*2 + b2.b*4 + b3.b*8 + b4.b*16 + b5.b*32 + b6.b*64) AS n
            FROM B b0 CROSS JOIN B b1 CROSS JOIN B b2
            CROSS JOIN B b3 CROSS JOIN B b4 CROSS JOIN B b5 CROSS JOIN B b6
        ),
        Tally AS (
            SELECT (a.n*128 + b.n + 1) AS idx
            FROM N7 a CROSS JOIN N7 b       -- 128*128 = 16384
        ),
        Rang AS (
            SELECT
                CASE WHEN ni.FromIdx <= ni.ToIdx THEN ni.FromIdx ELSE ni.ToIdx END AS L,
                CASE WHEN ni.FromIdx <= ni.ToIdx THEN ni.ToIdx   ELSE ni.FromIdx END AS R
            FROM NameToIndex ni
        ),
        -- Chuyển chỉ số -> tên cột (1..16384 -> A..XFD)
        MapIdxToName AS (
            SELECT
                t.idx,
                -- t.idx -> (c3,c2,c1) trong hệ 26
                (t.idx - 1) / (26*26)                         AS c3,
                ((t.idx - 1) % (26*26)) / 26                  AS c2,
                ((t.idx - 1) % (26*26)) % 26                  AS c1
            FROM Tally t
        )
        INSERT INTO @Cols(Col)
        SELECT
            CASE
                WHEN c3 > 0
                    THEN CHAR(64 + c3) + CHAR(64 + c2) + CHAR(65 + c1)
                WHEN c2 > 0
                    THEN CHAR(64 + c2) + CHAR(65 + c1)
                ELSE CHAR(65 + c1)
            END AS ColName
        FROM MapIdxToName m
        CROSS JOIN Rang rg
        WHERE m.idx BETWEEN rg.L AND rg.R;

        -- Nếu range invalid → fallback về cột mặc định
        IF NOT EXISTS (SELECT 1 FROM @Cols)
            INSERT INTO @Cols(Col) VALUES (@Def);

        RETURN;
    END

    ----------------------------------------------------------------
    -- 2) Trường hợp thường: danh sách cột cụ thể (có thể chứa macro COL)
    ----------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM OPENJSON(@J, '$.apply_cols'))
    BEGIN
        INSERT INTO @Cols(Col)
        SELECT UPPER(
                   CASE UPPER(LTRIM(RTRIM([value])))
                        WHEN 'COL' THEN @Def
                        WHEN '{{COL}}' THEN @Def
                        WHEN 'THIS_COL' THEN @Def
                        WHEN '{{THIS_COL}}' THEN @Def
                        ELSE LTRIM(RTRIM([value]))
                   END
               )
        FROM OPENJSON(@J, '$.apply_cols');
    END

    -- Nếu không đổ được gì từ JSON -> fallback về cột mặc định
    IF NOT EXISTS (SELECT 1 FROM @Cols)
        INSERT INTO @Cols(Col) VALUES (@Def);

    RETURN;
END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_SiblingsRange]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [dbo].[fn_BCDT_SiblingsRange]
(
    @BieuMauId   INT,
    @DonViId     INT,
    @KeHoachId   INT,
    @ParentGUID  UNIQUEIDENTIFIER,
    @SheetName   NVARCHAR(128) = NULL,
    @Col         NVARCHAR(8)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @UCol NVARCHAR(8) = UPPER(LTRIM(RTRIM(@Col)));
    DECLARE @cnt INT, @minR INT, @maxR INT;

    SELECT 
        @cnt  = COUNT(*),
        @minR = MIN(p.ExcelRow),
        @maxR = MAX(p.ExcelRow)
    FROM dbo.BCDT_CauTruc_BieuMau s
    JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel p ON p.CauTrucGUID = s.CauTrucGUID
    LEFT JOIN dbo.BCDT_Bieu_TieuChi_CongThuc map
           ON map.BieuTieuChiId = s.BieuTieuChiId AND map.IsActive = 1 AND map.BitDaXoa = 0
    WHERE s.BieuMauId=@BieuMauId AND s.DonViId=@DonViId AND s.KeHoachId=@KeHoachId AND s.BitDaXoa=0
      AND s.ParentCauTrucGUID=@ParentGUID
      AND p.ExcelRow IS NOT NULL
      AND UPPER(COALESCE(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), ''), UPPER(LTRIM(RTRIM(p.ExcelColumn))))) = @UCol
      AND (@SheetName IS NULL OR map.SheetName=@SheetName);

    IF ISNULL(@cnt,0)=0 RETURN N'';

    IF @cnt = (@maxR - @minR + 1)
        RETURN @UCol + CAST(@minR AS NVARCHAR(10)) + ':' + @UCol + CAST(@maxR AS NVARCHAR(10));

    DECLARE @csv NVARCHAR(MAX);
    SELECT @csv = STUFF((
        SELECT ',' + @UCol + CAST(p.ExcelRow AS NVARCHAR(10))
        FROM dbo.BCDT_CauTruc_BieuMau s
        JOIN dbo.BCDT_CauTruc_BieuMau_ViTriExcel p ON p.CauTrucGUID = s.CauTrucGUID
        LEFT JOIN dbo.BCDT_Bieu_TieuChi_CongThuc map
               ON map.BieuTieuChiId = s.BieuTieuChiId AND map.IsActive = 1 AND map.BitDaXoa = 0
        WHERE s.BieuMauId=@BieuMauId AND s.DonViId=@DonViId AND s.KeHoachId=@KeHoachId AND s.BitDaXoa=0
          AND s.ParentCauTrucGUID=@ParentGUID
          AND p.ExcelRow IS NOT NULL
          AND UPPER(COALESCE(NULLIF(LTRIM(RTRIM(map.ViTri_Cot)), ''), UPPER(LTRIM(RTRIM(p.ExcelColumn))))) = @UCol
          AND (@SheetName IS NULL OR map.SheetName=@SheetName)
        ORDER BY p.ExcelRow
        FOR XML PATH(''), TYPE).value('.','nvarchar(max)')
    ,1,1,'');

    RETURN @csv;  -- KHÔNG có dấu '='
END

GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_StripTsqlLiteral]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Bóc vỏ N'...' hoặc '...' khỏi tên tham số
CREATE   FUNCTION [dbo].[fn_BCDT_StripTsqlLiteral] (@name NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @p NVARCHAR(MAX) = LTRIM(RTRIM(@name));
    IF @p IS NULL RETURN NULL;

    IF LEFT(@p,2)=N'N''' AND RIGHT(@p,1)=N''''
        SET @p = SUBSTRING(@p,3,LEN(@p)-3);
    ELSE IF LEFT(@p,1)=N'''' AND RIGHT(@p,1)=N''''
        SET @p = SUBSTRING(@p,2,LEN(@p)-2);

    RETURN @p;
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_GetCauTrucBieuMau]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		haidt
-- Create date: 06/10/2025
-- Description:	Báo cáo điện tử - Lấy cấu trúc biểu mẫu 
-- =============================================
CREATE   FUNCTION [dbo].[fn_BCDT_GetCauTrucBieuMau]
(	
	@donViId INT,
	@keHoachId INT,
	@maBieuMau NVARCHAR(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		bm.DonViId,
		bm.KeHoachId,
		bm.MaBieuMau,
		bm.BieuMauId,
		bm.MaTieuChi,
		bm.TieuChiId,
		bm.PathId AS Path,
		bm.SoThuTu,
		bm.SoThuTuHienThi,
		bm.SoThuTuBieuTieuChi,
		bm.TenTieuChi,
		bm.Style,
		bm.CauTrucGUID,
		bm.DonViTinh,
		bm.ColumnMerge,
		bm.BitDaXoa
	FROM dbo.BCDT_CauTruc_BieuMau bm
	WHERE (bm.DonViId IS NULL OR bm.DonViId = @donViId)
		AND bm.KeHoachId = @keHoachId
		AND bm.MaBieuMau = @maBieuMau
		AND bm.BitHieuLuc = 1
)
GO
/****** Object:  UserDefinedFunction [dbo].[fn_BCDT_Scope_ExpandCriteria]    Script Date: 1/26/2026 6:40:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_BCDT_Scope_ExpandCriteria]
(
    @ScopeJson NVARCHAR(MAX),
    @DefaultBieuTieuChiId INT,
    @BieuMauId INT,
    @DonViId   INT,
    @KeHoachId INT
)
RETURNS TABLE
AS
RETURN
WITH
J AS (
    SELECT CASE WHEN ISJSON(@ScopeJson)=1 THEN @ScopeJson ELSE N'{}' END AS J
),
-- scalar value (nếu apply_criteria là chuỗi/số đơn)
ScalarVal AS (
    SELECT 
        UPPER(NULLIF(LTRIM(RTRIM(JSON_VALUE(J.J,'$.apply_criteria'))),''))   AS s_val_upper,
        TRY_CAST(JSON_VALUE(J.J,'$.apply_criteria') AS INT)                  AS s_val_int
    FROM J
),
-- array values (nếu apply_criteria là mảng)
ApplyArr AS (
    SELECT TRY_CAST([value] AS NVARCHAR(50)) AS v
    FROM J
    CROSS APPLY OPENJSON(J.J, '$.apply_criteria')
),
-- exclude list (mảng)
Excl AS (
    SELECT TRY_CAST([value] AS INT) AS Id
    FROM J
    CROSS APPLY OPENJSON(J.J, '$.exclude_criteria')
),
-- Cờ ALL: đúng nếu scalar = 'ALL' hoặc mảng có 'ALL'
Flags AS (
    SELECT 
        CASE 
            WHEN (SELECT s_val_upper FROM ScalarVal) = 'ALL'
                 OR EXISTS (SELECT 1 FROM ApplyArr WHERE UPPER(v)='ALL')
            THEN 1 ELSE 0 
        END AS IsAll
),
-- Anchor: tiêu chí mặc định của rule thuộc BM hiện tại hay không?
Anchor AS (
    SELECT CASE WHEN EXISTS (
        SELECT 1
        FROM dbo.BCDT_Bieu_TieuChi x
        WHERE x.Id = @DefaultBieuTieuChiId
          AND x.BieuMauId = @BieuMauId
          AND x.BitDaXoa = 0
    ) THEN 1 ELSE 0 END AS IsAnchorInThisBM
),
-- Nếu ALL nhưng anchor không thuộc BM hiện tại => KHÔNG mở rộng (tra về rỗng)
Guard AS (
    SELECT CASE WHEN (SELECT IsAll FROM Flags)=1 AND (SELECT IsAnchorInThisBM FROM Anchor)=0
                THEN 1 ELSE 0 END AS BlockAll
),
-- Tập id tiêu chí được chỉ định dạng số trong mảng
ApplyIds AS (
    SELECT DISTINCT TRY_CAST(v AS INT) AS Id
    FROM ApplyArr
    WHERE TRY_CAST(v AS INT) IS NOT NULL
),
-- Nếu scalar là số đơn thì cũng cộng vào
ApplyUnion AS (
    SELECT Id FROM ApplyIds
    UNION 
    SELECT s_val_int FROM ScalarVal WHERE s_val_int IS NOT NULL
),
-- Ứng viên: ALL => mọi tiêu chí trong cấu trúc biểu; 
--           ngược lại => chỉ những id nêu ra (ApplyUnion)
Candidates AS (
    SELECT DISTINCT ctb.BieuTieuChiId
    FROM dbo.BCDT_CauTruc_BieuMau ctb
    CROSS JOIN Flags f
	CROSS JOIN Guard g
    WHERE g.BlockAll = 0
	  AND ctb.BieuMauId=@BieuMauId
      AND ctb.DonViId=@DonViId
      AND ctb.KeHoachId=@KeHoachId
      AND ctb.BitDaXoa=0
      AND (
            f.IsAll = 1
            OR ctb.BieuTieuChiId IN (SELECT Id FROM ApplyUnion)
          )
),
AfterExclude AS (
    SELECT c.BieuTieuChiId
    FROM Candidates c
    WHERE NOT EXISTS (SELECT 1 FROM Excl e WHERE e.Id = c.BieuTieuChiId)
),
Fallback AS (
    SELECT @DefaultBieuTieuChiId AS BieuTieuChiId
)
SELECT BieuTieuChiId
FROM (
    SELECT BieuTieuChiId FROM AfterExclude
    UNION ALL
    SELECT BieuTieuChiId FROM Fallback
    WHERE NOT EXISTS (SELECT 1 FROM AfterExclude)
) X;
GO
