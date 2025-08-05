# Nginx Reverse Proxy Configuration

This setup configures Nginx to:
- Serve valid Let's Encrypt certificates for configured domains
- Serve self-signed certificates and redirect to an external domain for all other requests

## Prerequisites

- Docker and Docker Compose installed
- Domain names pointing to your server (for Let's Encrypt certificates)
- Your backend applications ready to be deployed

## Setup Instructions

1. Create the Docker network:
   ```bash
   docker network create proxy
   ```

2. Generate self-signed certificate:
   ```bash
   ./generate-self-signed.sh
   ```

3. Update configuration:
   - Edit `conf.d/default.conf` to set your redirect domain (replace `example-redirect.com`)
   - Edit `certbot-init.sh` to set your domains and email

4. Create Nginx configuration files for your domains (see examples below)

5. Configure your backend services in `docker-compose.yml`

6. Start Nginx:
   ```bash
   docker-compose up -d
   ```

7. Initialize Let's Encrypt certificates:
   ```bash
   ./certbot-init.sh
   ```

## How it works

- **Valid domains**: Configure in `conf.d/` directory. These will use Let's Encrypt certificates.
- **Unknown domains**: Any request to an unknown domain will:
  1. Receive a self-signed certificate
  2. Get redirected to the external domain specified in `default.conf`

## Configuring Backend Services

### Step 1: Add your backend service to docker-compose.yml

```yaml
  my-backend:
    image: your-app:latest
    container_name: my-backend
    networks:
      - proxy
    # Add any other configuration your app needs
```

### Step 2: Create Nginx configuration

Create a file `conf.d/yourdomain.conf`:

#### Example 1: Simple Web Application
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name app.yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.yourdomain.com;

    # Certificate paths
    ssl_certificate /etc/letsencrypt/live/app.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.yourdomain.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://my-backend:3000;  # Your container name and port
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Example 2: API with Custom Path
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    location /api/ {
        proxy_pass http://api-backend:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # API specific settings
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
```

#### Example 3: WebSocket Support
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name ws.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ws.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/ws.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ws.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://websocket-app:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Adding a new domain

1. Create a new configuration file in `conf.d/yourdomain.conf`
2. Add the domain to `certbot-init.sh`
3. Run `./certbot-init.sh` to obtain the certificate
4. Reload Nginx: `docker-compose exec nginx nginx -s reload`

## Important Notes

- Ensure your backend service is on the same network (`proxy`)
- The proxy_pass should use the container name from docker-compose.yml
- Let's Encrypt has rate limits - use staging environment for testing
- Certificate renewal runs automatically via the certbot container