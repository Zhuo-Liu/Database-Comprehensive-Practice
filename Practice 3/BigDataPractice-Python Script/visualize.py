# -*- coding: utf-8 -*-

from __future__ import division

import cpca
import matplotlib.pyplot as plt

from config import db, host, port, user, passwd, charset
from db import MySQLCommand


# import matplotlib as mpl

def get_data():
    """
    cinemaName:影院名称
    amount:当周票房
    avgPS:场均人次
    avgScreen：单荧幕票房
    screen_yield:单日单厅票房
    scenes_time:单日单厅场次
    """
    database.connectMysql()
    sql = 'SELECT cinema_id, cinema_name, amount, avg_per_show, avg_screen, screen_yield, scenes_time FROM cbooo.cinema;'
    result = database.queryMysql(sql)
    database.closeMysql()
    return result


def draw_distribution(data):
    fig, axs = plt.subplots(5, 5, figsize=(25, 25))
    label = [u'当周票房', u'场均人次', u'单荧幕票房', u'单日单厅票房', u'单日单厅场次']
    for row in range(5):
        for col in range(5):

            if col == 4:
                axs[col, row].set_xlabel(label[row])

            if row == 0:
                axs[col, row].set_ylabel(label[col])

            axs[col, row].plot(matrix[row], matrix[col], 'bo')

            axs[col, row].set_xlim(0, max(matrix[row]))
            axs[col, row].set_ylim(0, max(matrix[col]))

    # plt.show()
    plt.savefig('img/distribution.png')


def draw_avg_price(data):
    # 平均票价 = 单日单厅票房 / 单日单厅场次 / 场均人数
    avg_price = []
    for idx in range(len(data[0])):
        avg_price.append(data[3][idx] / data[4][idx] / data[1][idx])

    plt.plot(avg_price, data[1], 'bo')
    plt.xlabel(u'平均票价')
    plt.ylabel(u'场均人数')
    plt.xlim(0, max(avg_price))
    plt.ylim(0, max(data[1]))
    # plt.show()
    plt.savefig('img/avg_price.png')


def draw_regional_characteristics(data):
    cinema_name = []
    amount = []
    for row in data:
        amount.append(row[2])
        cinema_name.append(row[1].encode('utf-8'))
    result = cpca.transform(cinema_name, cut=False)
    result['票房'] = amount

    pdict = {}

    for idx in range(result.shape[0]):
        provinces = result['省'][idx]
        pamount = result['票房'][idx]
        if provinces != '':
            # print provinces, pamount
            try:
                pdict[provinces] += pamount
            except:
                pdict[provinces] = pamount
    plist = []
    for k in pdict.keys():
        plist.append((k, pdict[k]))
    plist = sorted(plist, cmp=lambda x, y: int(y[1] - x[1]))

    x_ = []
    y_ = []
    for idx in range(len(plist)):
        x_.append(plist[idx][0].decode('utf-8'))
        y_.append(plist[idx][1])

    plt.bar(x_, y_)
    plt.xticks(rotation=90)
    # plt.show()
    plt.savefig('img/regional_characteristics.png')


if __name__ == '__main__':
    # 显示中文
    # mpl.rcParams['font.sans-serif'] = ['SimHei'];
    # mpl.rcParams['axes.unicode_minus'] = False
    database = MySQLCommand(host=host, port=port, user=user, passwd=passwd, db=db, charset=charset)
    data = get_data()
    matrix = [[], [], [], [], [], []]
    for row in data:
        for idx in range(5):
            matrix[idx].append(row[idx + 2])
    draw_distribution(matrix)
    draw_avg_price(matrix)
    draw_regional_characteristics(data)
