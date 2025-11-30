from flask import (
    Flask,
    render_template,
    request,
    redirect,
    session,
    jsonify,
    url_for,
)
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Load env
load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "ks_dev")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret")

app = Flask(__name__)
app.secret_key = SECRET_KEY


# ---------------------------
# DB helpers
# ---------------------------

def get_db():
    conn = psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        port=DB_PORT,
        cursor_factory=RealDictCursor,
    )
    return conn


def apply_user_context(conn):
    """session['user_id'] se Postgres GUC set karega (RLS ke liye)."""
    user_id = session.get("user_id")
    if not user_id:
        return
    cur = conn.cursor()
    cur.execute("SELECT set_user_context(%s)", (user_id,))
    conn.commit()


# ---------------------------
# BASIC ROUTES
# ---------------------------

@app.route("/")
def index():
    if "user_id" in session:
        return redirect(url_for("dashboard"))
    return redirect(url_for("login_page"))


# ---------------------------
# AUTH: LOGIN / LOGOUT
# ---------------------------

@app.get("/login")
def login_page():
    error = request.args.get("error")
    return render_template("login.html", error=error)


@app.post("/login")
def login_submit():
    company_code = request.form.get("company_code", "").strip().lower()
    email = request.form.get("email", "").strip().lower()
    password = request.form.get("password", "").strip()

    if not company_code or not email or not password:
        return redirect(url_for("login_page", error="Please fill all fields."))

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """
        SELECT 
            u.id AS user_id,
            u.role,
            u.full_name,
            t.id AS tenant_id,
            t.name AS tenant_name,
            t.code AS tenant_code
        FROM app_users u
        JOIN tenants t ON t.id = u.tenant_id
        WHERE t.code = %s
          AND lower(u.email) = %s
          AND u.password = %s
          AND u.is_active = true
          AND t.is_active = true
        """,
        (company_code, email, password),
    )
    row = cur.fetchone()
    conn.close()

    if not row:
        return redirect(url_for("login_page", error="Invalid company / email / password."))

    session["user_id"] = row["user_id"]
    session["role"] = row["role"]
    session["tenant_id"] = row["tenant_id"]
    session["tenant_name"] = row["tenant_name"]
    session["tenant_code"] = row["tenant_code"]
    session["full_name"] = row["full_name"]

    return redirect(url_for("dashboard"))


@app.get("/logout")
def logout():
    session.clear()
    return redirect(url_for("login_page"))


# ---------------------------
# DASHBOARD (HTML)
# ---------------------------

@app.get("/dashboard")
def dashboard():
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    tab = request.args.get("tab", "projects")

    conn = get_db()
    apply_user_context(conn)
    cur = conn.cursor()

    projects = []
    users = []

    if tab == "users":
        cur.execute(
            """
            SELECT id, email, full_name, role, is_active, created_at
            FROM app_users
            ORDER BY created_at DESC
            """
        )
        users = cur.fetchall()
    else:
        cur.execute(
            """
            SELECT id, name, status, budget, created_at
            FROM projects
            ORDER BY created_at DESC
            """
        )
        projects = cur.fetchall()

    conn.close()

    return render_template(
        "dashboard.html",
        tab=tab,
        projects=projects,
        users=users,
        role=session.get("role"),
        tenant_name=session.get("tenant_name"),
        full_name=session.get("full_name"),
    )


# ---------------------------
# PROJECTS – UI (forms)
# ---------------------------

@app.post("/projects/create")
def ui_create_project():
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    if session.get("role") not in ("admin", "writer"):
        return "Forbidden", 403

    name = request.form.get("name", "").strip()
    status = request.form.get("status", "draft").strip()
    budget_raw = request.form.get("budget", "0").strip()

    if not name:
        return redirect(url_for("dashboard", tab="projects"))

    try:
        budget = float(budget_raw or 0)
    except ValueError:
        budget = 0

    conn = get_db()
    apply_user_context(conn)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO projects (tenant_id, name, status, budget)
        VALUES (current_setting('app.tenant_id')::uuid, %s, %s, %s)
        """,
        (name, status, budget),
    )
    conn.commit()
    conn.close()

    return redirect(url_for("dashboard", tab="projects"))


@app.post("/projects/delete/<project_id>")
def ui_delete_project(project_id):
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    if session.get("role") not in ("admin", "writer"):
        return "Forbidden", 403

    conn = get_db()
    apply_user_context(conn)
    cur = conn.cursor()
    cur.execute("DELETE FROM projects WHERE id::text = %s", (project_id,))
    conn.commit()
    conn.close()

    return redirect(url_for("dashboard", tab="projects"))


# ---------------------------
# USERS – UI (basic manage)
# ---------------------------

@app.post("/users/create")
def ui_create_user():
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    if session.get("role") != "admin":
        return "Forbidden", 403

    email = request.form.get("email", "").strip().lower()
    full_name = request.form.get("full_name", "").strip()
    role = request.form.get("role", "writer").strip()
    password = request.form.get("password", "").strip() or "admin"

    if not email or role not in ("admin", "writer", "readonly"):
        return redirect(url_for("dashboard", tab="users"))

    conn = get_db()
    apply_user_context(conn)
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO app_users (tenant_id, email, full_name, role, password)
        VALUES (current_setting('app.tenant_id')::uuid, %s, %s, %s, %s)
        """,
        (email, full_name, role, password),
    )
    conn.commit()
    conn.close()

    return redirect(url_for("dashboard", tab="users"))


@app.post("/users/delete/<user_id>")
def ui_delete_user(user_id):
    if "user_id" not in session:
        return redirect(url_for("login_page"))

    if session.get("role") != "admin":
        return "Forbidden", 403

    # Optional: apne aap ko delete na karne dena
    if user_id == str(session.get("user_id")):
        return redirect(url_for("dashboard", tab="users"))

    conn = get_db()
    apply_user_context(conn)
    cur = conn.cursor()
    cur.execute("DELETE FROM app_users WHERE id::text = %s", (user_id,))
    conn.commit()
    conn.close()

    return redirect(url_for("dashboard", tab="users"))


# ---------------------------
# SIMPLE JSON API (optional)
# ---------------------------

@app.get("/api/projects")
def api_list_projects():
    if "user_id" not in session:
        return jsonify({"error": "unauthenticated"}), 401

    conn = get_db()
    apply_user_context(conn)
    cur = conn.cursor()
    cur.execute("SELECT * FROM projects ORDER BY created_at DESC")
    rows = cur.fetchall()
    conn.close()
    return jsonify(rows)


if __name__ == "__main__":
    app.run(debug=True)
