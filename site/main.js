// Progressive enhancement only: the page is complete without this file.
// With "prefers-reduced-motion: reduce" nothing here animates.
(function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Typewriter reveal of the terminal's output line. The full text is in the DOM already.
  var el = document.querySelector('[data-typed]');
  if (el && !reduce) {
    var text = el.getAttribute('data-typed');
    var i = 0;
    el.textContent = '';
    el.classList.add('typing');
    (function tick() {
      el.textContent = text.slice(0, i);
      if (i++ < text.length) setTimeout(tick, 35 + Math.random() * 45);
      else el.classList.remove('typing');
    })();
  }

  // ASCII banner: a buzzword as figlet art, glitch-morphing to a random next one.
  // Frames are pre-rendered in banner.js and all have the same size.
  var B = window.BANNER;
  var art = document.getElementById('banner-art');
  if (!B || !art) return;
  var frames = B.frames.map(function (f) { return f.art.join('\n'); });
  var GLYPHS = '█▓▒░#%*+=~<>/\\|';
  var cur = 0;
  art.textContent = frames[0];
  if (reduce) return;

  function esc(c) { return c === '&' ? '&amp;' : c === '<' ? '&lt;' : c === '>' ? '&gt;' : c; }

  function morph(from, to, done) {
    var n = from.length, thr = [], t0 = null;
    for (var k = 0; k < n; k++) thr.push(Math.random() * 0.55);
    function frame(ts) {
      if (t0 === null) t0 = ts;
      var p = (ts - t0) / 650;
      if (p >= 1) { art.textContent = to; return done(); }
      var html = '';
      for (var j = 0; j < n; j++) {
        var tc = to[j];
        if (from[j] === tc || p >= thr[j]) html += esc(tc);
        else html += '<span class="g">' + esc(GLYPHS[(Math.random() * GLYPHS.length) | 0]) + '</span>';
      }
      art.innerHTML = html;
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  function next() {
    var ni;
    do { ni = (Math.random() * frames.length) | 0; } while (ni === cur && frames.length > 1);
    morph(frames[cur], frames[ni], function () {
      cur = ni;
      setTimeout(next, 2800);
    });
  }
  setTimeout(next, 2600);
})();
