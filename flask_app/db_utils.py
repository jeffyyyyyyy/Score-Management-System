'''数据库连接工具，所有数据库操作从这里导入连接'''
import pyodbc
import os

# 数据库登录信息（可用环境变量/配置文件管理）
server_name = r'LAPTOP-HHS2UOJ9\SQLEXPRESS'
database_name = 'ScoreManagement'
username = '****'
password = '****'

def get_db_connection():
    try:
        conn = pyodbc.connect(
            f'DRIVER={{SQL Server}};SERVER={server_name};DATABASE={database_name};UID={username};PWD={password}'
        )
        return conn
    except Exception as e:
        print(f"Database connection failed: {e}")
        return None