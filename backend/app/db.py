import pyodbc
import os
import threading
from contextlib import contextmanager

_local = threading.local()


def get_connection() -> pyodbc.Connection:
    conn = getattr(_local, 'connection', None)
    if conn is None:
        driver   = os.environ.get('DB_DRIVER', 'SQL Server')
        server   = os.environ.get('DB_SERVER', r'.\SQLEXPRESS')
        database = os.environ.get('DB_NAME',   'philipeia')

        db_user = os.environ.get('DB_USER', '')
        db_pwd  = os.environ.get('DB_PASSWORD', '')

        if db_user and db_pwd:
            conn_str = (
                f"DRIVER={{{driver}}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                f"UID={db_user};"
                f"PWD={db_pwd};"
                "TrustServerCertificate=yes;"
            )
        else:
            # Autenticação Windows (Trusted_Connection) — padrão do professor
            conn_str = (
                f"DRIVER={{{driver}}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                "Trusted_Connection=yes;"
                "TrustServerCertificate=yes;"
            )

        conn = pyodbc.connect(conn_str, autocommit=False)
        _local.connection = conn
    return conn


def fetchone(sql: str, *params) -> dict | None:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params)
        row = cursor.fetchone()
        if row is None:
            return None
        cols = [col[0] for col in cursor.description]
        return dict(zip(cols, row))
    finally:
        cursor.close()


def fetchall(sql: str, *params) -> list[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params)
        cols = [col[0] for col in cursor.description]
        return [dict(zip(cols, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()


def execute(sql: str, *params) -> None:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params)
        conn.commit()
    finally:
        cursor.close()


def execute_insert(sql: str, *params) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params)
        row = cursor.fetchone()
        conn.commit()
        return row[0]
    finally:
        cursor.close()


@contextmanager
def transaction():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
