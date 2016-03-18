'use strict';

var angular = require('angular');

/**
 * Ferpa Restrictions URL Factory
 */
angular.module('calcentral.factories').factory('ferpaDeeplinkFactory', function(apiService) {
  var url = '/api/campus_solutions/ferpa_deeplink';

  var getUrl = function(options) {
    return apiService.http.request(options, url);
  };

  return {
    getUrl: getUrl
  };
});
