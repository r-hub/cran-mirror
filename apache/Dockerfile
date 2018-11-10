
FROM httpd:2.4.37-alpine

COPY conf /conf
COPY entrypoint.sh /entrypoint.sh

RUN mkdir -p /cran && \
    chown daemon:daemon /cran
