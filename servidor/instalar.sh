#!/bin/bash
# Deja el servidor actualizando la web de DO-IT-3D sola desde GitHub, cada 5 minutos.
# Se corre una sola vez. No toca Ginebra, Jellyfin ni ningun otro servicio:
# solo copia archivos a la carpeta que ya sirve el contenedor doiten3d-web (puerto 3648).
set -e

REPO_URL=https://github.com/ferloprete/doiten3d-web.git
REPO=/root/doiten3d-web-repo
HTML=/srv/dev-disk-by-uuid-da56eb06-4107-4632-94ee-8c6c9afc8502/docker/appdata/doiten3d-web/html

command -v git >/dev/null || { echo "ABORTO: falta git en el servidor (apt install git)"; exit 1; }
[ -d "$HTML" ] || { echo "ABORTO: no existe $HTML"; exit 1; }
[ -d "$REPO/.git" ] || git clone -q "$REPO_URL" "$REPO"

# El actualizador vive fuera del repositorio, asi lo que se suba a GitHub
# nunca se ejecuta en el servidor: solo se copian index.html y videos/.
cat > /usr/local/bin/doiten3d-actualizar <<EOF
#!/bin/bash
set -e
cd "$REPO"
git fetch -q origin main
git reset -q --hard origin/main
mkdir -p "$HTML/videos"
cp index.html "$HTML/index.html"
cp -r videos/. "$HTML/videos/"
chmod -R a+rX "$HTML"
EOF
chmod 755 /usr/local/bin/doiten3d-actualizar

echo "*/5 * * * * root /usr/local/bin/doiten3d-actualizar >/var/log/doiten3d-actualizar.log 2>&1" > /etc/cron.d/doiten3d-web
chmod 644 /etc/cron.d/doiten3d-web

/usr/local/bin/doiten3d-actualizar
echo "Listo. La web se actualiza sola cada 5 minutos desde GitHub."
curl -s -o /dev/null -w "pagina: HTTP %{http_code}\n" http://localhost:3648/
curl -s -o /dev/null -w "video:  HTTP %{http_code}\n" http://localhost:3648/videos/fidgets.mp4
