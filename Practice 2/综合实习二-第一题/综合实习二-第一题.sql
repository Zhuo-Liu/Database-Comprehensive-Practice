USE practice2
IF OBJECT_ID(N'dbo.GET_FATHERS_OR_SONS', N'TF') IS NOT NULL DROP FUNCTION dbo.GET_FATHERS_OR_SONS;
GO

CREATE FUNCTION dbo.GET_FATHERS_OR_SONS(@surname nvarchar(50), @father_or_son int)
RETURNS @Results Table
(
	surname nvarchar(50) NOT NULL,
	lvl int NOT NULL
)
AS
BEGIN
-- father_or_son=0 ���Ҹ��ڵ�,��������ӽڵ�
	IF @father_or_son = 0
	  BEGIN
		WITH TAB(����,����,curlevel)
		AS
		(
		SELECT  ����,����,1 AS level 
		FROM dbo.Surname
		WHERE ����=@surname
		UNION ALL
		--�ݹ�����
		SELECT a.����,a.����,b.curlevel + 1
		FROM Surname a INNER JOIN TAB b ON (a.����=b.����) 
		)
		INSERT INTO @Results(surname,lvl) SELECT ����,curlevel FROM TAB
	  END
	ELSE
	  BEGIN
		WITH TAB(����,����,curlevel)
		AS
		(
		SELECT  ����,����,1 AS level 
		FROM dbo.Surname
		WHERE ����=@surname
		UNION ALL
		--�ݹ�����
		SELECT a.����,a.����,b.curlevel - 1
		FROM Surname a INNER JOIN TAB b ON (a.����=b.����) 
		)
		INSERT INTO @Results(surname,lvl) SELECT ����,curlevel FROM TAB
	  END
	RETURN;
END
GO

DECLARE @INPUT AS nvarchar(50) = '��'

SELECT surname, lvl FROM dbo.GET_FATHERS_OR_SONS(@INPUT,0)