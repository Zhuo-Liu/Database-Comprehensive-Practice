--CREATE FUNCTION dbo.GET_FATHERS_OR_SONS(@surname nvarchar(50), @father_or_son int)
--RETURNS @Results Table
--(
--	surname nvarchar(50) NOT NULL,
--	lvl int NOT NULL
--)
--AS
--BEGIN
---- father_or_son=0 ²éÕÒ¸¸½Úµã,ÆäÓà²éÕÒ×Ó½Úµã
--	IF @father_or_son = 0
--	  BEGIN
--		WITH TAB(¸¸ÐÕ,×ÓÐÕ,curlevel)
--		AS
--		(
--		SELECT  ¸¸ÐÕ,×ÓÐÕ,1 AS level 
--		FROM dbo.Surname
--		WHERE ×ÓÐÕ=@surname
--		UNION ALL
--		--µÝ¹éÌõ¼þ
--		SELECT a.¸¸ÐÕ,a.×ÓÐÕ,b.curlevel + 1
--		FROM Surname a INNER JOIN TAB b ON (a.¸¸ÐÕ=b.×ÓÐÕ) 
--		)
--		INSERT INTO @Results(surname,lvl) SELECT ×ÓÐÕ,curlevel FROM TAB
--	  END
--	ELSE
--	  BEGIN
--		WITH TAB(×ÓÐÕ,¸¸ÐÕ,curlevel)
--		AS
--		(
--		SELECT  ×ÓÐÕ,¸¸ÐÕ,1 AS level 
--		FROM dbo.Surname
--		WHERE ¸¸ÐÕ=@surname
--		UNION ALL
--		--µÝ¹éÌõ¼þ
--		SELECT a.×ÓÐÕ,a.¸¸ÐÕ,b.curlevel - 1
--		FROM Surname a INNER JOIN TAB b ON (a.×ÓÐÕ=b.¸¸ÐÕ) 
--		)
--		INSERT INTO @Results(surname,lvl) SELECT ¸¸ÐÕ,curlevel FROM TAB
--	  END
--	RETURN;
--END
--GO

--DECLARE @INPUT AS nvarchar(50) = '¼§'

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