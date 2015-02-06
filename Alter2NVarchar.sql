USE tempdb
IF OBJECT_ID('tempdb..#TempTable') IS NOT NULL 
DROP TABLE #TempTable
create table #TempTable (TABLE_CATALOG nvarchar(max),TableName nvarchar(max),ColumnName nvarchar(max),DataType nvarchar(max),Size int,Nullable nvarchar(max),definition nvarchar(max),ConstraintName nvarchar(max),SQLCmd nvarchar(max))

DECLARE DBList CURSOR

FOR select 'exampleDB' as DBname
--------------------篩選條件打在上面這行--------------------

open DBList

DECLARE @DBname nvarchar(50)
DECLARE @cmd nvarchar(4000)

FETCH NEXT FROM DBList into @DBname
WHILE(@@FETCH_STATUS =0)
BEGIN

select @cmd ='
use '+@DBname +'
select INFORMATION_SCHEMA.COLUMNS.TABLE_CATALOG,
COLUMNS.TABLE_NAME AS TableName,COLUMNS.COLUMN_NAME AS ColumnName,DATA_TYPE AS DataType,max_length AS Size,
COLUMNS.IS_NULLABLE AS Nullable,definition,default_constraints.name AS ConstraintName,
CASE 
WHEN (DATA_TYPE=''varchar'' AND definition IS NULL) THEN
(''ALTER TABLE ''+COLUMNS.TABLE_NAME+'' ALTER COLUMN ''+COLUMNS.COLUMN_NAME+'' nvarchar(''+CAST(max_length as varchar)+'') ''+(CASE when COLUMNS.IS_NULLABLE=''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END))
WHEN (DATA_TYPE=''text'' AND definition IS NULL) THEN
(''ALTER TABLE ''+COLUMNS.TABLE_NAME+'' ALTER COLUMN ''+COLUMNS.COLUMN_NAME+'' nvarchar(max) ''+(CASE when COLUMNS.IS_NULLABLE=''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END)+'';ALTER TABLE ''+COLUMNS.TABLE_NAME+'' ALTER COLUMN ''+COLUMNS.COLUMN_NAME+'' ntext ''+(CASE when COLUMNS.IS_NULLABLE=''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END)+'';'')
WHEN (DATA_TYPE=''varchar'' AND definition IS NOT NULL) THEN
(''ALTER TABLE ''+COLUMNS.TABLE_NAME+'' DROP CONSTRAINT ''+default_constraints.name+'';ALTER TABLE ''+COLUMNS.TABLE_NAME+'' ALTER COLUMN ''+COLUMNS.COLUMN_NAME+'' nvarchar(''+CAST(max_length as varchar)+'') ''+(CASE when COLUMNS.IS_NULLABLE=''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END)+'';ALTER TABLE ''+COLUMNS.TABLE_NAME+'' add constraint ''+default_constraints.name+'' default ''+definition+'' for ''+COLUMNS.COLUMN_NAME+'';'')
WHEN (DATA_TYPE=''text'' AND definition IS NOT NULL) THEN
(''ALTER TABLE ''+COLUMNS.TABLE_NAME+'' DROP CONSTRAINT ''+default_constraints.name+'';ALTER TABLE ''+COLUMNS.TABLE_NAME+'' ALTER COLUMN ''+COLUMNS.COLUMN_NAME+'' nvarchar(max) ''+(CASE when COLUMNS.IS_NULLABLE=''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END)+'';ALTER TABLE ''+COLUMNS.TABLE_NAME+'' ALTER COLUMN ''+COLUMNS.COLUMN_NAME+'' ntext ''+(CASE when COLUMNS.IS_NULLABLE=''YES'' THEN ''NULL'' ELSE ''NOT NULL'' END)+'';ALTER TABLE ''+COLUMNS.TABLE_NAME+'' add constraint ''+default_constraints.name+'' default ''+definition+'' for ''+COLUMNS.COLUMN_NAME+'';'')
END as SQLCmd
FROM INFORMATION_SCHEMA.COLUMNS
LEFT JOIN sys.all_columns ON TABLE_NAME=OBJECT_NAME(object_id) and COLUMN_NAME=name
LEFT JOIN sys.default_constraints ON default_object_id=default_constraints.object_id
LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ON COLUMNS.TABLE_NAME=CONSTRAINT_COLUMN_USAGE.TABLE_NAME and COLUMNS.COLUMN_NAME=CONSTRAINT_COLUMN_USAGE.COLUMN_NAME
LEFT JOIN sys.views ON all_columns.object_id=views.object_id
WHERE INFORMATION_SCHEMA.COLUMNS.DATA_TYPE in (''varchar'',''text'')
and INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME !=''ser_no''
and CONSTRAINT_COLUMN_USAGE.TABLE_NAME IS NULL
and sys.views.object_id IS NULL'

INSERT INTO #TempTable EXECUTE sp_executesql @cmd

FETCH NEXT from DBList INTO @DBName
END

CLOSE DBList
DEALLOCATE DBList
----------------------愛的分隔線-----------------------
DECLARE CMDList CURSOR
FOR select TABLE_CATALOG,SQLCmd from #TempTable
open CMDList
FETCH NEXT FROM CMDList INTO @DBname,@cmd
WHILE(@@FETCH_STATUS =0)
BEGIN
DECLARE @temp nvarchar(max)
SET @temp='use '+@DBname+';'+@cmd+';'
EXEC sp_executesql @temp
FETCH NEXT from CMDList INTO @DBname,@cmd
END

CLOSE CMDList
DEALLOCATE CMDList
----------------------打完收功-----------------------
DROP TABLE #TempTable