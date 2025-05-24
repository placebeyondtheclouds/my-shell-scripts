#!/bin/bash

WEBAPP_PORT=${1:-8080}
SSL_PORT=${2:-8081}
WEBAPP_NAME=${3:-webapp.local}

if [ "$EUID" -ne 0 ]; then
    exit 1
fi
if ! command -v nginx &>/dev/null || ! command -v openssl &>/dev/null; then
    apt update
    apt install -y nginx openssl
fi

mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/$WEBAPP_NAME.key \
    -out /etc/nginx/ssl/$WEBAPP_NAME.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$WEBAPP_NAME"
chmod 600 /etc/nginx/ssl/$WEBAPP_NAME.key
chown root:root /etc/nginx/ssl/$WEBAPP_NAME.key

cat >/etc/nginx/sites-available/$WEBAPP_NAME <<EOF
server {
    listen $SSL_PORT ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/ssl/$WEBAPP_NAME.crt;
    ssl_certificate_key /etc/nginx/ssl/$WEBAPP_NAME.key;

    location / {
        proxy_pass http://localhost:$WEBAPP_PORT;
        # Add WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Standard headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Timeouts for WebSocket connections
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/$WEBAPP_NAME
ln -s /etc/nginx/sites-available/$WEBAPP_NAME /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl restart nginx
