from flask import Blueprint, request, jsonify, session
from database import get_db

projects_bp = Blueprint("projects", __name__)

@projects_bp.get("/projects")
def list_projects():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM projects")
    return jsonify(cur.fetchall())
