FROM 201959883603.dkr.ecr.us-east-2.amazonaws.com/mdaca/base-images/ironbank-ubuntu-r:22.04_4.4.1

WORKDIR mkd/opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/achilles/drivers"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libssh2-1-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev && \
    groupadd -g 10001 achilles && \
    useradd -m -u 10001 -g achilles achilles && \
    mkdir ./drivers && \
    mkdir ./workspace && \
    chown -R achilles . && \
    apt-get update && \
    apt-get install -y --no-install-recommends openjdk-11-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
      
    #RUN R -e "install.packages(c('httr', 'remotes', 'xtable', 'httpuv', 'shiny', 'ttr', 'zoo', 'xts', 'quantmod', 'quadprog', 'tseries', 'ParallelLogger', 'SqlRender', 'DatabaseConnector'), quiet = TRUE, dependencies = TRUE, repos = 'http://cran.r-project.org')" && \
RUN R -e "options(timeout = 5); install.packages(c('remotes', 'DatabaseConnector'), dependencies = TRUE, repos = 'http://cran.r-project.org')" && \
    R CMD javareconf && \
    R --vanilla -e "library(DatabaseConnector); downloadJdbcDrivers('postgresql'); downloadJdbcDrivers('redshift'); downloadJdbcDrivers('sql server'); downloadJdbcDrivers('oracle'); downloadJdbcDrivers('spark')" && \
    R -e "remotes::install_github('mdaca/OHDSI-Achilles@v1.7.2')"

COPY src/entrypoint.r ./

USER 10001:10001

WORKDIR /opt/achilles/workspace
CMD ["Rscript", "/opt/achilles/entrypoint.r"]
