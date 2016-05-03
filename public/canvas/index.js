(function(window, $) {
  'use strict';

  window.CALCENTRAL = 'https://calcentral.berkeley.edu';

  // Load the JavaScript customizations
  $.getScript(window.CALCENTRAL + '/canvas/canvas-customization.js');

  // Load the CSS customizations
  var css = $('<link>', {
    'rel': 'stylesheet',
    'type': 'text/css',
    'href': window.CALCENTRAL + '/canvas/canvas-customization.css'
  });
  $('head').append(css);

})(window, window.$);
