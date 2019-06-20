Load Data infile 
    'd:/学习工作/课程资料/大四下/数据库概论-陈立军/Database-Comprehensive-Practice/Practice 3/ml-latest/ratings.csv' 
    Ignore 
Into Table Users
    Fields Terminated by ',' 
    Lines Terminated by '\n'
Ignore 1 Lines
    (userID, @dummy, @dummy, @dummy);

Load Data infile 
    'd:/学习工作/课程资料/大四下/数据库概论-陈立军/Database-Comprehensive-Practice/Practice 3/ml-latest/ratings.csv' 
    Ignore 
Into Table Ratings
    Fields Terminated by ',' 
    Lines Terminated by '\n'
Ignore 1 Lines
(userID, movieID, rating, @var1)
Set time=FROM_UNIXTIME(@var1);