

----------------------------------------------------------------------
-- Max Concurrent Sessions
----------------------------------------------------------------------

-- Creating and Populating Sessions
SET NOCOUNT ON;
USE TSQL2012;

IF OBJECT_ID('dbo.Sessions', 'U') IS NOT NULL DROP TABLE dbo.Sessions;

CREATE TABLE dbo.Sessions
(
  keycol    INT         NOT NULL,
  app       VARCHAR(10) NOT NULL,
  usr       VARCHAR(10) NOT NULL,
  host      VARCHAR(10) NOT NULL,
  starttime DATETIME    NOT NULL,
  endtime   DATETIME    NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(keycol),
  CHECK(endtime > starttime)
);
GO

CREATE UNIQUE INDEX idx_nc_app_st_et ON dbo.Sessions(app, starttime, keycol) INCLUDE(endtime);
CREATE UNIQUE INDEX idx_nc_app_et_st ON dbo.Sessions(app, endtime, keycol) INCLUDE(starttime);

-- small set of sample data
TRUNCATE TABLE dbo.Sessions;

INSERT INTO dbo.Sessions(keycol, app, usr, host, starttime, endtime) VALUES
  (2,  'app1', 'user1', 'host1', '20120212 08:30', '20120212 10:30'),
  (3,  'app1', 'user2', 'host1', '20120212 08:30', '20120212 08:45'),
  (5,  'app1', 'user3', 'host2', '20120212 09:00', '20120212 09:30'),
  (7,  'app1', 'user4', 'host2', '20120212 09:15', '20120212 10:30'),
  (11, 'app1', 'user5', 'host3', '20120212 09:15', '20120212 09:30'),
  (13, 'app1', 'user6', 'host3', '20120212 10:30', '20120212 14:30'),
  (17, 'app1', 'user7', 'host4', '20120212 10:45', '20120212 11:30'),
  (19, 'app1', 'user8', 'host4', '20120212 11:00', '20120212 12:30'),
  (23, 'app2', 'user8', 'host1', '20120212 08:30', '20120212 08:45'),
  (29, 'app2', 'user7', 'host1', '20120212 09:00', '20120212 09:30'),
  (31, 'app2', 'user6', 'host2', '20120212 11:45', '20120212 12:00'),
  (37, 'app2', 'user5', 'host2', '20120212 12:30', '20120212 14:00'),
  (41, 'app2', 'user4', 'host3', '20120212 12:45', '20120212 13:30'),
  (43, 'app2', 'user3', 'host3', '20120212 13:00', '20120212 14:00'),
  (47, 'app2', 'user2', 'host4', '20120212 14:00', '20120212 16:30'),
  (53, 'app2', 'user1', 'host4', '20120212 15:30', '20120212 17:00');
GO

/*
app        mx
---------- -----------
app1       3
app2       4
*/

-- large set of sample data
TRUNCATE TABLE dbo.Sessions;

DECLARE 
  @numrows AS INT = 100000, -- total number of rows 
  @numapps AS INT = 10;     -- number of applications

INSERT INTO dbo.Sessions WITH(TABLOCK)
    (keycol, app, usr, host, starttime, endtime)
  SELECT
    ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS keycol, 
    D.*,
    DATEADD(
      second,
      1 + ABS(CHECKSUM(NEWID())) % (20*60),
      starttime) AS endtime
  FROM
  (
    SELECT 
      'app' + CAST(1 + ABS(CHECKSUM(NEWID())) % @numapps AS VARCHAR(10)) AS app,
      'user1' AS usr,
      'host1' AS host,
      DATEADD(
        second,
        1 + ABS(CHECKSUM(NEWID())) % (30*24*60*60),
        '20120101') AS starttime
    FROM dbo.GetNums(1, @numrows) AS Nums
  ) AS D;
GO

