# Nginx — ACCESS API (port 80 → 3001)

## Copy to server

From your PC (project root):

```powershell
scp deploy/nginx/access root@103.125.217.117:/etc/nginx/sites-available/access
```

Or on the server, after cloning the repo:

```bash
sudo cp /opt/access_mobile/deploy/nginx/access /etc/nginx/sites-available/access
```

## Enable

```bash
sudo ln -sf /etc/nginx/sites-available/access /etc/nginx/sites-enabled/access
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

## Test

```bash
curl -s http://103.125.217.117/api/health
```

Browser: `http://103.125.217.117/api/health`

## Domain + HTTPS (later)

Replace `server_name 103.125.217.117;` with your domain, then:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

Update `CORS_ORIGINS` and `ALLOWED_HOSTS` in `access_backend/.env` on the server.
