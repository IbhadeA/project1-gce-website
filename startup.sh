#! /bin/bash
set -eu
apt-get update -y
apt-get install -y nginx
ZONE=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata/computeMetadata/v1/instance/zone | awk -F/ '{print $NF}')
HOST=$(hostname)
cat >/var/www/html/index.html <<HTML
<!doctype html>
<html>
  <head><title>Hello from GCE</title></head>
  <body style="font-family: sans-serif;">
    <h1>It works! 🚀</h1>
    <p>Served by <b>${HOST}</b> in zone <b>${ZONE}</b>.</p>
  </body>
</html>
HTML
systemctl enable nginx
systemctl restart nginx
