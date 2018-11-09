
FROM nginx:1.15.5-alpine

RUN rm -rf /etc/nginx/conf.d/* /etc/nginx/nginx.conf

RUN mkdir /cran && chown nginx:nginx /cran

COPY nginx.conf /etc/nginx/nginx.conf
