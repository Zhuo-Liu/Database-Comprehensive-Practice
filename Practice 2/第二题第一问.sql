USE practice2
IF OBJECT_ID(N'dbo.schedule', N'U') IS NOT NULL DROP TABLE dbo.schedule;
GO


CREATE TABLE dbo.schedule
(
  order_num int not null primary key,
  trans_id int not null, -- t1 as 1, t2 as 2
  operation_type int not null,  -- read as 0, write as 1
  data_item int not null
);
GO

--与PPT上的一致
INSERT INTO dbo.schedule(order_num, trans_id, operation_type, data_item) values
  (1, 1, 0, 1),
  (2, 2, 1, 1),
  (3, 1, 1, 1);
GO

IF OBJECT_ID(N'dbo.tu', N'U') IS NOT NULL DROP TABLE dbo.tu;
GO


CREATE TABLE tu
(
 edge_num int identity(1,1) primary key,
 prior_tran int,
 posterior_tran int
)
GO

INSERT INTO dbo.tu
	SELECT a.trans_id, b.trans_id
	FROM dbo.schedule AS a, dbo.schedule AS b
	WHERE a.data_item = b.data_item AND (a.operation_type = 1 OR b.operation_type=1) AND b.order_num > a.order_num AND a.trans_id <> b.trans_id
GO

select * from tu

IF OBJECT_ID(N'dbo.LOOP_TABLE', N'TF') IS NOT NULL DROP FUNCTION dbo.LOOP_TABLE;
GO

CREATE FUNCTION dbo.LOOP_TABLE(@root AS INT)
RETURNS @loop TABLE
(
  prior_tran INT NOT NULL,
  poterior_tran INT NOT NULL,
  lvl   INT NOT NULL,
  path varchar(100),
  cycle INT
)
AS
BEGIN
	WITH SUBS
	AS
	(
	 SELECT DISTINCT prior_tran,posterior_tran, 0 AS lvl, CAST('.'+CAST(prior_tran AS VARCHAR(10))+ '.' AS VARCHAR(100)) AS path, 0 AS cycle
	 FROM dbo.tu
	 WHERE edge_num = @root

	 UNION ALL

	 SELECT C.prior_tran, C.posterior_tran, P.lvl + 1, CAST(P.path + CAST(C.prior_tran AS VARCHAR(10)) + '.' AS VARCHAR(100)),
		CASE WHEN P.path LIKE '%.' + CAST(C.prior_tran AS varchar(10)) + '.%' THEN 1 ELSE 0 END
	 FROM SUBS AS P INNER JOIN dbo.tu AS C ON C.prior_tran = P.posterior_tran AND P.cycle=0
	)
	INSERT INTO @loop
	SELECT *
	FROM SUBS

	RETURN;
END
GO

DECLARE @edge_num INT
DECLARE @SERIALIZABLE INT = 0
DECLARE mycursor CURSOR FOR SELECT edge_num FROM tu
OPEN mycursor
FETCH NEXT FROM mycursor INTO @edge_num
WHILE @@FETCH_STATUS =0 AND @SERIALIZABLE=0
BEGIN
	IF EXISTS(SELECT * FROM dbo.LOOP_TABLE(@edge_num) WHERE cycle =1)
		SET @SERIALIZABLE = 1
	FETCH NEXT FROM mycursor INTO @edge_num
END
CLOSE mycursor
DEALLOCATE mycursor
IF @SERIALIZABLE = 1
	PRINT 'NOT CONFLICT SERIALIZABLE'
ELSE
	PRINT 'CONFLICT SERIALIZABLE'