-- Traditional set-based solution
WITH TimePoints AS 
(
  SELECT app, starttime AS ts FROM dbo.Sessions
),
Counts AS
(
  SELECT app, ts,
    (SELECT COUNT(*)
     FROM dbo.Sessions AS S
     WHERE P.app = S.app
       AND P.ts >= S.starttime
       AND P.ts < S.endtime) AS concurrent
  FROM TimePoints AS P
)      
SELECT app, MAX(concurrent) AS mx
FROM Counts
GROUP BY app;

-- query used by cursor solution
SELECT app, starttime AS ts, +1 AS type
FROM dbo.Sessions
  
UNION ALL
  
SELECT app, endtime, -1
FROM dbo.Sessions
  
ORDER BY app, ts, type;

/*
app        ts                      type
---------- ----------------------- -----------
app1       2012-02-12 08:30:00.000 1
app1       2012-02-12 08:30:00.000 1
app1       2012-02-12 08:45:00.000 -1
app1       2012-02-12 09:00:00.000 1
app1       2012-02-12 09:15:00.000 1
app1       2012-02-12 09:15:00.000 1
app1       2012-02-12 09:30:00.000 -1
app1       2012-02-12 09:30:00.000 -1
app1       2012-02-12 10:30:00.000 -1
app1       2012-02-12 10:30:00.000 -1
...
*/

-- cursor-based solution
DECLARE
  @app AS varchar(10), 
  @prevapp AS varchar (10),
  @ts AS datetime,
  @type AS int,
  @concurrent AS int, 
  @mx AS int;

DECLARE @AppsMx TABLE
(
  app varchar (10) NOT NULL PRIMARY KEY,
  mx int NOT NULL
);

DECLARE sessions_cur CURSOR FAST_FORWARD FOR
  SELECT app, starttime AS ts, +1 AS type
  FROM dbo.Sessions
  
  UNION ALL
  
  SELECT app, endtime, -1
  FROM dbo.Sessions
  
  ORDER BY app, ts, type;

OPEN sessions_cur;

FETCH NEXT FROM sessions_cur
  INTO @app, @ts, @type;

SET @prevapp = @app;
SET @concurrent = 0;
SET @mx = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @app <> @prevapp
  BEGIN
    INSERT INTO @AppsMx VALUES(@prevapp, @mx);
    SET @concurrent = 0;
    SET @mx = 0;
    SET @prevapp = @app;
  END

  SET @concurrent = @concurrent + @type;
  IF @concurrent > @mx SET @mx = @concurrent;
  
  FETCH NEXT FROM sessions_cur
    INTO @app, @ts, @type;
END

IF @prevapp IS NOT NULL
  INSERT INTO @AppsMx VALUES(@prevapp, @mx);

CLOSE sessions_cur;

DEALLOCATE sessions_cur;

SELECT * FROM @AppsMx;
GO

-- solution using window aggregate function
WITH C1 AS
(
  SELECT app, starttime AS ts, +1 AS type
  FROM dbo.Sessions

  UNION ALL

  SELECT app, endtime, -1
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    SUM(type) OVER(PARTITION BY app ORDER BY ts, type
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cnt
  FROM C1
)
SELECT app, MAX(cnt) AS mx
FROM C2
GROUP BY app;

-- solution using ROW_NUMBER
WITH C1 AS
(
  SELECT app, starttime AS ts, +1 AS type, keycol,
    ROW_NUMBER() OVER(PARTITION BY app ORDER BY starttime, keycol) AS start_ordinal
  FROM dbo.Sessions

  UNION ALL

  SELECT app, endtime, -1, keycol, NULL
  FROM dbo.Sessions
),
C2 AS
(
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY app ORDER BY ts, type, keycol) AS start_or_end_ordinal
  FROM C1
)
SELECT app, MAX(start_ordinal - (start_or_end_ordinal - start_ordinal)) AS mx
FROM C2
GROUP BY app;

----------------------------------------------------------------------
-- Packing Intervals
----------------------------------------------------------------------

-- code to create and populate Sessions and Users tables
SET NOCOUNT ON;
USE TSQL2012;

IF OBJECT_ID('dbo.Sessions') IS NOT NULL DROP TABLE dbo.Sessions;
IF OBJECT_ID('dbo.Users') IS NOT NULL DROP TABLE dbo.Users;

