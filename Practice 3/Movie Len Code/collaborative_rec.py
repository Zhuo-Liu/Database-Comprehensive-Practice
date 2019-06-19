import pymysql
import os

from surprise import KNNBaseline
from surprise import Dataset
from surprise import Reader


def col_model():
    filepath = os.path.join("Practice 3", "ml-latest-small", "ratings.csv")
    with open(filepath,"r") as f:
        print(1)
        pass

    reader = Reader(line_format="user item rating timestamp",
                    sep=",", rating_scale=(1, 5), skip_lines=1)
    data = Dataset.load_from_file(filepath, reader=Reader)

    algo = []
    return algo


if __name__ == "__main__":
    col_model()
