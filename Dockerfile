FROM ubuntu:xenial

ENV PYTHON_PIP_VERSION 18.1
ENV PYTHON_VERSION 3.5.2

RUN set -ex; \
    buildDeps=" \
        ca-certificates \
        curl \
        wget \
        git" \
    ; \
    apt-get update && apt-get install -y $buildDeps --no-install-recommends \
    ; \
    rm -rf /var/lib/apt/lists/* \
    ; \
    apt-get update && apt install -y --no-install-recommends python3 python3-dev supervisor \
    ; \
    rm -rf /var/lib/apt/lists/* \
    ; \
    wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py' \
    ; \
    python3 get-pip.py \
        --disable-pip-version-check \
        --no-cache-dir \
        "pip==$PYTHON_PIP_VERSION" \
    ; \
    pip3 --version \
    ; \
    find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' + \
    ; \
    rm -f get-pip.py

RUN git clone --depth=1 --branch=master https://github.com/ajanis/Plex-to-InfluxDB-Extended.git /opt/plex-influxdb-collector \
    ; \
    rm -rf /opt/plex-influxdb-collector/.git

RUN cd /opt/plex-influxdb-collector \
    ; \
    pip3 install -r requirements.txt \
    ; \
    apt-get purge -y --auto-remove $buildDeps

COPY custom-config.ini /opt/plex-influxdb-collector/config.ini
COPY contrib/etc/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

STOPSIGNAL SIGTERM

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]