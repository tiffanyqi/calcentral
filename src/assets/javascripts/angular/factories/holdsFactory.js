'use strict';

var angular = require('angular');

/**
 * Holds Factory
 */
angular.module('calcentral.factories').factory('holdsFactory', function(apiService) {
  // var url = '/dummy/json/holds_empty.json';
  // var url = '/dummy/json/holds_present.json';
  var url = '/api/campus_solutions/holds';

  var getHolds = function(options) {
    return apiService.http.request(options, url);
  };

  return {
    getHolds: getHolds
  };
});
