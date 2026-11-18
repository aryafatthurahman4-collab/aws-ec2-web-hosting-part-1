#!/bin/sh
set -eu

template_source=/etc/nginx/templates
template_runtime=/tmp/nginx-templates
certificate_dir="/etc/letsencrypt/live/${DOMAIN:-}"

mkdir -p "$template_runtime"
cp "$template_source/default.conf.template" "$template_runtime/default.conf.template"

# Enable the domain redirect and HTTPS virtual host only after Certbot has
# created both files. This lets the app start on its LAN/public IP over HTTP.
if [ -n "${DOMAIN:-}" ] \
  && [ -s "$certificate_dir/fullchain.pem" ] \
  && [ -s "$certificate_dir/privkey.pem" ]; then
  cp "$template_source/tls.conf.template" "$template_runtime/tls.conf.template"
fi

export NGINX_ENVSUBST_TEMPLATE_DIR="$template_runtime"
exec /docker-entrypoint.sh nginx -g 'daemon off;'
