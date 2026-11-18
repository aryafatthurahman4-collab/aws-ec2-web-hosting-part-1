# Part 3 — Domain + HTTPS

## 1. A record

Di Route 53 (atau Cloudflare/Namecheap):

| Type | Name | Value | TTL |
| --- | --- | --- | --- |
| A | `app` | Elastic IP | 300 |

Cek propagasi:

```bash
dig +short app.example.com
nslookup app.example.com
```

Kalau memakai Cloudflare, atur **DNS only (grey cloud)** saat pertama kali menerbitkan sertifikat agar challenge HTTP tidak ter-proxy. Setelah valid, boleh di-proxy.

Di VPS, pastikan `.env` memetakan port host `HTTP_PORT=80` dan
`HTTPS_PORT=443`, lalu buka TCP 80/443 pada firewall VPS dan firewall provider.
Sertifikat publik hanya bisa diterbitkan untuk domain yang mengarah ke IP publik
server. Untuk uji LAN tanpa domain, gunakan `http://192.168.1.20:8083`.

## 2. Terbitkan sertifikat

```bash
cd /opt/app
DOMAIN=app.example.com EMAIL=kamu@email.com sudo -E bash scripts/issue-cert.sh
```

Script memakai `certbot --standalone`, jadi nginx dihentikan sementara agar port 80 host bebas.

Sertifikat tersimpan di:

```text
nginx/certs/live/app.example.com/fullchain.pem
nginx/certs/live/app.example.com/privkey.pem
```

## 3. Nyalakan Nginx

```bash
docker compose up -d
docker compose exec nginx nginx -t
curl -I https://app.example.com
```

Jika sertifikat belum tersedia, Nginx tetap berjalan pada HTTP dan tidak
mengalihkan akses IP ke HTTPS. Setelah sertifikat diterbitkan, jalankan ulang
`docker compose up -d nginx` agar virtual host HTTPS dimuat.

Yang benar:

- `HTTP/2 200`
- `strict-transport-security` ada
- `http://` → `301` ke `https://`

## 4. Perpanjangan otomatis

`scripts/setup-ec2.sh` memasang cron:

```text
30 2,14 * * * /usr/local/bin/renew-cert
```

Script `renew-cert.sh`:

1. `certbot renew --webroot` (nginx tetap jalan, challenge dilayani dari `nginx/www`),
2. `nginx -s reload`.

Uji tanpa menunggu 60 hari:

```bash
docker compose --profile tls run --rm --entrypoint certbot certbot renew --dry-run
```

## 5. Verifikasi masa berlaku

```bash
openssl s_client -connect app.example.com:443 -servername app.example.com \
  </dev/null 2>/dev/null | openssl x509 -noout -dates -subject
```

Atau:

```bash
echo | openssl s_client -connect app.example.com:443 2>/dev/null | openssl x509 -noout -enddate
```

## 6. HSTS

Template memakai `max-age=86400` (1 hari) agar aman saat latihan. Setelah yakin HTTPS stabil selama beberapa hari, naikkan:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

Jangan naikkan sebelum yakin: browser akan memaksa HTTPS dan sulit dibatalkan.

## 7. Checklist HTTPS

- [ ] A record mengarah ke Elastic IP
- [ ] Port 80 & 443 terbuka di SG dan ufw
- [ ] `curl http://domain` → 301
- [ ] `curl https://domain/api/health` → 200 JSON
- [ ] Sertifikat bukan self-signed
- [ ] Renewal dry-run lulus
- [ ] Cron aktif: `ls /etc/cron.d/letsencrypt-renew`
