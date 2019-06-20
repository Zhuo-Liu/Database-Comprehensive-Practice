import pymysql
import os


def recommend_for_user(userID, genres_range=3, rec_range=10):
    with open("Practice 3/Movie Len Code/pswd", "r") as f:
        pswd = f.read()
    db = pymysql.connect(host="127.0.0.1", port=3306,
                         user="root", passwd=pswd, db="MovieLen", charset="utf8")
    cursor = db.cursor()
    cursor.execute(
        f"""
        Select R.movieID, R.rating, G.genres
        From Ratings R
        Inner Join Genres G
        On R.movieID=G.movieID
        Where R.userID={str(userID)}
        Order By R.rating Desc;
        """
    )
    if cursor.rowcount == 0:
        db.close()
        return "No Rating Record!"

    movie_set = set()
    genres_set = set()
    genres_range = min(int(cursor.rowcount/10), genres_range)
    genres_range = max(genres_range, 1)
    for i in range(cursor.rowcount):
        res = cursor.fetchone()
        movie_set.add(res[0])
        if len(genres_set) < genres_range:
            genres_set.add(res[2])

    query_str = " or ".join([f'G.genres="{g}"' for g in genres_set])
    cursor.execute(
        f"""
        Select G.movieID, avg(R.rating) avg_rating
        From Genres G
            Inner Join Ratings R
            On G.movieID=R.movieID
        Where {query_str}
        Group By G.movieID
        Order By avg_rating Desc;
        """
    )

    rec_list = []
    for i in range(cursor.rowcount):
        res = cursor.fetchone()
        if res[0] not in rec_list and res[0] not in movie_set:
            rec_list.append(res[0])
        if len(rec_list) >= rec_range:
            break

    rec_title_list = []
    for movieID in rec_list:
        cursor.execute(
            f"""
            Select M.title From Movies M
            Where M.movieID={str(movieID)};
            """
        )
        res = cursor.fetchone()
        rec_title_list.append(res[0])

    db.close()
    return rec_title_list


if __name__ == "__main__":
    print(recommend_for_user(4))
