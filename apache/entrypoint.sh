
set -e

cp -r /conf/* /usr/local/apache2/conf/

# TODO: Let's Encrypt

exec httpd-foreground
