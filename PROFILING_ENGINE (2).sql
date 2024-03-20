--SELECT * FROM SOW_DATA_CLEANSING_CONFIG
--select * from person
--SELECT * FROM SOW_DATA_CLEANSING_REPORT
--SELECT * FROM #PROFILE
-- DROP TABLE #PROFILE
-- DROP TABLE SOW_DATA_CLEANSING_REPORT
DECLARE @PROFILING_ID INT
	, @TNAME VARCHAR(250)
	, @CNAME VARCHAR(250)
	, @PRIMARY_KEY_COL_NAME VARCHAR(20)
	, @STMT		VARCHAR(4000)
	, @ERR_DESC VARCHAR(1000)
	, @ERROR_NO VARCHAR(10)
	, @IS_NULL_ALLOWED VARCHAR(3)
	, @FUTURE_DT_ALLOWED VARCHAR(3)
	, @MAX_LENGTH VARCHAR(2)
	, @Min_LENGTH VARCHAR(2)
	,@DUPLICATE_ALLOWED VARCHAR(3)
	,@MAX_VALUE VARCHAR(3)
	,@MIN_VALUE VARCHAR(3)
	,@SPL_CHAR VARCHAR(3)
	,@IS_PRINT CHAR(1)= 'Y'
	,@EMAIL VARCHAR(50)
	,@IS_NUMERIC VARCHAR(3)


DROP TABLE IF EXISTS #PROFILE
SELECT C.NAME AS PRIMARY_KEY_COL_NAME, CFG.*
INTO #PROFILE
FROM SOW_DATA_CLEANSING_CONFIG CFG
	JOIN SYS.OBJECTS O ON O.NAME = CFG.TABLE_NAME
	JOIN SYS.COLUMNS C ON C.OBJECT_ID = O.OBJECT_ID AND C.is_identity = 1
ORDER BY PROFILING_ID

TRUNCATE TABLE SOW_DATA_CLEANSING_REPORT;
 
SELECT TOP 1 @PROFILING_ID = PROFILING_ID, @TNAME = TABLE_NAME, @CNAME = COLUMN_NAME, @PRIMARY_KEY_COL_NAME = PRIMARY_KEY_COL_NAME, @IS_NULL_ALLOWED = IS_NULL_ALLOWED
	, @FUTURE_DT_ALLOWED = IS_FUTURE_DATE_ALLOWED, @MAX_LENGTH = MAX_LENGTH, @MIN_LENGTH = MIN_LENGTH, @DUPLICATE_ALLOWED  = DUPLICATE_ALLOWED, @MAX_VALUE = MAX_VALUE, @MIN_VALUE = MIN_VALUE, @SPL_CHAR = SPL_CHAR, @EMAIL = EMAIL, @IS_NUMERIC = IS_NUMERIC
FROM #PROFILE
ORDER BY PROFILING_ID

