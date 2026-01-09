# =========================
# FRONTEND BUILD
# =========================
FROM node:20-alpine AS frontend-builder

WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci

COPY frontend/ .
RUN npm run build


# =========================
# BACKEND IMAGE
# =========================
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y gcc curl && rm -rf /var/lib/apt/lists/*

# Install backend dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY backend/app ./app

# Copy frontend build
COPY --from=frontend-builder /frontend/dist ./frontend/dist

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

