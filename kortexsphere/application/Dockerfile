# KortexSphere API Dockerfile
FROM python:3.12-slim

# System deps (optional but safe)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements (agar file ka naam different ho to yahan change karna)
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . /app

# Flask env vars (compose mein override kar sakte hain)
ENV FLASK_APP=app.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=5000

# Default DB config: Docker postgres service "db" assume kar raha hun
ENV DB_HOST=db \
    DB_NAME=ks_dev \
    DB_USER=ks_admin \
    DB_PASSWORD=admin

EXPOSE 5000

CMD ["flask", "run"]
