import psycopg2
from psycopg2.extras import RealDictCursor
from config import Config

def get_db():
    conn = psycopg2.connect(
        host=Config.DB_HOST,
        dbname=Config.DB_NAME,
        user=Config.DB_USER,
        password=Config.DB_PASS,
        cursor_factory=RealDictCursor
    )
    return conn

def set_user_context(conn, user_id):
    cur = conn.cursor()
    cur.execute("SELECT set_user_context(%s)", (user_id,))
    conn.commit()
