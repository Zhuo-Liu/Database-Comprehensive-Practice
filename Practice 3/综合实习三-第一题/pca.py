import numpy as np
import keras
import pyodbc
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
plt.rcParams["figure.figsize"] = [12.8, 9.6]

import database
import config

# def get_data(db):
#     sql1 = 'select team from player_career'
#     result = db.qeurySql(sql)
#     return result

if __name__ == "__main__":    
    db = database.SQLCommand(config.config_)    
    db.connectSqlServer()
    sql1 = 'select ilkid,minutes,pts,reb,asts,stl,blk from player_career where minutes <> 0'
    player_career_sql = db.qeurySql(sql1)
    players = []
    for i in player_career_sql:
        players.append(i[0:7])
    players.pop()
    players.pop()
    players.pop()
    players = np.array(players)

    for player in players:
        for i in range(2,7):
            player[i] = int(player[i])

    player_id = []
    player_data = []
    for player in players:
        player_id.append(player[0])
        player_data.append(player[2:])
    
    pca = PCA(n_components=2)
    data_pca = pca.fit_transform(player_data)
    print(type(data_pca))
    print(data_pca)

    fig, ax = plt.subplots()
    for i in range(int(data_pca.size / 2)):
        #if i%10 == 1:
        player = data_pca[i]
        ax.scatter(player[0], player[1])
        ax.annotate(player_id[i], (player[0], player[1]))
    plt.show()
