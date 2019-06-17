import MySQLdb
import os
import csv
import re
from collections import namedtuple


def createTables(cursor):
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


def split_title(title):
    # 切掉头尾的引号
    if re.match(r'^".+"$', title) != None or re.match(r"^'.+'$", title) != None:
        title = title[1:-1]
    year_reobj = re.search(r"\(\s*[0-9]{4}\s*\)\s*$", title)
    name = title[0:year_reobj.span(0)[0]].strip()
    year_str = year_reobj.group(0)
    year = int(re.search(r"[0-9]{4}", year_str).group(0))
    return (name, year)


if __name__ == "__main__":
    with open("Practice 3/Movie Len Code/pswd", "r") as f:
        pswd = f.read()

    db = MySQLdb.connect("localhost", "root", pswd, "MovieLen", charset="utf8")
    cursor = db.cursor()

    filepath = os.path.join("Practice 3", "ml-latest-small")

    with open(os.path.join(filepath, "movies.csv")) as f:
        movie_csv = csv.reader(f)
        headings = next(movie_csv)
        Row = namedtuple('Row', headings)
        print(headings)
