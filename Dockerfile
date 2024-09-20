FROM 201959883603.dkr.ecr.us-east-2.amazonaws.com/mdaca/base-images/ironbank-ubuntu-r:22.04_4.4.1

WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/achilles/drivers"
ENV DEBIAN_FRONTEND=noninteractive

# Create necessary directories and set up R configurations
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    r-base \
    r-base-dev \
    openjdk-11-jdk-headless && \
    groupadd -g 10001 achilles && \
    useradd -m -u 10001 -g achilles achilles && \
    mkdir ./drivers && \
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
    R -e "install.packages('DatabaseConnector', repos = 'https://packagemanager.posit.co/cran/latest')"

    # Add the environment variable for DatabaseConnector
RUN echo "DATABASECONNECTOR_JAR_FOLDER=/usr/local/lib/R/site-library/DatabaseConnector/java/" >> /usr/local/lib/R/etc/Renviron && \
    # Download JDBC drivers for various databases
    R --vanilla -e "library(DatabaseConnector); downloadJdbcDrivers('postgresql'); downloadJdbcDrivers('redshift'); downloadJdbcDrivers('sql server'); downloadJdbcDrivers('oracle'); downloadJdbcDrivers('spark')" && \
    # Install OHDSI Achilles
    R -e "remotes::install_github('mdaca/OHDSI-Achilles@v1.7.2')" && \
    # Clean up temporary files
    rm -Rf /var/lib/apt/lists/* /tmp/* && \
    chown -R 10001:10001 /opt/achilles



# Copy entrypoint script and set permissions
COPY --chown=achilles --chmod=755 src/entrypoint.r ./ 

WORKDIR /tmp

# Patched CVE-2024-1597 CVE-2024-32888 CVE-2022-21724 & CVE-2022-31197
RUN apt-get update -y && \
    rm -f /usr/local/lib/R/site-library/DatabaseConnector/java/postgresql-42.2.18.jar /usr/local/lib/R/site-library/DatabaseConnector/java/redshift-jdbc42-2.1.0.20.jar && \
    wget https://s3.amazonaws.com/redshift-downloads/drivers/jdbc/2.1.0.30/redshift-jdbc42-2.1.0.30.zip && \
    mv redshift-jdbc42-2.1.0.30.jar /usr/local/lib/R/site-library/DatabaseConnector/java/ && \
    wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.28/postgresql-42.2.28.jar && \
    mv postgresql-42.2.28.jar /usr/local/lib/R/site-library/DatabaseConnector/java/ && \
    rm -Rf /tmp/*

    


# Switch to non-root user
USER 10001:10001

# Set working directory for the user
WORKDIR /opt/achilles/workspace

# Define the command to run
CMD ["Rscript", "/opt/achilles/entrypoint.r"]
