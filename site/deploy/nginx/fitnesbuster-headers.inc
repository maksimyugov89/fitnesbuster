# Заголовки безопасности сайта fitnesbuster.ru.
# Подключается через include в каждом location: nginx не наследует add_header
# в location, где объявлены свои add_header, поэтому файл общий.

add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
add_header Cross-Origin-Resource-Policy "same-origin" always;

# Строгая CSP: сайт не тянет ничего извне (шрифты, скриншоты, скрипты — свои).
# Единственный встроенный скрипт — разметка JSON-LD: разрешаем по хешу.
add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self' 'sha256-JpxvP2QZTyAg/5Arhy6nOdN4EnWVGW6HKEMkUT7EsVk='; font-src 'self'; connect-src 'self'; manifest-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests" always;
