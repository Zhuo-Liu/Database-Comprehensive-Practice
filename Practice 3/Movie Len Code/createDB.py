import pymysql
import os
import csv
import re
from datetime import datetime
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
            title VARCHAR(150) NOT NULL,
            pub_date INT NOT NULL,
            PRIMARY KEY (movieID)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

        Create Table Genres(
            movieID BIGINT,
            genres VARCHAR(30),
            Foreign Key (movieID)
                References Movies(movieID)
                On Delete CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

        Create Table Tags(
            userID BIGINT,
            movieID BIGINT,
            tag VARCHAR(200),
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
            rating DECIMAL(2,1),
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
    year = re.search(r"[0-9]{4}", year_str).group(0)
    return (name, year)


def read_movie_data(db, cursor, filepath):
    with open(os.path.join(filepath, "movies.csv")) as f:
        movie_csv = csv.reader(f)
        headings = next(movie_csv)
        Row = namedtuple('Row', headings)
        for r in movie_csv:
            row = Row(*r)
            # print(row)

            try:
                movieID = str(row.movieId)
                name, year = split_title(row.title)
                print(movieID, name, year)
                cursor.execute(
                    f"""Insert Into Movies (movieID, title, pub_date)
                    Values ({movieID}, "{name}", {year})"""
                )
                db.commit()
            except:
                db.rollback()

            genres_list = row.genres.split('|')
            for genres in genres_list:
                try:
                    cursor.execute(
                        f"""Insert Ignore Into Genres (movieID, genres)
                            Values ({movieID}, "{genres.strip()}")
                        """
                    )
                    db.commit()
                except:
                    db.rollback()


def read_user_data(db, cursor, filepath):
    with open(os.path.join(filepath, "ratings.csv")) as f:
        rating_csv = csv.reader(f)
        headings = next(rating_csv)
        Row = namedtuple('Row', headings)
        print(headings)

        index = 0
        for r in rating_csv:
            row = Row(*r)

            userID = str(row.userId)
            index += 1
            if index % 10000 == 0:
                print(index, ":", userID)

            try:
                cursor.execute(
                    f"""
                        Insert Ignore Into Users (userID)
                        Values({userID})
                        """
                )
                db.commit()
            except:
                db.rollback()


def read_tag_data(db, cursor, filepath):
    with open(os.path.join(filepath, "tags.csv")) as f:
        tag_csv = csv.reader(f)
        headings = next(tag_csv)
        Row = namedtuple('Row', headings)
        print(headings)

        for r in tag_csv:
            row = Row(*r)

            userID = str(row.userId)
            date_str = str(datetime.fromtimestamp(int(row.timestamp)))
            movieID, tag = str(row.movieId), str(row.tag)
            print(userID, movieID, tag, date_str)
            try:
                cursor.execute(
                    f"""
                    Insert Ignore Into Users (userID)
                    Values({userID})
                    """
                )
                db.commit()
            except:
                db.rollback()
            try:
                cursor.execute(
                    f"""
                    Insert Ignore Into Tags (userID, movieID, tag, time)
                    Values({userID}, {movieID}, "{tag}", "{date_str}")
                    """
                )
                db.commit()
            except:
                db.rollback()


def read_rating_data(db, cursor, filepath):
    with open(os.path.join(filepath, "ratings.csv")) as f:
        rating_csv = csv.reader(f)
        headings = next(rating_csv)
        Row = namedtuple('Row', headings)
        print(headings)

        for r in rating_csv:
            row = Row(*r)

            userID = str(row.userId)
            date_str = str(datetime.fromtimestamp(int(row.timestamp)))
            movieID, rating = str(row.movieId), str(row.rating)
            print(userID, movieID, rating, date_str)

            try:
                cursor.execute(
                    f"""
                    Insert Ignore Into Users (userID)
                    Values({userID})
                    """
                )
                db.commit()
            except:
                db.rollback()

            try:
                cursor.execute(
                    f"""
                    Insert Ignore Into Ratings (userID, movieID, rating, time)
                    Values({userID}, {movieID}, {rating}, "{date_str}")
                    """
                )
                db.commit()
                print(userID, movieID, rating, date_str)
            except:
                db.rollback()


if __name__ == "__main__":
    with open("Practice 3/Movie Len Code/pswd", "r") as f:
        pswd = f.read()

    db = pymysql.connect("localhost", "root", pswd, "MovieLen", charset="utf8")
    cursor = db.cursor()

    filepath = os.path.join("Practice 3", "ml-latest")
    # createTables(cursor)
    # read_movie_data(db, cursor, filepath)
    # read_tag_data(db, cursor, filepath)
    # read_rating_data(db, cursor, filepath)
    read_user_data(db, cursor, filepath)

    db.close()
