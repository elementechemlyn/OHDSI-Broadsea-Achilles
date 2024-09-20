FROM 201959883603.dkr.ecr.us-east-2.amazonaws.com/mdaca/base-images/ironbank-ubuntu-r:22.04_4.4.1

WORKDIR /opt/achilles
ENV DATABASECONNECTOR_JAR_FOLDER="/opt/achilles/drivers"
ENV DEBIAN_FRONTEND=noninteractive

# Create necessary directories and set up R configurations
RUN mkdir /root/.R && \
    echo "PKG_CXXFLAGS = -O3 -march=native" >> /root/.R/Makevars && \
    echo "PKG_CPPFLAGS = -I /usr/local/include" >> /root/.R/Makevars && \
    echo "PKG_FCFLAGS = -O3" >> /root/.R/Makevars && \
    apt-get update -y && \
    apt-get install -y \
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

# Install R packages and link littler
RUN R -e "install.packages('littler', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('docopt', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R -e "install.packages('rJava', repos = 'https://packagemanager.posit.co/cran/latest')" && \
    R CMD javareconf && \
    ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r

# Copy install2.r script
COPY --chmod=755 src/install2.r /usr/local/bin/install2.r 

# Install required R packages and configure environment
RUN install2.r --error --ncpus 2 --skipinstalled --repos "https://packagemanager.posit.co/cran/latest" remotes ParallelLogger SqlRender DatabaseConnector

    # Add the environment variable for DatabaseConnector
RUN echo "DATABASECONNECTOR_JAR_FOLDER=/usr/local/lib/R/site-library/DatabaseConnector/java/" >> /usr/local/lib/R/etc/Renviron && \


    # Download JDBC drivers for various databases
    R --vanilla -e "library(DatabaseConnector); downloadJdbcDrivers('postgresql'); downloadJdbcDrivers('redshift'); downloadJdbcDrivers('sql server'); downloadJdbcDrivers('oracle'); downloadJdbcDrivers('spark')" && \

    # Install OHDSI Achilles
    R -e "remotes::install_github('mdaca/OHDSI-Achilles@v1.7.2')" && \

    # Clean up temporary files
    rm -rf /var/lib/apt/lists/* /tmp/*

# Copy entrypoint script and set permissions
COPY --chown=achilles --chmod=755 src/entrypoint.r ./

# Switch to non-root user
USER 10001:10001

# Set working directory for the user
WORKDIR /opt/achilles/workspace

# Define the command to run
CMD ["Rscript", "/opt/achilles/entrypoint.r"]
