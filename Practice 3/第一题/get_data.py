import numpy as np
import keras
import pyodbc

import database
import config

def get_data(db):
    sql = 'select * from player_career'
    result = db.qeurySql(sql)
    return result

if __name__ == "__main__":    
    db = database.SQLCommand(config.config_)    
    db.connectSqlServer()
    results = get_data(db)
    #print(results)
    re = np.array([i[1] for i in results])
    # for row in results:
    #     print(row)
    # array = np.fromiter(results_as_list,dtype=np.int32)
    print(re)
    # for row in results:
    #     print(row)
    #print(array)
    db.closeSql()
    # connect = pyodbc.connect('Driver={SQL Server Native Client 11.0}; Server=DESKTOP-O5FNLUM\SQLEXPRESS; Database=practice3_question1; Uid=sa;Pwd=123456')
    # if connect:
    #     print('connect successed!')
    # else:
    #     print("failed!")