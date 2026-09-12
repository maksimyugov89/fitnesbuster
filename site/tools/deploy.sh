#!/usr/bin/env bash
# Выкладка сайта FitnesBuster на VPS (72.56.84.225) одной командой.
#
# Что делает: собирает архив только из того, что нужно веб-серверу
# (страницы, языковые разделы, ассеты, nginx-конфиги) и разворачивает
# его в /opt/fitnesbuster/site и conf.d. APK и исходники языков
# (i18n/, tools/) на сервер не уезжают.
#
# Использование:  bash site/tools/deploy.sh
set -euo pipefail

HOST="${FB_HOST:-root@72.56.84.225}"
REMOTE_SITE=/opt/fitnesbuster/site
REMOTE_CONF=/opt/storyhero/storyhero/nginx/conf.d
HERE="$(cd "$(dirname "$0")/.." && pwd)"   # каталог site/

LANGS="en de es fr it pt tr uk be ar hi ja ko zh"
TARBALL="$(mktemp -t fb-site-XXXX).tgz"

echo "== собираю архив из $HERE"
# Опции --exclude должны идти ДО списка файлов: иначе GNU tar (в том числе
# MSYS-сборка на Windows) считает их позиционными и падает с ошибкой.
tar czf "$TARBALL" -C "$HERE" \
  --exclude='*.bak' --exclude='*.pre-i18n' --exclude='_*' \
  index.html 404.html privacy.html terms.html robots.txt sitemap.xml \
  site.webmanifest .well-known \
  assets \
  $LANGS

echo "== заливаю на $HOST"
scp -o BatchMode=yes "$TARBALL" "$HOST:/tmp/fb-site.tgz"
rm -f "$TARBALL"

echo "== разворачиваю"
ssh -o BatchMode=yes "$HOST" "
  set -e
  mkdir -p $REMOTE_SITE
  tar xzf /tmp/fb-site.tgz -C $REMOTE_SITE
  rm -f /tmp/fb-site.tgz
  for d in $LANGS; do
    chmod 755 $REMOTE_SITE/\$d 2>/dev/null || true
    chmod 644 $REMOTE_SITE/\$d/*.html 2>/dev/null || true
  done
  find $REMOTE_SITE -type d -exec chmod 755 {} +
  find $REMOTE_SITE -type f -exec chmod 644 {} +
  echo 'файлов в дереве:' \$(find $REMOTE_SITE -type f | wc -l)
"

echo "== конфиги nginx (с бэкапом)"
scp -o BatchMode=yes "$HERE"/deploy/nginx/fitnesbuster.conf "$HERE"/deploy/nginx/fitnesbuster-headers.inc \
    "$HOST:/tmp/"
ssh -o BatchMode=yes "$HOST" "
  set -e
  cp $REMOTE_CONF/fitnesbuster.conf $REMOTE_CONF/fitnesbuster.conf.bak-\$(date +%F-%H%M) 2>/dev/null || true
  cp $REMOTE_CONF/fitnesbuster-headers.inc $REMOTE_CONF/fitnesbuster-headers.inc.bak-\$(date +%F-%H%M) 2>/dev/null || true
  install -m 644 /tmp/fitnesbuster.conf $REMOTE_CONF/fitnesbuster.conf
  install -m 644 /tmp/fitnesbuster-headers.inc $REMOTE_CONF/fitnesbuster-headers.inc
  rm -f /tmp/fitnesbuster.conf /tmp/fitnesbuster-headers.inc
"

echo "== проверяю nginx и перезагружаю"
ssh -o BatchMode=yes "$HOST" "
  docker exec storyhero-nginx nginx -t && docker exec storyhero-nginx nginx -s reload
"

echo "== готово. Проверка:"
for u in / /en/ /de/ /ar/ /zh/ /privacy.html; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://fitnesbuster.ru$u")
  echo "  $u → $code"
done
