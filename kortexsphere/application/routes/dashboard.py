from flask import Blueprint, session, render_template

dashboard_bp = Blueprint("dashboard", __name__)

@dashboard_bp.get("/dashboard")
def dashboard():
    if "user_id" not in session:
        return redirect("/login")
    return render_template("dashboard.html", role=session["role"])
