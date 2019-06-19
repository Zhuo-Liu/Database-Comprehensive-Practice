import pymysql
import os
import logging

from surprise import KNNBaseline
from surprise import KNNBasic
from surprise import Dataset
from surprise import Reader
from surprise import dump

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                    datefmt='%a, %d %b %Y %H:%M:%S')


def get_model(re_train=False):
    algopath = os.path.join("Practice 3", "Movie Len Code", "kNNBaseline.algo")
    if not re_train and os.path.exists(algopath):
        logging.debug("Retrieving existed Model")
        algo = dump.load(algopath)[1]
        return algo

    filepath = os.path.join("Practice 3", "ml-latest-small", "ratings.csv")
    reader = Reader(line_format="user item rating timestamp",
                    sep=",", skip_lines=1)
    data = Dataset.load_from_file(filepath, reader=reader)
    trainset = data.build_full_trainset()
    # print("train")
    sim_options = {'name': 'pearson_baseline', 'user_based': False}
    algo = KNNBaseline(sim_options=sim_options)
    algo.train(trainset)

    dump.dump(algopath, algo=algo, verbose=1)
    return algo


def recommend_for_movie(algo, movieID):
    with open("Practice 3/Movie Len Code/pswd", "r") as f:
        pswd = f.read()
    db = pymysql.connect(host="127.0.0.1", port=3306,
                         user="root", passwd=pswd, db="MovieLen", charset="utf8")
    cursor = db.cursor()
    cursor.execute(
        f"""
        Select title From Movies Where movieID={str(movieID)};
        """
    )
    title = cursor.fetchone()[0]
    # logging.debug(f"""For movie {title}:""")

    innerID = algo.trainset.to_inner_iid(str(movieID))
    neighbors = algo.get_neighbors(innerID, k=10)
    rec_list = []
    for iid in neighbors:
        neighbor_movieID = algo.trainset.to_raw_iid(iid)
        cursor.execute(
            f"""
            Select title From Movies Where movieID={str(neighbor_movieID)};
            """
        )
        rec_list.append(cursor.fetchone()[0])

    db.close()
    return rec_list


if __name__ == "__main__":
    algo = get_model()
    rec_list = recommend_for_movie(algo, movieID=100)
    print(rec_list)
