# Dockerfile - build a local custom-airflow:3.3.0 image
FROM apache/airflow:3.3.0-python3.12

ARG AIRFLOW_VERSION=3.3.0

USER root

# Install system deps needed for pyodbc / mssql connectivity and build steps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    unixodbc-dev \
    freetds-dev \
    freetds-bin \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

COPY --chown=airflow:root requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-3.12.txt" \
  && rm /tmp/requirements.txt
