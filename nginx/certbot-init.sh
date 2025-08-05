#!/bin/bash

# Script to obtain initial certificates from Let's Encrypt

# IMPORTANT: Update these variables before running!
DOMAINS=""  # Space-separated list of domains, e.g., "app.example.com api.example.com"
EMAIL=""    # Your email for Let's Encrypt notifications

if [ -z "$DOMAINS" ] || [ -z "$EMAIL" ]; then
    echo "ERROR: Please edit this script and set DOMAINS and EMAIL variables"
    exit 1
fi

for DOMAIN in $DOMAINS; do
    echo "Obtaining certificate for $DOMAIN..."
    
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d $DOMAIN
done

echo "Certificate initialization complete!"