WHILE @PROFILING_ID IS NOT NULL
BEGIN
	
	---------------IS NULL ALLOWED-----------------------
	IF @IS_NULL_ALLOWED = 'NO'
	BEGIN
		SET @ERR_DESC ='Column is not nullable'
		SET @ERROR_NO = 'A-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE '+@CNAME+' IS NULL'
		EXECUTE (@STMT)
	END
	
	----IS_FUTURE_DATE_ALLOWED------------
	IF @FUTURE_DT_ALLOWED = 'NO'
	BEGIN
		SET @ERR_DESC ='Future Date not Allowed'
		SET @ERROR_NO = 'B-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE '+@CNAME+' > getdate()'
		EXECUTE (@STMT)
	END
	------MAX_LEGTH----------------------
		IF @MAX_LENGTH is not null
	BEGIN
		SET @ERR_DESC ='MAXIMUM LENGTH IS'  +@MAX_LENGTH
		SET @ERROR_NO = 'C-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE LEN('+@CNAME+') >' +@MAX_LENGTH
		EXECUTE (@STMT)
	END

	------Min_length---------------------
    IF @Min_LENGTH is not null
	BEGIN
		SET @ERR_DESC ='MINIMUM LENGTH IS'  +@MIN_LENGTH
		SET @ERROR_NO = 'D-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE LEN('+@CNAME+') <' +@MIN_LENGTH
		EXECUTE (@STMT)
	END

		------IS_DUPLICATE---------------------
   IF @DUPLICATE_ALLOWED = 'NO'
	BEGIN
		SET @ERR_DESC ='DUPLICATE VALUES NOT ALLOWED'
		SET @ERROR_NO = 'E-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+'''
		FROM (SELECT COUNT(*)OVER(PARTITION BY '+@CNAME+') AS DUPL_CNT, * 
		FROM '+@TNAME+') AS SQ
		WHERE DUPL_CNT > 1'
		PRINT @STMT
		EXECUTE (@STMT)
	END 


	----MAX_VAL----------------
	IF @MAX_VALUE is not null
	BEGIN
		SET @ERR_DESC ='MAXIMUM VALUE IS'  +@MAX_VALUE
		SET @ERROR_NO = 'F-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE ('+@CNAME+') >' +@MAX_VALUE
		EXECUTE (@STMT)
	END

		----MIN_VAL----------------
	IF @MIN_VALUE is not null
	BEGIN
		SET @ERR_DESC ='MINIMUM VALUE IS'  +@MIN_VALUE
		SET @ERROR_NO = 'G-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE ('+@CNAME+') <' +@MIN_VALUE
		EXECUTE (@STMT)
	END
	--------Special Charcters-------
			IF @SPL_CHAR = 'NO'
	BEGIN
		SET @ERR_DESC ='SHOULD NOT CONTAIN SPECIAL CHARACTERS' 
		SET @ERROR_NO = 'H-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE '+@TNAME+'.' +@CNAME+ ' NOT LIKE ''%[^a-zA-Z0-9]%'''
		IF @IS_PRINT = 'Y' PRINT @STMT
		EXECUTE (@STMT)
	END
---------EMAIL------------------------------------------
		IF @EMAIL = 'YES'
	BEGIN
		SET @ERR_DESC ='NOT VALID EMAIL' 
		SET @ERROR_NO = 'I-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE '+@TNAME+'.' +@CNAME+ ' NOT LIKE ''%_@__%.__%'' AND '+@TNAME+ '.'+@CNAME+ ' NOT LIKE ''%_@Q%.__%'''
		IF @IS_PRINT = 'Y' PRINT @STMT
		EXECUTE (@STMT)
	END 
	---------------IS_NUMERIC-----------------------------
		IF @IS_NUMERIC = 'NO'
	BEGIN
		SET @ERR_DESC ='SHOULD NOT CONTAIN NUMBERS' 
		SET @ERROR_NO = 'J-'+CAST(@PROFILING_ID AS VARCHAR(7))
		SET @STMT = 'INSERT INTO SOW_DATA_CLEANSING_REPORT (TABLE_NAME, PRIMARY_KEY_COL_NAME, PRIMARY_KEY_COL_VALUE, CLEANSING_COLUMN_NAME, ERR_DESC, ERROR_NO)'
		SET @STMT = @STMT+' SELECT '''+@TNAME+''', '''+@PRIMARY_KEY_COL_NAME+''', '+@PRIMARY_KEY_COL_NAME+', '''+@CNAME+''', '''+@ERR_DESC+''', '''+@ERROR_NO+''' FROM '+@TNAME+' WHERE PATINDEX (''%[0-9]%'', '+@CNAME+') >0'
		EXECUTE (@STMT)
	END
	----------EXIT WHILE------------
	IF EXISTS(SELECT 1 FROM #PROFILE WHERE PROFILING_ID > @PROFILING_ID)
	BEGIN
		SELECT TOP 1 @PROFILING_ID = PROFILING_ID, @TNAME = TABLE_NAME, @CNAME = COLUMN_NAME, @PRIMARY_KEY_COL_NAME = PRIMARY_KEY_COL_NAME, @IS_NULL_ALLOWED = IS_NULL_ALLOWED
			, @FUTURE_DT_ALLOWED = IS_FUTURE_DATE_ALLOWED, @max_length = max_length, @MIN_LENGTH = MIN_LENGTH, @DUPLICATE_ALLOWED = DUPLICATE_ALLOWED, @MAX_VALUE = MAX_VALUE, @MIN_VALUE = MIN_VALUE, @SPL_CHAR = SPL_CHAR, @EMAIL = EMAIL, @IS_NUMERIC= IS_NUMERIC
		FROM #PROFILE
		WHERE PROFILING_ID > @PROFILING_ID
		ORDER BY PROFILING_ID
	END
	ELSE
	BEGIN
		SET @PROFILING_ID = NULL
	END

	--EOP--------EXIT WHILE------------
END