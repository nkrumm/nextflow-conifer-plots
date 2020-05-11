FROM python:2.7-slim


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    python2.7-dev \
    gcc \
    locales

RUN pip install \
    numpy>1.10.1 \
    pandas>=0.17.1 \
    suds==0.4 \
    XlsxWriter==0.9.6 \
    xlwt==0.7.5 \
    xlrd==0.9.3 \
    natsort>=5.0.2 \
    plotly>=2.7.0 \
    intervaltree==2.1.0 \
    matplotlib==2.2.4 \
    pyarrow>=0.15.1 \
    subprocess32==3.2.7

RUN git clone https://github.com/sheenamt/munge.git

