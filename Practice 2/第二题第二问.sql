USE practice2
IF OBJECT_ID(N'dbo.schedule_2',N'U') IS NOT NULL DROP TABLE dbo.schedule_2
GO

CREATE TABLE dbo.schedule_2
(
  order_num int not null primary key,
  trans_id int not null, -- t1 as 1, t2 as 2, t3 as 3
  operation_type int not null,  -- read as 0, write as 1
  data_item int not null
);
GO

--与PPT上的一致
INSERT INTO dbo.schedule_2(order_num, trans_id, operation_type, data_item) values
  (1, 1, 0, 1),
  (2, 2, 1, 1),
  (3, 3, 0, 1),
  (4, 1, 1, 1),
  (5, 3, 1, 1);
GO

-----------------------------------
------From_and_Read 表部分---------
-----------------------------------
-- 为了方便，暂时用100代表Tb，101代表Te
--------------------------
IF OBJECT_ID(N'dbo.From_and_Read',N'U') IS NOT NULL DROP TABLE dbo.From_and_Read
GO

CREATE TABLE dbo.From_and_Read
(
  From_tran int NOT NULL,
  Read_tran int NOT NULL
);
GO

INSERT INTO From_and_Read
	SELECT 100, trans_id --100 FOR Tb
	FROM schedule_2
	WHERE order_num=1
GO

INSERT INTO From_and_Read
	SELECT a.trans_id, b.trans_id
	FROM dbo.schedule_2 a, dbo.schedule_2 b
	WHERE b.operation_type = 0 AND a.operation_type =1 AND b.order_num > a.order_num AND b.data_item = a.data_item
GO

DECLARE @COUNT INT 
SELECT @COUNT = COUNT (*) FROM dbo.schedule_2
INSERT INTO From_and_Read
	SELECT trans_id,101 --101 For Te
	FROM schedule_2
	WHERE order_num=@COUNT
GO

select * from dbo.From_and_Read

IF OBJECT_ID(N'dbo.tu_part_1',N'U') IS NOT NULL DROP TABLE dbo.tu_part_1
GO

-----------------------------------
------有向图表部分---------
-----------------------------------

--这一部分是label为0的部分
CREATE TABLE dbo.tu_part_1
(
 --edge_num int identity(1,1) primary key,
 edge_label int NOT NULL,
 prior_tran int NOT NULL,
 posterior_tran int NOT NULL
);
GO

INSERT INTO tu_part_1(edge_label, prior_tran, posterior_tran)
	SELECT 0, From_tran, Read_tran
	FROM dbo.From_and_Read

INSERT INTO tu_part_1(edge_label, prior_tran, posterior_tran)
	SELECT distinct 0, b.trans_id, c.trans_id
	FROM dbo.From_and_Read AS a, dbo.schedule_2 AS b, dbo.schedule_2 AS c
	WHERE c.operation_type = 1 AND b.trans_id = a.Read_tran AND a.From_tran = 100 AND c.trans_id <> b.trans_id AND c.order_num > b.order_num

INSERT INTO tu_part_1(edge_label, prior_tran, posterior_tran)
	SELECT distinct 0, c.trans_id, b.trans_id
	FROM dbo.From_and_Read AS a, dbo.schedule_2 AS b, dbo.schedule_2 AS c
	WHERE c.operation_type = 1 AND b.trans_id = a.Read_tran AND a.Read_tran = 101 AND c.trans_id <> b.trans_id AND c.order_num > b.order_num

IF OBJECT_ID(N'dbo.tu_part_2',N'U') IS NOT NULL DROP TABLE dbo.tu_part_2
GO

--这一部分是label为1的部分
CREATE TABLE dbo.tu_part_2
(
 --edge_num int identity(1,1) primary key,
 edge_label int NOT NULL,
 prior_tran int NOT NULL,
 posterior_tran int NOT NULL
);
GO

INSERT INTO tu_part_2(edge_label, prior_tran, posterior_tran)
	SELECT distinct 1, c.trans_id, a.From_tran
	FROM dbo.From_and_Read AS a, dbo.schedule_2 AS b, dbo.schedule_2 AS c
	WHERE a.Read_tran <> 101 AND a.From_tran <>100 AND c.operation_type = 1 AND b.trans_id = a.Read_tran AND c.trans_id <> b.trans_id AND c.order_num > b.order_num

