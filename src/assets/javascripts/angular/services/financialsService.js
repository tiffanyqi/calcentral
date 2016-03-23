'use strict';

var angular = require('angular');

angular.module('calcentral.services').service('financialsService', function(analyticsService) {
  var printPage = function() {
    analyticsService.sendEvent('Finances', 'Print');
    window.print();
  };

  // Expose methods
  return {
    printPage: printPage
  };
});
