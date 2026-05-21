import pyodbc
import os
import threading
from contextlib import contextmanager

_local = threading.local()


def get_connection() -> pyodbc.Connection:
    conn = getattr(_local, 'connection', None)
    if conn is None:
        conn_str = (
            f"DRIVER={{{os.environ['DB_DRIVER']}}};"
            f"SERVER={os.environ['DB_SERVER']};"
            f"DATABASE={os.environ['DB_NAME']};"
            f"UID={os.environ['DB_USER']};"
            f"PWD={os.environ['DB_PASSWORD']};"
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
    """Executa INSERT e retorna o ID gerado (IDENTITY)."""
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
