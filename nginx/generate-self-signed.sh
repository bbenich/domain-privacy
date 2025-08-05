#!/bin/bash

# Generate self-signed certificate
mkdir -p certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout certs/self-signed.key \
    -out certs/self-signed.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=default.local"

chmod 644 certs/self-signed.crt
chmod 600 certs/self-signed.key

echo "Self-signed certificate generated in certs/"