CREATE TABLE dbo.Users
(
  username  VARCHAR(14)  NOT NULL,
  CONSTRAINT PK_Users PRIMARY KEY(username)
);
GO

INSERT INTO dbo.Users(username) VALUES('User1'), ('User2'), ('User3');

CREATE TABLE dbo.Sessions
(
  id        INT          NOT NULL IDENTITY(1, 1),
  username  VARCHAR(14)  NOT NULL,
  starttime DATETIME2(3) NOT NULL,
  endtime   DATETIME2(3) NOT NULL,
  CONSTRAINT PK_Sessions PRIMARY KEY(id),
  CONSTRAINT CHK_endtime_gteq_starttime
    CHECK (endtime >= starttime)
);
GO

INSERT INTO dbo.Sessions(username, starttime, endtime) VALUES
  ('User1', '20121201 08:00:00.000', '20121201 08:30:00.000'),
  ('User1', '20121201 08:30:00.000', '20121201 09:00:00.000'),
  ('User1', '20121201 09:00:00.000', '20121201 09:30:00.000'),
  ('User1', '20121201 10:00:00.000', '20121201 11:00:00.000'),
  ('User1', '20121201 10:30:00.000', '20121201 12:00:00.000'),
  ('User1', '20121201 11:30:00.000', '20121201 12:30:00.000'),
  ('User2', '20121201 08:00:00.000', '20121201 10:30:00.000'),
  ('User2', '20121201 08:30:00.000', '20121201 10:00:00.000'),
  ('User2', '20121201 09:00:00.000', '20121201 09:30:00.000'),
  ('User2', '20121201 11:00:00.000', '20121201 11:30:00.000'),
  ('User2', '20121201 11:32:00.000', '20121201 12:00:00.000'),
  ('User2', '20121201 12:04:00.000', '20121201 12:30:00.000'),
  ('User3', '20121201 08:00:00.000', '20121201 09:00:00.000'),
  ('User3', '20121201 08:00:00.000', '20121201 08:30:00.000'),
  ('User3', '20121201 08:30:00.000', '20121201 09:00:00.000'),
  ('User3', '20121201 09:30:00.000', '20121201 09:30:00.000');
GO

-- desired results
/*
username  starttime               endtime
--------- ----------------------- -----------------------
User1     2012-12-01 08:00:00.000 2012-12-01 09:30:00.000
User1     2012-12-01 10:00:00.000 2012-12-01 12:30:00.000
User2     2012-12-01 08:00:00.000 2012-12-01 10:30:00.000
User2     2012-12-01 11:00:00.000 2012-12-01 11:30:00.000
User2     2012-12-01 11:32:00.000 2012-12-01 12:00:00.000
User2     2012-12-01 12:04:00.000 2012-12-01 12:30:00.000
User3     2012-12-01 08:00:00.000 2012-12-01 09:00:00.000
User3     2012-12-01 09:30:00.000 2012-12-01 09:30:00.000
*/

-- Large Set of Sample Data
-- 2,000 users, 5,000,000 intervals
DECLARE 
  @num_users          AS INT          = 2000,
  @intervals_per_user AS INT          = 2500,
  @start_period       AS DATETIME2(3) = '20120101',
  @end_period         AS DATETIME2(3) = '20120107',
  @max_duration_in_ms AS INT  = 3600000; -- 60 minutes
  
TRUNCATE TABLE dbo.Sessions;
TRUNCATE TABLE dbo.Users;

INSERT INTO dbo.Users(username)
  SELECT 'User' + RIGHT('000000000' + CAST(U.n AS VARCHAR(10)), 10) AS username
  FROM dbo.GetNums(1, @num_users) AS U;

