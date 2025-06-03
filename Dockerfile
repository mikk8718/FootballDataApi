FROM rstudio/plumber

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev



WORKDIR /workspace

COPY / /workspace

RUN R -e "install.packages('plumber')"
RUN R -e "install.packages('dplyr')"

EXPOSE 8000

CMD ["Rscript", "start.R"]
