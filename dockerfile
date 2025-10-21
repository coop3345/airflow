# Dockerfile - build a local custom-airflow:2.9.3 image
FROM apache/airflow:2.9.3-python3.9

USER root

# Install system deps needed for pyodbc / mssql connectivity and build steps
# (Add msodbcsql if you prefer MS official driver; instructions below)
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

# Optional: install Microsoft ODBC Driver 18 for SQL Server (recommended for best compatibility)
# Uncomment the next block if you want msodbcsql18 instead of FreeTDS. Note: this adds extra repo steps.
# RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
#  && DISTRO="$(. /etc/os-release && echo $ID$VERSION_ID)" \
#  && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
#  && apt-get update \
#  && ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev \
#  && rm -rf /var/lib/apt/lists/*

# Switch back to airflow user (image's default user where pip installs go)
USER airflow

# Copy and install python requirements (only requirements - don't copy whole project)
COPY --chown=airflow:root requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
  && rm /tmp/requirements.txt