create table Emp(
    eid int identity(1,1) primary key,
    did int identity(1,1)
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

create function find_bad_emp()
return int as
begin
return            
       (select count(*)
        from (select eid, did, salary 
              from Emp 
              where eid in (select managerid 
                            from Dept)) as M
        where exists(select salary
                     from Emp
                     where Emp.did = M.did and 
                          Emp.salary > M.salary))
End

alter table Emp
     add Constraint Check_mngSalary check (find_bad_emp() = 0)

