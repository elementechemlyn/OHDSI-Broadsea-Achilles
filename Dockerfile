# syntax=docker/dockerfile:1.4
FROM rocker/r-ver:4.1.3

WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/achilles/drivers"

RUN <<EOF
groupadd -g 10001 achilles
useradd -u 10001 -g achilles achilles
mkdir ./output
mkdir ./drivers
chown -R achilles .
EOF

# hadolint ignore=DL3008
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends openjdk-11-jre-headless
apt-get clean
rm -rf /var/lib/apt/lists/*

# The default GitHub Actions runner has 2 vCPUs (https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
install2.r --error --ncpus 2 \
  httr \
  remotes \
  rjson \
  littler \
  docopt \
  snow \
  xml2 \
  jsonlite \
  rjava \
  rlang \
  stringr \
  readr \
  dbi \
  urltools \
  bit64 \
  lubridate \
  data.table \
  dplyr \
  fastmap \
  rappdirs \
  fs \
  base64enc \
  digest \
  jquerylib \
  sass \
  htmltools \
  later \
  promises \
  cachem \
  bslib \
  commonmark \
  sourcetools \
  fontawesome \
  xtable \
  httpuv \
  shiny \
  ttr \
  zoo \
  xts \
  quantmod \
  quadprog \
  tseries \
  ParallelLogger \
  SqlRender \
  DatabaseConnector

R CMD javareconf
EOF

RUN R <<EOF
library(DatabaseConnector);

downloadJdbcDrivers('postgresql');
downloadJdbcDrivers('redshift');
downloadJdbcDrivers('sql server');
downloadJdbcDrivers('oracle');
downloadJdbcDrivers('spark');
EOF

RUN R -e "remotes::install_github('OHDSI/Achilles@c6b7adb6330e75c2311880db2eb3dc4c12341c4f')"

COPY src/entrypoint.r ./

USER 10001:10001
CMD ["Rscript", "entrypoint.r"]
