
FROM httpd:2.4.35-alpine

RUN apk add --no-cache certbot py2-pip

RUN mkdir -p /cran && \
    chown daemon:daemon /cran

COPY conf /conf
COPY entrypoint.sh /entrypoint.sh