INSERT INTO tu_part_2(edge_label, prior_tran, posterior_tran)
	SELECT distinct 1, b.trans_id, c.trans_id
	FROM dbo.From_and_Read AS a, dbo.schedule_2 AS b, dbo.schedule_2 AS c
	WHERE a.Read_tran <> 101 AND a.From_tran <>100 AND c.operation_type = 1 AND b.trans_id = a.Read_tran AND c.trans_id <> b.trans_id AND c.order_num > b.order_num

IF OBJECT_ID(N'dbo.tu_2',N'U') IS NOT NULL DROP TABLE dbo.tu_2
GO

--这一部分是总的图，与PPT上的一致
CREATE TABLE dbo.tu_2
(
 edge_num int identity(1,1) primary key,
 edge_label int NOT NULL,
 prior_tran int NOT NULL,
 posterior_tran int NOT NULL
);
GO

INSERT INTO dbo.tu_2
SELECT * FROM tu_part_1

INSERT INTO dbo.tu_2
SELECT * FROM tu_part_2
GO

select * from dbo.tu_2

--临时表
IF OBJECT_ID(N'dbo.temp',N'U') IS NOT NULL DROP TABLE dbo.temp;

CREATE TABLE dbo.temp
(
	   prior_tran INT NOT NULL,
       posterior_tran INT NOT NULL
);

IF OBJECT_ID(N'dbo.LOOP_TABLE_2', N'TF') IS NOT NULL DROP FUNCTION dbo.LOOP_TABLE_2;
GO

--环路检测函数
CREATE FUNCTION dbo.LOOP_TABLE_2()
RETURNS @loop TABLE
(
  prior_tran INT NOT NULL,
  posterior_tran INT NOT NULL,
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
	 FROM dbo.temp
	 WHERE prior_tran = 100

	 UNION ALL

	 SELECT C.prior_tran, C.posterior_tran, P.lvl + 1, CAST(P.path + CAST(C.prior_tran AS VARCHAR(10)) + '.' AS VARCHAR(100)),
		CASE WHEN P.path LIKE '%.' + CAST(C.prior_tran AS varchar(10)) + '.%' THEN 1 ELSE 0 END
	 FROM SUBS AS P INNER JOIN dbo.temp AS C ON C.prior_tran = P.posterior_tran AND P.cycle=0
	)
	INSERT INTO @loop
	SELECT *
	FROM SUBS

	RETURN;
END
GO

--每次从LABEL为1的部分抽出一行来和LABEL为0的部分组成一个临时表，用函数判断是否有环，若环的数目和
--label为1的条目一样多，说明无论保留哪一个label为1的边，都是有环的，那么就是视图不可串行化
DECLARE @LOOP_COUNT INT = 0
DECLARE @COUNT INT
SELECT @COUNT = COUNT(*) FROM tu_part_2
DECLARE @prior_tran INT
DECLARE @posterior_tran INT
DECLARE @NUM INT = 1
DECLARE my_cursor CURSOR FOR SELECT prior_tran,posterior_tran FROM tu_part_2
OPEN my_cursor
FETCH NEXT FROM my_cursor INTO @prior_tran, @posterior_tran
WHILE @@FETCH_STATUS = 0 AND @NUM<@COUNT-1
BEGIN
	IF OBJECT_ID(N'dbo.temp',N'U') IS NOT NULL DROP TABLE dbo.temp;

	CREATE TABLE dbo.temp
	(
	   prior_tran INT NOT NULL,
       posterior_tran INT NOT NULL
	);
	
	INSERT INTO dbo.temp SELECT prior_tran, posterior_tran FROM dbo.tu_part_1
	INSERT INTO dbo.temp values (@prior_tran, @posterior_tran)

	IF EXISTS(SELECT * FROM dbo.LOOP_TABLE_2() WHERE cycle =1)
		SET @LOOP_COUNT += 1
	FETCH NEXT FROM my_cursor INTO @prior_tran, @posterior_tran
END
CLOSE my_cursor
DEALLOCATE my_cursor

IF @LOOP_COUNT = @COUNT
	PRINT 'NOT VIEW SERIALIZABLE'
ELSE
	PRINT 'VIEW SERIALIZABLE'