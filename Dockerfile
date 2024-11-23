FROM rocker/r-ubuntu AS build

WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER=/usr/local/lib/R/site-library/DatabaseConnector/java/
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV LD_LIBRARY_PATH=$JAVA_HOME/lib/server:$LD_LIBRARY_PATH

# Create necessary directories and set up R configurations
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    r-base \
    r-base-dev \
    openjdk-11-jdk-headless libcurl4-openssl-dev libxml2-dev libssl-dev && \
    groupadd -g 10001 achilles && \
    useradd -m -u 10001 -g achilles achilles && \
    ln -s /usr/local/lib/R/site-library/DatabaseConnector/java drivers && \
    mkdir ./workspace && \
    chown -R achilles:achilles . && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages('rJava', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R CMD javareconf && \
    R -e "install.packages('remotes', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('ParallelLogger', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('SqlRender', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('httr', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('aws.s3', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('DatabaseConnector', repos = 'https://packagemanager.posit.co/cran/latest')"

RUN mkdir -p /usr/local/lib/R/etc/

    # Add the environment variable for DatabaseConnector
RUN echo "DATABASECONNECTOR_JAR_FOLDER=/usr/local/lib/R/site-library/DatabaseConnector/java/" >> /usr/local/lib/R/etc/Renviron && \
    # Download JDBC drivers for various databases
    R --vanilla -e "library(DatabaseConnector); downloadJdbcDrivers('postgresql'); downloadJdbcDrivers('redshift'); downloadJdbcDrivers('sql server'); downloadJdbcDrivers('oracle'); downloadJdbcDrivers('spark')" && \
    # Install OHDSI Achilles
    R -e "remotes::install_github('OHDSI/Achilles@v1.7.0')" && \
    # Clean up temporary files
    rm -Rf /var/lib/apt/lists/* tmp/* && \
    chown -R 10001:10001 /opt/achilles /usr/local/lib/R /usr/local/bin/*


# Copy entrypoint script and set permissions
COPY --chown=achilles --chmod=755 src/entrypoint.r ./ 

WORKDIR /tmp

# Patched CVE-2024-1597 CVE-2024-32888 CVE-2022-21724 & CVE-2022-31197
RUN rm -f /usr/local/lib/R/site-library/DatabaseConnector/java/postgresql-42.2.18.jar /usr/local/lib/R/site-library/DatabaseConnector/java/redshift-jdbc42-2.1.0.20.jar && \
    wget https://s3.amazonaws.com/redshift-downloads/drivers/jdbc/2.1.0.30/redshift-jdbc42-2.1.0.30.zip && \
    unzip redshift-jdbc42-2.1.0.30.zip && \
    mv redshift-jdbc42-2.1.0.30.jar /usr/local/lib/R/site-library/DatabaseConnector/java/ && \
    wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.3.9/postgresql-42.3.9.jar && \
    mv postgresql-42.3.9.jar /usr/local/lib/R/site-library/DatabaseConnector/java/postgresql-42.3.9.jar && \
    rm -Rf /tmp/*

    
FROM rocker/r-ubuntu


WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER=/usr/local/lib/R/site-library/DatabaseConnector/java/
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV LD_LIBRARY_PATH=$JAVA_HOME/lib/server:$LD_LIBRARY_PATH

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    r-base \
    openjdk-11-jdk-headless && \
    groupadd -g 10001 achilles && \
    useradd -m -u 10001 -g achilles achilles && \
    mkdir ./workspace && \
    chown -R achilles:achilles . && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


COPY --from=build --chown=achilles /opt/achilles /opt/achilles
COPY --from=build --chown=achilles /usr/local/bin /usr/local/bin
COPY --from=build --chown=achilles /usr/local/lib /usr/local/lib

RUN ln -s /usr/local/lib/R/site-library/DatabaseConnector/java drivers

# Switch to non-root user
USER 10001:10001

# Set working directory for the user
WORKDIR /opt/achilles/workspace

# Define the command to run
CMD ["Rscript", "/opt/achilles/entrypoint.r"]
