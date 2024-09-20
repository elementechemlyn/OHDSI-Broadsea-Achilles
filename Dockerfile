FROM 201959883603.dkr.ecr.us-east-2.amazonaws.com/mdaca/base-images/ironbank-ubuntu-r:22.04_4.4.1

WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/achilles/drivers"
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /root/.R && \
    echo "PKG_CXXFLAGS = -O3 -march=native" >> ~/.R/Makevars && \
    echo "PKG_CPPFLAGS = -I/usr/local/include" >> ~/.R/Makevars && \
    echo "PKG_FCFLAGS = -O3apt-get update" >> ~/.R/Makevars && \
    apt-get update -y && \
    apt-get install -y \
    r-base \
    r-base-dev && \
    groupadd -g 10001 achilles && \
    useradd -m -u 10001 -g achilles achilles && \
    mkdir ./drivers && \
    mkdir ./workspace && \
    chown -R achilles . && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
  
    # Install r and install2.r
RUN R -e "install.packages(c('littler', 'docopt'), dependencies = TRUE, repos = 'http://cran.r-project.org')" && \
    ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r 
COPY --chmod=755 src/install2.r /usr/local/bin/install2.r 
    # The default GitHub Actions runner has 2 vCPUs (https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
RUN install2.r --error --ncpus 2  --skipinstalled --repos "https://packagemanager.posit.co/cran/latest \
    rJava \
    remotes \ 
    ParallelLogger \
    SqlRender \
    DatabaseConnector && \
 
    # Add the environment variable
    echo "DATABASECONNECTOR_JAR_FOLDER=/usr/local/lib/R/site-library/DatabaseConnector/java/" >> /usr/local/lib/R/etc/Renviron && \
    R CMD javareconf && \
    R --vanilla -e "library(DatabaseConnector); downloadJdbcDrivers('postgresql'); downloadJdbcDrivers('redshift'); downloadJdbcDrivers('sql server'); downloadJdbcDrivers('oracle'); downloadJdbcDrivers('spark')" && \
    R -e "remotes::install_github('mdaca/OHDSI-Achilles@v1.7.2')" && rm -rf /var/lib/apt/lists/* /tmp/*

COPY --chown=achilles --chmod=755 src/entrypoint.r  ./

USER 10001:10001

WORKDIR /opt/achilles/workspace
CMD ["Rscript", "/opt/achilles/entrypoint.r"]
