/* ==========================================================================
   FitnesBuster — поведение сайта.
   Без внешних зависимостей: темы, 3D-наклон телефонов, появление блоков
   и лайтбокс экранов.
   ========================================================================== */
(() => {
  'use strict';

  const root = document.documentElement;
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ── Темы оформления ─────────────────────────────────────────────────────
     Список совпадает с темами приложения (lib/core/theme/theme_service.dart). */
  const THEMES = ['neon', 'ocean', 'sunset', 'forest', 'purple', 'cyber'];
  const THEME_KEY = 'fb-theme';

  const applyTheme = (name, persist) => {
    if (!THEMES.includes(name)) name = 'neon';
    root.dataset.theme = name;

    document.querySelectorAll('[data-theme-pick]').forEach((btn) => {
      btn.setAttribute('aria-pressed', String(btn.dataset.themePick === name));
    });

    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) {
      const bg = getComputedStyle(root).getPropertyValue('--bg').trim();
      if (bg) meta.setAttribute('content', bg);
    }

    if (persist) {
      try {
        localStorage.setItem(THEME_KEY, name);
      } catch (err) {
        /* приватный режим — просто не запоминаем */
      }
    }
  };

  let saved = null;
  try {
    saved = localStorage.getItem(THEME_KEY);
  } catch (err) {
    saved = null;
  }
  applyTheme(saved || 'neon', false);

  document.querySelectorAll('[data-theme-pick]').forEach((btn) => {
    btn.addEventListener('click', () => applyTheme(btn.dataset.themePick, true));
  });

  /* ── Шапка «прилипает» ───────────────────────────────────────────────── */
  const header = document.getElementById('header');
  if (header) {
    const onScroll = () => header.classList.toggle('is-stuck', window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ── Появление блоков при прокрутке ──────────────────────────────────── */
  const revealables = document.querySelectorAll('.reveal');
  if (reduceMotion || !('IntersectionObserver' in window)) {
    revealables.forEach((el) => el.classList.add('in'));
  } else {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('in');
            io.unobserve(entry.target);
          }
        });
      },
      { rootMargin: '0px 0px -12% 0px', threshold: 0.08 }
    );
    revealables.forEach((el) => io.observe(el));
  }

  /* ── 3D-наклон телефонов за курсором ─────────────────────────────────── */
  const stage = document.getElementById('stage');
  const phones = document.getElementById('phones');
  const finePointer = window.matchMedia('(pointer: fine)').matches;

  if (stage && phones && finePointer && !reduceMotion) {
    let frame = 0;
    let targetX = 6;
    let targetY = -14;

    const render = () => {
      frame = 0;
      phones.style.setProperty('--rx', `${targetX.toFixed(2)}deg`);
      phones.style.setProperty('--ry', `${targetY.toFixed(2)}deg`);
    };

    stage.addEventListener('pointermove', (event) => {
      const box = stage.getBoundingClientRect();
      const px = (event.clientX - box.left) / box.width - 0.5;
      const py = (event.clientY - box.top) / box.height - 0.5;
      targetY = -14 + px * 16;
      targetX = 6 - py * 12;
      if (!frame) frame = requestAnimationFrame(render);
    });

    stage.addEventListener('pointerleave', () => {
      targetX = 6;
      targetY = -14;
      if (!frame) frame = requestAnimationFrame(render);
    });
  } else if (phones) {
    phones.style.setProperty('--rx', '0deg');
    phones.style.setProperty('--ry', '0deg');
  }

  /* ── Лайтбокс экранов ────────────────────────────────────────────────── */
  const lightbox = document.getElementById('lightbox');
  const lbImg = document.getElementById('lightbox-img');
  const lbTitle = document.getElementById('lightbox-title');
  const shots = Array.from(document.querySelectorAll('.shot'));

  if (lightbox && lbImg && shots.length) {
    let current = 0;

    const show = (index) => {
      current = (index + shots.length) % shots.length;
      const shot = shots[current];
      const img = shot.querySelector('img');
      lbImg.src = shot.dataset.full;
      lbImg.srcset = '';
      lbImg.alt = img ? img.alt : '';
      if (lbTitle) lbTitle.textContent = shot.dataset.caption || '';
    };

    const open = (index) => {
      show(index);
      if (typeof lightbox.showModal === 'function') lightbox.showModal();
      else lightbox.setAttribute('open', '');
      document.body.classList.add('is-locked');
    };

    shots.forEach((shot, index) => {
      shot.addEventListener('click', () => open(index));
    });

    const close = () => {
      if (typeof lightbox.close === 'function') lightbox.close();
      else lightbox.removeAttribute('open');
      document.body.classList.remove('is-locked');
    };

    document.getElementById('lightbox-close')?.addEventListener('click', close);
    document.getElementById('lightbox-prev')?.addEventListener('click', () => show(current - 1));
    document.getElementById('lightbox-next')?.addEventListener('click', () => show(current + 1));

    lightbox.addEventListener('click', (event) => {
      if (event.target === lightbox) close();
    });

    lightbox.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowLeft') show(current - 1);
      if (event.key === 'ArrowRight') show(current + 1);
    });

    /* Свайпы на телефоне */
    let startX = 0;
    lightbox.addEventListener(
      'touchstart',
      (event) => {
        startX = event.changedTouches[0].clientX;
      },
      { passive: true }
    );
    lightbox.addEventListener(
      'touchend',
      (event) => {
        const dx = event.changedTouches[0].clientX - startX;
        if (Math.abs(dx) > 45) show(dx < 0 ? current + 1 : current - 1);
      },
      { passive: true }
    );

    /* Плавная прокрутка ленты к открытому экрану */
    shots.forEach((shot) => {
      shot.addEventListener('focus', () => {
        shot.scrollIntoView({ block: 'nearest', inline: 'center', behavior: reduceMotion ? 'auto' : 'smooth' });
      });
    });
  }
})();