WITH C AS
(
  SELECT 'User' + RIGHT('000000000' + CAST(U.n AS VARCHAR(10)), 10) AS username,
      DATEADD(ms, ABS(CHECKSUM(NEWID())) % 86400000,
        DATEADD(day, ABS(CHECKSUM(NEWID())) % DATEDIFF(day, @start_period, @end_period), @start_period)) AS starttime
  FROM dbo.GetNums(1, @num_users) AS U
    CROSS JOIN dbo.GetNums(1, @intervals_per_user) AS I
)
INSERT INTO dbo.Sessions WITH (TABLOCK) (username, starttime, endtime)
  SELECT username, starttime,
    DATEADD(ms, ABS(CHECKSUM(NEWID())) % (@max_duration_in_ms + 1), starttime) AS endtime
  FROM C;
GO

-- indexes for traditional solution
/*
CREATE INDEX idx_user_start_end ON dbo.Sessions(username, starttime, endtime);
CREATE INDEX idx_user_end_start ON dbo.Sessions(username, endtime, starttime);
*/

-- traditional solution
-- run time: several hours (need to test again in SQL Server 2012)

-- traditional solution
WITH StartTimes AS
(
  SELECT DISTINCT username, starttime
  FROM dbo.Sessions AS S1
  WHERE NOT EXISTS
    (SELECT * FROM dbo.Sessions AS S2
     WHERE S2.username = S1.username
       AND S2.starttime < S1.starttime
       AND S2.endtime >= S1.starttime)
),
EndTimes AS
(
  SELECT DISTINCT username, endtime
  FROM dbo.Sessions AS S1
  WHERE NOT EXISTS
    (SELECT * FROM dbo.Sessions AS S2
     WHERE S2.username = S1.username
       AND S2.endtime > S1.endtime
       AND S2.starttime <= S1.endtime)
)
SELECT username, starttime,
  (SELECT MIN(endtime) FROM EndTimes AS E
   WHERE E.username = S.username
     AND endtime >= starttime) AS endtime
FROM StartTimes AS S;

-- cleanup indexes for traditional solution
/*
DROP INDEX idx_user_start_end ON dbo.Sessions;
DROP INDEX idx_user_end_start ON dbo.Sessions;
*/

-- indexes for solutions based on window functions
CREATE UNIQUE INDEX idx_user_start_id ON dbo.Sessions(username, starttime, id);
CREATE UNIQUE INDEX idx_user_end_id ON dbo.Sessions(username, endtime, id);

-- Listing 5-1: Packing Intervals Using Row Numbers
-- run time: 47 seconds

WITH C1 AS
-- let e = end ordinals, let s = start ordinals
(
  SELECT id, username, starttime AS ts, +1 AS type, NULL AS e,
    ROW_NUMBER() OVER(PARTITION BY username ORDER BY starttime, id) AS s
  FROM dbo.Sessions

  UNION ALL

  SELECT id, username, endtime AS ts, -1 AS type, 
    ROW_NUMBER() OVER(PARTITION BY username ORDER BY endtime, id) AS e,
    NULL AS s
  FROM dbo.Sessions
),
C2 AS
-- let se = start or end ordinal, namely, how many events (start or end) happened so far
(
  SELECT C1.*, ROW_NUMBER() OVER(PARTITION BY username ORDER BY ts, type DESC, id) AS se
  FROM C1
),
C3 AS
-- For start events, the expression s - (se - s) - 1 represents how many sessions were active
-- just before the current (hence - 1)
--
-- For end events, the expression (se - e) - e represents how many sessions are active
-- right after this one
--
-- The above two expressions are 0 exactly when a group of packed intervals 
-- either starts or ends, respectively
--
-- After filtering only events when a group of packed intervals either starts or ends,
-- group each pair of adjacent start/end events
(
  SELECT username, ts, 
    FLOOR((ROW_NUMBER() OVER(PARTITION BY username ORDER BY ts) - 1) / 2 + 1) AS grpnum
  FROM C2
  WHERE COALESCE(s - (se - s) - 1, (se - e) - e) = 0
)
SELECT username, MIN(ts) AS starttime, max(ts) AS endtime
FROM C3
GROUP BY username, grpnum;

-- solution using row numbers and APPLY to exploit parallelism

-- inline table function encapsulating logic from solution in listing 2 for single user
IF OBJECT_ID('dbo.UserIntervals', 'IF') IS NOT NULL DROP FUNCTION dbo.UserIntervals;
GO

