// Make the header "window" resemble the visitor's OS. Sets os-mac /
// os-win / os-linux on <html> before paint, so there is no flash.
(function () {
  var p = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || '';
  var s = (p + ' ' + (navigator.userAgent || '')).toLowerCase();
  var os = 'mac';
  if (s.indexOf('win') > -1) os = 'win';
  else if (s.indexOf('mac') > -1 || /iphone|ipad|ipod/.test(s)) os = 'mac';
  else if (s.indexOf('android') > -1 || s.indexOf('linux') > -1 || s.indexOf('x11') > -1 || s.indexOf('cros') > -1) os = 'linux';
  document.documentElement.classList.add('os-' + os);
})();
