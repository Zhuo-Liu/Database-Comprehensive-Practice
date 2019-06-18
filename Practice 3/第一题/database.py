import pyodbc

class SQLCommand(object):
    def __init__(self, config):
        self.config = config

    def connectSqlServer(self):
        try:
            self.conn = pyodbc.connect(self.config)
            if self.conn:
                print("connect successed!")
            self.cursor = self.conn.cursor()
        except Exception as e:
            self.conn = None
            self.cursor = None
            print('connect sql server error.', e)
    
    def qeurySql(self, sql):
        try:
            self.cursor.execute(sql)
            result = self.cursor.fetchall()
            return result
        except Exception as e:
            print(e)    
    
    def closeSql(self):
        self.conn.close()