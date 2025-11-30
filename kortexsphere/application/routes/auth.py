from flask import Blueprint, render_template, request, redirect, session
from database import get_db, set_user_context

auth_bp = Blueprint("auth", __name__)

@auth_bp.get("/login")
def login_page():
    return render_template("login.html")

@auth_bp.post("/login")
def login_submit():
    company = request.form.get("company_code")
    email = request.form.get("email")
    password = request.form.get("password")

    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT u.id, u.role, t.id AS tenant_id
        FROM app_users u
        JOIN tenants t ON t.id = u.tenant_id
        WHERE t.code = %s AND u.email = %s AND u.password = %s
    """, (company, email, password))

    row = cur.fetchone()
    if not row:
        return "Invalid credentials"

    # set tenant context for RLS & RBAC
    set_user_context(conn, row["id"])

    session["user_id"] = row["id"]
    session["role"] = row["role"]
    session["tenant_id"] = row["tenant_id"]

    return redirect("/dashboard")
