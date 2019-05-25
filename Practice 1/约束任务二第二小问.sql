create table Emp(
    eid int identity(1,1) primary key,
    ename varchar(10),
    age int,
    salary float
)
go

create table Dept(
    did int identity(1,1) primary key,
	budget float,
	managerid int
)
go

--´¥·¢Æ÷
CREATE TRIGGER UPDATE_BUDGET
ON Emp
AFTER UPDATE
AS
BEGIN
	DECLARE @old_salary float
	DECLARE @new_salary float
	SELECT @old_salary = salary FROM deleted 
	SELECT @new_salary = salary FROM inserted

	DECLARE @delta float
	SELECT @delta = @new_salary - @old_salary

	UPDATE Dept set budget = budget - @delta

END