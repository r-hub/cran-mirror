
FROM httpd:2.4.51-alpine

RUN apk add --no-cache certbot

RUN mkdir -p /cran && \
    chown daemon:daemon /cran

COPY conf /conf
COPY entrypoint.sh /entrypoint.sh
