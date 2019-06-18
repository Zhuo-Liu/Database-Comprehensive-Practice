import MySQLdb
with open("Practice 3/Movie Len Code/pswd", "r") as f:
    pswd = f.read()

db = MySQLdb.connect("localhost", "root", pswd, "MovieLen", charset="utf8")
cursor = db.cursor()
Create_SQL = """
    Drop Table If Exists Users, Movies, Genres, Tags, Ratings;
    Create Table Users(
        userID BIGINT NOT NULL,
        PRIMARY KEY(userID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    Create Table Movies(
        movieID BIGINT NOT NULL,
        title VARCHAR(100) NOT NULL,
        pub_date INT NOT NULL,
        PRIMARY KEY (movieID)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    Create Table Genres(
        movieID BIGINT,
        genres VARCHAR(100),
        Foreign Key (movieID)
            References Movies(movieID)
            On Delete CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    Create Table Tags(
        userID BIGINT,
        movieID BIGINT,
        tag VARCHAR(100),
        time DATETIME,
        Foreign Key (userID)
            References Users(userID)
            On Delete CASCADE,
        Foreign Key (movieID)
            References Movies(movieID)
            On Delete CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    Create Table Ratings(
        userID BIGINT,
        movieID BIGINT,
        rating DECIMAL(1,1),
        time DATETIME,
        Foreign Key (userID)
            References Users(userID)
            On Delete CASCADE,
        Foreign Key (movieID)
            References Movies(movieID)
            On Delete CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    """
cursor.execute(Create_SQL)