CREATE FUNCTION dbo.UserIntervals(@user AS VARCHAR(14)) RETURNS TABLE
AS
RETURN
  WITH C1 AS
  (
    SELECT id, starttime AS ts, +1 AS type, NULL AS e,
      ROW_NUMBER() OVER(ORDER BY starttime, id) AS s
    FROM dbo.Sessions
    WHERE username = @user

    UNION ALL

    SELECT id, endtime AS ts, -1 AS type, 
      ROW_NUMBER() OVER(ORDER BY endtime, id) AS e,
      NULL AS s
    FROM dbo.Sessions
    WHERE username = @user
  ),
  C2 AS
  (
    SELECT C1.*, ROW_NUMBER() OVER(ORDER BY ts, type DESC, id) AS se
    FROM C1
  ),
  C3 AS
  (
    SELECT ts, 
      FLOOR((ROW_NUMBER() OVER(ORDER BY ts) - 1) / 2 + 1) AS grpnum
    FROM C2
    WHERE COALESCE(s - (se - s) - 1, (se - e) - e) = 0
  )
  SELECT MIN(ts) AS starttime, max(ts) AS endtime
  FROM C3
  GROUP BY grpnum;
GO

-- Solution Using APPLY and Row Numbers
-- run time: 6 seconds
SELECT U.username, A.starttime, A.endtime
FROM dbo.Users AS U
  CROSS APPLY dbo.UserIntervals(U.username) AS A;

-- Listing 5-2: Solution Using Window Aggregate
-- run time: 83 seconds
WITH C1 AS
(
  SELECT username, starttime AS ts, +1 AS type, 1 AS sub
  FROM dbo.Sessions

  UNION ALL

  SELECT username, endtime AS ts, -1 AS type, 0 AS sub
  FROM dbo.Sessions
),
C2 AS
(
  SELECT C1.*,
    SUM(type) OVER(PARTITION BY username ORDER BY ts, type DESC
                   ROWS BETWEEN UNBOUNDED PRECEDING
                            AND CURRENT ROW) - sub AS cnt
  FROM C1
),
C3 AS
(
  SELECT username, ts, 
    FLOOR((ROW_NUMBER() OVER(PARTITION BY username ORDER BY ts) - 1) / 2 + 1) AS grpnum
  FROM C2
  WHERE cnt = 0
)
SELECT username, MIN(ts) AS starttime, max(ts) AS endtime
FROM C3
GROUP BY username, grpnum;

-- inline table function encapsulating logic from solution in listing 1 for single user
IF OBJECT_ID('dbo.UserIntervals', 'IF') IS NOT NULL DROP FUNCTION dbo.UserIntervals;
GO

CREATE FUNCTION dbo.UserIntervals(@user AS VARCHAR(14)) RETURNS TABLE
AS
RETURN
  WITH C1 AS
  (
    SELECT starttime AS ts, +1 AS type, 1 AS sub
    FROM dbo.Sessions
    WHERE username = @user

    UNION ALL

    SELECT endtime AS ts, -1 AS type, 0 AS sub
    FROM dbo.Sessions
    WHERE username = @user
  ),
  C2 AS
  (
    SELECT C1.*,
      SUM(type) OVER(ORDER BY ts, type DESC
                     ROWS BETWEEN UNBOUNDED PRECEDING
                              AND CURRENT ROW) - sub AS cnt
    FROM C1
  ),
  C3 AS
  (
    SELECT ts, 
      FLOOR((ROW_NUMBER() OVER(ORDER BY ts) - 1) / 2 + 1) AS grpnum
    FROM C2
    WHERE cnt = 0
  )
  SELECT MIN(ts) AS starttime, max(ts) AS endtime
  FROM C3
  GROUP BY grpnum;
GO

-- Solution Using APPLY and Window Aggregate
-- run time: 13 seconds
SELECT U.username, A.starttime, A.endtime
FROM dbo.Users AS U
  CROSS APPLY dbo.UserIntervals(U.username) AS A;

