#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

LOCAL_SUBNET="10.0.0.0/24"
SERVER_IP="10.0.0.1"

check_dns_entry() {
    local host=$1
    grep -q "^${SERVER_IP}.*${host}$" /etc/hosts
    return $?
}

# these are some of the domain names that I saw in the wireshark capture
KINDLE_HOSTS=(
    "dogvgb9ujhybx.cloudfront.net"
    "pins.amazon.com"
    "api.amazon.com"
    "dcape-na.amazon.com"
    "unagi-na.amazon.com"
    "device-messaging-na.amazon.com"
    "todo-ta-g7g.amazon.com"
)

# Add DNS entries to /etc/hosts if they don't exist
for host in "${KINDLE_HOSTS[@]}"; do
    if ! check_dns_entry "$host"; then
        echo "${SERVER_IP}    ${host}" >>/etc/hosts
        echo "Added DNS entry for ${host}"
    else
        echo "DNS entry for ${host} already exists"
    fi
done

if ! command -v nginx &>/dev/null || ! command -v openssl &>/dev/null; then
    echo "Installing nginx and openssl..."
    apt update
    apt install -y nginx openssl
else
    echo "nginx and openssl are already installed"
fi

# Create self-signed certificates for HTTPS if not already present
if [ ! -f /etc/nginx/ssl/kindle.crt ]; then
    echo "Creating self-signed SSL certificate..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/kindle.key \
        -out /etc/nginx/ssl/kindle.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=kindle.local"
else
    echo "Self-signed SSL certificate already exists"
fi

# Configure nginx for HTTPS if not already configured
if [ ! -f /etc/nginx/sites-available/kindle ]; then
    echo "Configuring nginx for HTTPS..."
    cat >/etc/nginx/sites-available/kindle <<EOL
server {
    listen 443 ssl;
    server_name *.amazon.com;

    ssl_certificate /etc/nginx/ssl/kindle.crt;
    ssl_certificate_key /etc/nginx/ssl/kindle.key;

    location / {
        return 200 '{"status":"OK"}';
        add_header Content-Type application/json;
    }
}
EOL
else
    echo "nginx configuration already exists"
fi

# Enable the nginx site if not already enabled
if [ ! -f /etc/nginx/sites-enabled/kindle ]; then
    echo "Enabling nginx site..."
    ln -s /etc/nginx/sites-available/kindle /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
else
    echo "nginx site already enabled"
fi

# Restart nginx
systemctl restart nginx

echo "Kindle router setup completed"
echo "Please ensure your Kindle device uses ${SERVER_IP} as its DNS server"
echo "This setup will work for any device in the ${LOCAL_SUBNET} subnet"

read -p "Press [Enter] to stop or [Ctrl+C] to leave it running"

systemctl stop nginx
systemctl disable nginx
