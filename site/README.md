# Сайт FitnesBuster — fitnesbuster.ru

Одностраничный сайт-презентация приложения: **https://fitnesbuster.ru/**

Документация для разработчика. Всё, что про само приложение, — в корне репозитория.

## Структура

```
site/
├── index.html            — одностраничник: герой, возможности, экраны, темы, данные, скачивание, FAQ
├── privacy.html          — политика конфиденциальности (тот же текст, что в приложении)
├── terms.html            — условия использования (тот же текст, что в приложении)
├── 404.html              — страница ошибки
├── robots.txt, sitemap.xml, site.webmanifest
├── .well-known/security.txt
├── assets/
│   ├── css/site.css      — дизайн-система: 6 тем приложения как CSS-переменные
│   ├── js/site.js        — темы, 3D-наклон телефонов, появление блоков, лайтбокс
│   ├── fonts/            — Syne + Inter (subset, woff2, ~150 КБ на всё)
│   └── img/
│       ├── screens/      — скриншоты приложения (webp + jpg)
│       ├── icons/        — иконки из приложения (glow-варианты) + иконки сайта
│       ├── og-cover.jpg  — превью для мессенджеров
│       └── qr-download.png
└── deploy/               — конфиги сервера (в веб-корень не копируются)
```

## Локальный просмотр

```bash
cd site && python -m http.server 8123
# http://127.0.0.1:8123/
```

Ссылка на APK локально не работает: файл живёт только на сервере (`/download/`).

## Правки текста и цен

Весь текст — прямо в `index.html`, разметка разбита комментариями по секциям.
Версию и размер сборки нужно править в блоке `#download` при каждом релизе.

## Как это развёрнуто

Домен указывает на сервер **72.56.84.225** (ne45-amsterdam) — тот же, где живёт storyhero.ru.

- Статику отдаёт отдельный контейнер `fitnesbuster-web` (образ `nginx:alpine`),
  в него примонтирован каталог `/opt/fitnesbuster/site`, наружу портов не открывает.
- Внешний nginx (`storyhero-nginx`) проксирует `fitnesbuster.ru` внутрь по имени контейнера.
  Его конфиг: `/opt/storyhero/storyhero/nginx/conf.d/fitnesbuster.conf`
  + общие заголовки `fitnesbuster-headers.inc` (`.inc`, чтобы не подхватывался авто-include).
- Сертификат Let's Encrypt — в общем томе `app_certbot_data`, выпускается так:

```bash
ssh root@72.56.84.225
cd /opt/storyhero/storyhero
docker compose run -T --rm certbot certonly --webroot -w /var/www/certbot \
  -d fitnesbuster.ru -d www.fitnesbuster.ru --agree-tos --no-eff-email \
  --email maksim.yugov.89@gmail.com --non-interactive
docker exec storyhero-nginx nginx -t && docker exec storyhero-nginx nginx -s reload
```

Авто-продление — `/etc/cron.d/certbot-renew` (ежедневно в 4:00), оно же продлевает
сертификат storyhero.ru: раньше авто-продления на сервере не было вовсе.

### Обновить файлы сайта

```bash
cd site
scp -r index.html privacy.html terms.html 404.html robots.txt sitemap.xml \
  site.webmanifest favicon.ico .well-known assets root@72.56.84.225:/opt/fitnesbuster/site/
```

### Обновить APK

```bash
scp build/app/outputs/flutter-apk/app-release.apk \
  root@72.56.84.225:/opt/fitnesbuster/site/download/fitnesbuster-<версия>.apk
```

После загрузки обязательно сверить на сервере `sha256sum` с локальным и обновить
размер, версию и контрольную сумму в блоке `#download` на странице.

## Безопасность

- Только HTTPS, HTTP и `www` редиректят на `https://fitnesbuster.ru`.
- HSTS (1 год, includeSubDomains), `nosniff`, `X-Frame-Options: DENY`,
  `Referrer-Policy`, `Permissions-Policy`, COOP/CORP.
- Строгая CSP: `default-src 'self'` — сайт не тянет ничего извне (шрифты, картинки,
  скрипты только свои, без CDN и трекеров). Единственный встроенный скрипт — разметка
  JSON-LD, разрешена по SHA-256-хешу; при правке JSON-LD хеш в
  `deploy/nginx/fitnesbuster-headers.inc` нужно пересчитать.
- APK отдаётся как `application/vnd.android.package-archive` с именем файла,
  контрольная сумма указана на странице.
- `/.well-known/security.txt` — контакт для сообщений об уязвимостях.
- Контраст текста проверен по WCAG AA во всех 6 темах, есть skip-ссылка,
  клавиатурная навигация и поддержка `prefers-reduced-motion`.
