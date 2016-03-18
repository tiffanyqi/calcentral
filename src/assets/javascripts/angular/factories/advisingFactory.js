'use strict';

var angular = require('angular');

/**
 * Advising Factory
 */
angular.module('calcentral.factories').factory('advisingFactory', function(apiService) {
  // var url = '/dummy/json/advising_resources.json';
  var urlResources = '/api/campus_solutions/advising_resources';

  var getResources = function(options) {
    return apiService.http.request(options, urlResources);
  };

  return {
    getResources: getResources
  };
});
