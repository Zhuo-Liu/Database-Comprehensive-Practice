--CREATE FUNCTION dbo.GET_FATHERS_OR_SONS(@surname nvarchar(50), @father_or_son int)
--RETURNS @Results Table
--(
--	surname nvarchar(50) NOT NULL,
--	lvl int NOT NULL
--)
--AS
--BEGIN
---- father_or_son=0 ���Ҹ��ڵ�,��������ӽڵ�
--	IF @father_or_son = 0
--	  BEGIN
--		WITH TAB(����,����,curlevel)
--		AS
--		(
--		SELECT  ����,����,1 AS level 
--		FROM dbo.Surname
--		WHERE ����=@surname
--		UNION ALL
--		--�ݹ�����
--		SELECT a.����,a.����,b.curlevel + 1
--		FROM Surname a INNER JOIN TAB b ON (a.����=b.����) 
--		)
--		INSERT INTO @Results(surname,lvl) SELECT ����,curlevel FROM TAB
--	  END
--	ELSE
--	  BEGIN
--		WITH TAB(����,����,curlevel)
--		AS
--		(
--		SELECT  ����,����,1 AS level 
--		FROM dbo.Surname
--		WHERE ����=@surname
--		UNION ALL
--		--�ݹ�����
--		SELECT a.����,a.����,b.curlevel - 1
--		FROM Surname a INNER JOIN TAB b ON (a.����=b.����) 
--		)
--		INSERT INTO @Results(surname,lvl) SELECT ����,curlevel FROM TAB
--	  END
--	RETURN;
--END
--GO

--DECLARE @INPUT AS nvarchar(50) = '��'

--SELECT surname, lvl FROM dbo.GET_FATHERS_OR_SONS(@INPUT,0)

CREATE TABLE tu
(
 edge_num int primary key,
 prior_tran int,
 posterior_tran int
)
GO

INSERT INTO tu(edge_num, prior_tran, posterior_tran) VALUES(1, 1, 2)
INSERT INTO tu(edge_num, prior_tran, posterior_tran) VALUES(2, 2, 1)
GO

CREATE FUNCTION dbo.LOOP_OR_NOT()
RETURNS @loop TABLE
(
 num int NOT NULL
)
AS
BEGIN
	WITH TAB(prior_tran, posterior_tran)
	AS
	(
	 SELECT prior_tran,posterior_tran
	 FROM tu
	 WHERE edge_num = 1
	 UNION ALL

	 SELECT a.prior_tran, a.posterior_tran
	 FROM tu a INNER JOIN TAB b on (a.posterior_tran = b.prior_tran)
	)
	INSERT INTO @loop(num) SELECT prior_tran FROM TAB
   RETURN;
END
GO

SELECT * FROM dbo.LOOP_OR_NOT()