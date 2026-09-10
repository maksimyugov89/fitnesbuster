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
│       ├── icons/        — иконки приложения: <имя>-base.webp (базовый слой)
│       │                   + <имя>.png (маска бликов); logo.webp — знак в шапке
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

## Иконки

Каждая иконка рисуется двумя слоями — ровно как `AppIcon` в приложении
(`lib/core/theme/app_images.dart`):

1. `<имя>-base.webp` — базовое изображение из `assets/icons/`;
2. `<имя>.png` — файл бликов оттуда же (`*_glow.png`), залитый цветом активной
   темы (`--primary`) через `mask-image`.

В покое подсветка приглушена (55%), при наведении и фокусе — 100%, рост ×1.16 и
свечение цветом темы. Оба слоя сняты с одного кадра 512×512, поэтому совпадают
пиксель в пиксель: не собирайте их из разных источников.

Как добавить иконку: переснимите пару из `assets/icons/` (`<имя>.png` +
`<имя>_glow.png`) в 160×160 webp/png, положите в `assets/img/icons/`, в HTML
укажите `class="card__icon i-<имя>"` и `src="...-base.webp"`, а в CSS добавьте
`.i-<имя> { --icon-mask: url(../img/icons/<имя>.png); }`.

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

После загрузки сверить на сервере `sha256sum` с локальным (контроль доставки),
а в блоке `#download` на странице обновить версию и размер. Контрольную сумму
на страницу не выводим: ею никто не пользуется.

## Кэш и обновления

- HTML, стили и скрипты отдаются с `Cache-Control: no-cache`: браузер каждый раз
  перепроверяет файл и получает дешёвый 304, поэтому правки видны сразу.
- Картинки и шрифты кэшируются на 7 дней (7 дней у них в `deploy/nginx`).
- Ссылки на `site.css` и `site.js` содержат версию (`?v=N`). **При правке этих
  файлов поднимите `N` во всех четырёх страницах**, иначе у тех, кто уже открывал
  сайт, останется старая версия из кэша.

## Безопасность

- Только HTTPS, HTTP и `www` редиректят на `https://fitnesbuster.ru`.
- HSTS (1 год, includeSubDomains), `nosniff`, `X-Frame-Options: DENY`,
  `Referrer-Policy`, `Permissions-Policy`, COOP/CORP.
- Строгая CSP: `default-src 'self'` — сайт не тянет ничего извне (шрифты, картинки,
  скрипты только свои, без CDN и трекеров). Единственный встроенный скрипт — разметка
  JSON-LD, разрешена по SHA-256-хешу; при правке JSON-LD хеш в
  `deploy/nginx/fitnesbuster-headers.inc` нужно пересчитать.
- APK отдаётся как `application/vnd.android.package-archive` с именем файла
  и кэшируется на год — файл неизменяемый, версии выкладываются под новым именем.
- `/.well-known/security.txt` — контакт для сообщений об уязвимостях.
- Контраст текста проверен по WCAG AA во всех 6 темах, есть skip-ссылка,
  клавиатурная навигация и поддержка `prefers-reduced-motion`.
