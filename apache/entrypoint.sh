
set -e

cp -r /conf/* /usr/local/apache2/conf/

# Try to obtain a cert, or renew it
certbot certonly -n --standalone --preferred-challenges http \
	-d ${CRAN_SERVER_NAME} --agree-tos --email ${LETSENCRYPT_EMAIL}

exec httpd-foreground
