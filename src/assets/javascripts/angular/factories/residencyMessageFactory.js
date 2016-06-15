'use strict';

var angular = require('angular');

/**
 * Residency Message Factory, for retrieving messages by messageNbr from Campus
 * Solutions message catalog.
 */
angular.module('calcentral.factories').factory('residencyMessageFactory', function(apiService) {
  var urlResidencyMessage = '/api/campus_solutions/residency_message';

  var getResidencyMessage = function(options) {
    return apiService.http.request(options, urlResidencyMessage + '?messageNbr=' + options.messageNbr);
  };

  return {
    getMessage: getResidencyMessage
  };
});
