from flask import Flask, jsonify, request
import os
import logging
import psycopg2
from psycopg2.extras import RealDictCursor


logging.basicConfig(
    level=logging.INFO,
    format = '{"time" : "%(asctime)s", "level" : "%(levelname)s", "message" : "%(message)s"}'
)

def get_db():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST" , "postgres"),
        database=os.environ.get("DB_NAME","nebulastack"),
        user=os.environ.get("DB_USER","nebula"),
        password=os.environ.get("DB_PASS","secretpass"),
        cursor_factory=RealDictCursor
    )

app = Flask(__name__)

@app.route("/")
def home():
    return "Nebulastack API is running"

@app.route("/health")
def health():
    env = os.environ.get("APP_ENV", "local")
    return jsonify ({"status" : "ok", "env" : env })

@app.route("/db-test")
def db_test():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT 1 as result")
    data = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(data)


#----------- Projects Endpoints--------------

@app.route("/messages" , methods=["POST"])
def create_messages():
    body = request.get_json(silent=True) or {}
    content = body.get("content")

    if not content or not str(content).strip():
        return jsonify({"error": "content is required"}) , 400


    conn = get_db()
    cur =  conn.cursor()
    cur.execute(
        "INSERT INTO messages (content) VALUES (%s) RETURNING id, content, created_at", (content,)
    )
    msg = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    app.logger.info(f"New message created: {msg['id']}")
    return jsonify(msg), 201


@app.route("/messages" , methods=["GET"])
def list_messages():
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT id, content, created_at FROM messages ORDER BY created_at DESC LIMIT 50"
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows)

@app.route("/messages/<int:message_id>", methods=["DELETE"])
def delete_message(message_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "DELETE FROM messages WHERE id = %s RETURNING id;", (message_id,)
    )
    deleted = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()

    if not deleted:
        return jsonify({"error": "message not found"}), 404
    
    app.logger.info(f"Messages deleted: {deleted['id']}")
    return jsonify({"status": "deleted", "id": deleted["id"]})

#-----------WILL ADD SQL TABLE A AUTOMATICALLY IN START IF NOT PRESENT THERE-----------------------

def init_db():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id SERIAL PRIMARY KEY,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
 """)
    conn.commit()
    cur.close()
    conn.close()


#-----------Main body-----------------------

if __name__ == "__main__":
    init_db()
    app.run(host= "0.0.0.0", port = 5000)

