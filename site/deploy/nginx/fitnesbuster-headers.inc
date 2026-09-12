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
add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self' 'sha256-1EDJ+bb3knmkCc/7qc735bAPpzRC/203Squ6JiKbRQE=' 'sha256-A3itf6bT6bjszwN+sLzUeSiKpyTUPCbnJyfzL9qObVU=' 'sha256-Ct4XPaFRoX8l+I1fLcmuoSbxG7H3GsOkHSZ0IqvGc3k=' 'sha256-I0z/+IHQ/Uk014/awjV0WUBgZXoU+Fv1mvcQ9wdrBsQ=' 'sha256-IoA/V3p/pxFYa0l4sDYTG8ZSND1S+VBLJPTdj1vh36w=' 'sha256-JpxvP2QZTyAg/5Arhy6nOdN4EnWVGW6HKEMkUT7EsVk=' 'sha256-M+9ZT7xDn0HPBWEllJxgAnLlJoC9MUGPEUz/hAB6xZM=' 'sha256-QstGmk+1rE/ZLVfPwu4Vl1L9uqBYxC2g6gPuInIrZnA=' 'sha256-bLDKsVT6UjXFpaAjjQ9U4YaEysqjPgogpYSXiXHEut4=' 'sha256-dCEu7gjSvPCKSJyaPfciAkiVGH3sl0E/D8LIuRKq+y8=' 'sha256-e0tJwGVAek5gKdGpqY5oM+3hDh3U+u5Whx8DtRN76po=' 'sha256-lx2pXXER/KJXAZiax77LcyA+P0gdLHLrvOsswGbITO0=' 'sha256-mxQ9LYEVlWzK7LXKtKvS2apt2pp1TA24Yc0itfcGu50=' 'sha256-pJJNguHItI2uowDsEQlDNgyZ+ho0XE5U/iFs+2jMVFI=' 'sha256-v8kUoJxxM9iItrkoRqD4TlQRVnAY3z3OTXi1Yvw95aM='; font-src 'self'; connect-src 'self'; manifest-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests" always;
