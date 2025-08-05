# Traefik Reverse Proxy Configuration

This setup configures Traefik to:
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

2. Update configuration:
   - Edit `traefik.yml` to set your email for Let's Encrypt
   - Edit `dynamic.yml` to set your redirect domain (replace `example-redirect.com`)

3. Configure your backend services in `docker-compose.yml` (see examples below)

4. Start Traefik:
   ```bash
   docker-compose up -d
   ```

## How it works

- **Valid domains**: Services with proper Traefik labels will get Let's Encrypt certificates
- **Unknown domains**: Any request to an unknown domain will:
  1. Receive Traefik's auto-generated self-signed certificate
  2. Get redirected to the external domain specified in `dynamic.yml`

## Configuring Backend Services

Add your backend services to `docker-compose.yml`. Here are common examples:

### Example 1: Simple Web Application
```yaml
  my-webapp:
    image: your-app:latest
    container_name: my-webapp
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`app.yourdomain.com`)"
      - "traefik.http.routers.webapp.tls=true"
      - "traefik.http.routers.webapp.tls.certresolver=letsencrypt"
      - "traefik.http.routers.webapp.priority=10"
      - "traefik.http.services.webapp.loadbalancer.server.port=3000"  # Your app's port
```

### Example 2: API Service
```yaml
  api-service:
    image: your-api:latest
    container_name: api-service
    networks:
      - proxy
    environment:
      - NODE_ENV=production
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.yourdomain.com`)"
      - "traefik.http.routers.api.tls=true"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
      - "traefik.http.routers.api.priority=10"
      - "traefik.http.services.api.loadbalancer.server.port=8080"
```

### Example 3: Multiple Domains for One Service
```yaml
  multi-domain-app:
    image: your-app:latest
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.multiapp.rule=Host(`www.yourdomain.com`) || Host(`yourdomain.com`)"
      - "traefik.http.routers.multiapp.tls=true"
      - "traefik.http.routers.multiapp.tls.certresolver=letsencrypt"
      - "traefik.http.routers.multiapp.priority=10"
      - "traefik.http.services.multiapp.loadbalancer.server.port=80"
```

## Important Notes

- Ensure your backend service is on the same network (`proxy`)
- Set the correct port in the loadbalancer configuration
- Higher priority numbers take precedence (default router has priority 1)
- Let's Encrypt has rate limits - use staging environment for testing