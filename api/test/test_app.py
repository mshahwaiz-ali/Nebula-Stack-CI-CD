import sys
import os

# add api folder to python path |||| will also force python to load api/app.py as module
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "/..")


from app import app

def test_health_route():
    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "ok"
