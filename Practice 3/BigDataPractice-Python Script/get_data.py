# -*- coding: utf-8 -*-

import json

import requests
from fake_useragent import UserAgent

from config import db, host, port, user, passwd, charset
from db import MySQLCommand


def get_data(p_index, dt):
    """
    cinemaName:影院名称
    amount:当周票房
    avgPS:场均人次
    avgScreen：单荧幕票房
    screen_yield:单日单厅票房
    scenes_time:单日单厅场次
    """

    cbooo_api = 'http://www.cbooo.cn/BoxOffice/getCBW?pIndex={}&dt={}'
    headers = {"User-Agent": UserAgent(verify_ssl=False).random}
    response_comment = requests.get(cbooo_api.format(p_index, dt), headers=headers)
    json_comment = response_comment.text
    json_comment = json.loads(json_comment)
    return json_comment


def insert(line):
    database.connectMysql()
    sql = 'INSERT INTO cbooo.cinema ' \
          '(cinema_id, cinema_name, amount, avg_per_show, avg_screen, screen_yield, scenes_time) ' \
          'VALUES ("{}", "{}", "{}", "{}", "{}", "{}", "{}");'.format(int(line["cinemaId"]),
                                                                      line["cinemaName"].encode('utf-8'),
                                                                      float(line["amount"]),
                                                                      float(line["avgPS"]),
                                                                      float(line["avgScreen"]),
                                                                      float(line["screen_yield"]),
                                                                      float(line["scenes_time"]))
    database.insertMysql(sql)
    database.closeMysql()


if __name__ == '__main__':
    database = MySQLCommand(host=host, port=port, user=user, passwd=passwd, db=db, charset=charset)
    for page in range(10):
        # print(page + 1)
        data_json = get_data(page + 1, 1041)
        rows = data_json['data1']
        for row in rows:
            # print(row)
            insert(row)
