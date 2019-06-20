import numpy as np
import keras
import pyodbc
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
plt.rcParams["figure.figsize"] = [12.8, 9.6]

import database
import config

if __name__ == "__main__":
    db = database.SQLCommand(config.config_)    
    db.connectSqlServer()
    sql1 = 'select ilkid,gp,pts,reb,dreb,oreb,asts,turnover,stl,blk,fga,fgm,fta,ftm,tpa,tpm from player_career where gp <> 0 and gp >20 and turnover<>0 and turnover > 20'
    player_career_sql = db.qeurySql(sql1)
    players = []
    for i in player_career_sql:
        players.append(i[0:16])
    players.pop()
    players.pop()
    players.pop()
    players = np.array(players)

    # for player in players:
    #     for i in range(1,16):
    #         player[i] = int(player[i])

    player_id = []
    player_ppg = []
    player_atr = []
    player_feature = []
    for player in players:
        player_id.append(player[0])
        player_ppg.append(int(player[2])/int(player[1]))
        player_atr.append(int(player[6])/int(player[7]))
        player_feature = list(zip(player_atr,player_ppg))
    
    # plt.scatter(player_ppg, player_atr, c='y',s=5)
    # plt.title("Point Guards")
    # plt.xlabel('Points Per Game', fontsize=13)
    # plt.ylabel('Assist Turnover Ratio', fontsize=13)
    # plt.show()
    player_feature= np.array(player_feature)
    y_pred = KMeans(n_clusters=5).fit_predict(player_feature)

    fig, ax = plt.subplots()
    for i in range(int(player_feature.size / 2)):
        player_f = player_feature[i]
        ax.scatter(player_f[0],player_f[1],s=10)    
        ax.annotate(player_id[i], (player_f[0], player_f[1]))
    plt.title("Player ATR/PPG Abillity Cluster")
    plt.xlabel('Points Per Game', fontsize=13)
    plt.ylabel('Assist Turnover Ratio', fontsize=13)
    plt.show()
