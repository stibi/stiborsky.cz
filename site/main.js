// Typewriter reveal of the hero line. Progressive enhancement:
// the full text is already in the DOM, so it works without JS too.
(function () {
  var el = document.querySelector('.eyebrow[data-typed]');
  if (!el) return;
  var text = el.getAttribute('data-typed');
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce) { el.classList.add('typed-done'); return; }
  el.textContent = '';
  el.classList.add('typing');
  var i = 0;
  function tick() {
    el.textContent = text.slice(0, i);
    if (i++ < text.length) {
      setTimeout(tick, 40 + Math.random() * 45);
    } else {
      el.classList.remove('typing');
      el.classList.add('typed-done');
    }
  }
  setTimeout(tick, 400);
})();

// ASCII banner: show a buzzword as figlet art, then glitch-morph to a
// random next one. Frames are pre-rendered (banner.js) — zero deps.
(function () {
  var B = window.BANNER;
  var art = document.getElementById('banner-art');
  if (!B || !art) return;
  var wordEl = document.querySelector('.banner-word');
  var frames = B.frames.map(function (f) {
    return { w: f.w, s: f.art.join('\n') };
  });

  // Scale font so the widest line fills the available width.
  function fit() {
    art.style.fontSize = '16px';
    var natural = art.scrollWidth || 1;
    var avail = art.clientWidth || art.parentElement.clientWidth;
    var size = 16 * (avail - 1) / natural;
    size = Math.max(7, Math.min(size, 30));
    art.style.fontSize = size.toFixed(2) + 'px';
  }

  var GLYPHS = '█▓▒░#%*+=~<>/\\|'.split('');
  function esc(c) { return c === '&' ? '&amp;' : c === '<' ? '&lt;' : c === '>' ? '&gt;' : c; }
  function rnd(a) { return a[(Math.random() * a.length) | 0]; }

  var cur = 0;
  art.textContent = frames[0].s;
  if (wordEl) wordEl.textContent = frames[0].w;
  fit();
  window.addEventListener('resize', fit);

  function morph(from, to, done) {
    var n = from.length, thr = new Float32Array(n);
    for (var i = 0; i < n; i++) thr[i] = Math.random() * 0.55;
    var dur = 650, t0 = null;
    function frame(ts) {
      if (t0 === null) t0 = ts;
      var p = (ts - t0) / dur;
      if (p >= 1) { art.textContent = to; return done(); }
      var html = '';
      for (var i = 0; i < n; i++) {
        var fc = from[i], tc = to[i];
        if (fc === tc) { html += esc(tc); }
        else if (p >= thr[i]) { html += esc(tc); }
        else { html += '<span class="g">' + esc(rnd(GLYPHS)) + '</span>'; }
      }
      art.innerHTML = html;
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  function next() {
    var ni;
    do { ni = (Math.random() * frames.length) | 0; } while (ni === cur && frames.length > 1);
    if (wordEl) wordEl.textContent = frames[ni].w;
    morph(frames[cur].s, frames[ni].s, function () {
      cur = ni;
      setTimeout(next, 2600);
    });
  }
  setTimeout(next, 2400);
})();
