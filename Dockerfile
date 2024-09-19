# syntax=docker/dockerfile:1.4
FROM 201959883603.dkr.ecr.us-east-2.amazonaws.com/mdaca/base-images/ironbank-ubuntu-r:22.04_4.4.1

WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/achilles/drivers"

RUN <<EOF
groupadd -g 10001 achilles
useradd -m -u 10001 -g achilles achilles
mkdir ./drivers
mkdir ./workspace
chown -R achilles .
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

# Install the DatabaseConnector package and dependencies
RUN R --vanilla -e "install.packages('DatabaseConnector', repos='https://cloud.r-project.org')" && \
    R --vanilla <<EOF
library(DatabaseConnector);
downloadJdbcDrivers('postgresql');
downloadJdbcDrivers('redshift');
downloadJdbcDrivers('sql server');
downloadJdbcDrivers('oracle');
downloadJdbcDrivers('spark');
EOF && \
# this layer is the most likely to change over time so it's useful to keep it separated
# hadolint ignore=DL3059
    R -e "remotes::install_github('OHDSI/Achilles@v1.7.2')"



COPY src/entrypoint.r ./

USER 10001:10001

WORKDIR /opt/achilles/workspace
CMD ["Rscript", "/opt/achilles/entrypoint.r"]
