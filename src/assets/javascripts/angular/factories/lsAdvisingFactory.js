'use strict';

var angular = require('angular');

/**
 * L & S Advising Factory
 */
angular.module('calcentral.factories').factory('lsAdvisingFactory', function(apiService) {
  var advisingInfoUrl = '/api/my/advising';
  // var advisingInfoUrl = '/dummy/json/lsadvising2.json';

  var getAdvisingInfo = function(options) {
    return apiService.http.request(options, advisingInfoUrl);
  };

  return {
    getAdvisingInfo: getAdvisingInfo
  };
});
