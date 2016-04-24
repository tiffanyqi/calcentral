'use strict';

var angular = require('angular');

/**
 * Statement Of Legal Residency URL Factory
 */
angular.module('calcentral.factories').factory('slrDeeplinkFactory', function(apiService) {
  var url = '/api/campus_solutions/slr_deeplink';

  var getUrl = function(options) {
    return apiService.http.request(options, url);
  };

  return {
    getUrl: getUrl
  };
});
