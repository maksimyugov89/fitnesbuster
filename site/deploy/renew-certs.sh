#!/usr/bin/env bash
# Продление сертификатов Let's Encrypt для storyhero.ru и fitnesbuster.ru.
# Запускается из /etc/cron.d/certbot-renew. Лог — /var/log/certbot-renew.log.
set -uo pipefail

STACK=/opt/storyhero/storyhero
LOG=/var/log/certbot-renew.log
DOCKER=/usr/bin/docker

exec 9>/var/lock/certbot-renew.lock
flock -n 9 || { echo "$(date -Is) уже запущено, выходим" >> "$LOG"; exit 0; }

cd "$STACK" || exit 1

# Замок certbot старше часа — снимаем: иначе продление встанет навсегда.
$DOCKER compose run -T --rm --entrypoint sh certbot -c '
  if [ -f /etc/letsencrypt/.certbot.lock ]; then
    age=$(( $(date +%s) - $(date -r /etc/letsencrypt/.certbot.lock +%s) ))
    if [ "$age" -gt 3600 ]; then rm -f /etc/letsencrypt/.certbot.lock; echo "снят старый замок ($age с)"; fi
  fi' >> "$LOG" 2>&1

echo "$(date -Is) продление" >> "$LOG"
timeout 900 $DOCKER compose run -T --rm --entrypoint certbot certbot renew \
  --webroot -w /var/www/certbot --non-interactive --quiet >> "$LOG" 2>&1
RC=$?
echo "$(date -Is) certbot вернул $RC" >> "$LOG"

if $DOCKER exec storyhero-nginx nginx -t >> "$LOG" 2>&1; then
  $DOCKER exec storyhero-nginx nginx -s reload >> "$LOG" 2>&1
fi
exit $RC
