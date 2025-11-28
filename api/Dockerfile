# ---------- Stage 1: Builder ----------

FROM python:3-alpine AS builder

WORKDIR /app

COPY requirements.txt .

# Install build tools required for compiling some Python packages
RUN apk add --no-cache build-base

COPY requirements.txt .
RUN pip wheel --no-cache --wheel-dir /app/wheels -r requirements.txt

# ---------- Stage 2: Final Runtime ----------

FROM python:3-alpine

WORKDIR /app

# Install only the wheels (no build tools needed)
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*


COPY app.py .



CMD [ "python3", "app.py" ]