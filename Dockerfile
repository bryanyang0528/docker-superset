FROM python:3.7

# Superset version
ARG SUPERSET_VERSION=0.30

# Configure environment
ENV GUNICORN_BIND=0.0.0.0:8088 \
    GUNICORN_LIMIT_REQUEST_FIELD_SIZE=0 \
    GUNICORN_LIMIT_REQUEST_LINE=0 \
    GUNICORN_TIMEOUT=60 \
    GUNICORN_WORKERS=2 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_REPO=apache/incubator-superset \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset
ENV GUNICORN_CMD_ARGS="--workers ${GUNICORN_WORKERS} --timeout ${GUNICORN_TIMEOUT} --bind ${GUNICORN_BIND} --limit-request-line ${GUNICORN_LIMIT_REQUEST_LINE} --limit-request-field_size ${GUNICORN_LIMIT_REQUEST_FIELD_SIZE}"

# Create superset user & install dependencies
RUN useradd -U -m superset && \
    mkdir /etc/superset  && \
    mkdir ${SUPERSET_HOME} && \
    chown -R superset:superset /etc/superset && \
    chown -R superset:superset ${SUPERSET_HOME} && \
    apt-get -o Acquire::Check-Valid-Until=false update &&\
    apt-get -y upgrade

RUN apt-get install -y --allow-unauthenticated \
        build-essential \
        python3.7-dev \
        python-pip \
        curl \
        default-libmysqlclient-dev \
        openjdk-11-jdk \
        freetds-bin \
        freetds-dev \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/${SUPERSET_REPO}/${SUPERSET_VERSION}/requirements.txt -o requirements.txt && \
    pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt

RUN  pip install --no-cache-dir \
        flask-cors \
        flask-mail \
        flask-oauth \
        flask_oauthlib \
        gevent \
        impyla  \
        infi.clickhouse-orm \
        mysqlclient \
        psycopg2 \
        pyathena \
        pybigquery \
        pyhive \
        pyldap \
        pymssql \
        redis \
        sqlalchemy-clickhouse \
        sqlalchemy-redshift \
        PyAthenaJDBC \
        oauthlib \
        requests-oauthlib \
        werkzeug \
        requests \
        gsheetsdb[all] && \
    pip install superset==${SUPERSET_VERSION}

# Configure Filesystem
COPY superset /usr/local/bin
VOLUME /home/superset \
       /etc/superset \
       /var/lib/superset
WORKDIR /home/superset

# Deploy application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
CMD ["gunicorn", "superset:app"]
USER superset
