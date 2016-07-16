'use strict';

var angular = require('angular');

/**
 * Factory for the enrollment verification messages.
 */
angular.module('calcentral.factories').factory('enrollmentVerificationFactory', function(apiService) {
  // var url = '/dummy/json/enrollment_verification_messages.json'
  var url = '/api/campus_solutions/enrollment_verification_messages';

  var getEnrollmentVerificationMessages = function(options) {
    return apiService.http.request(options, url);
  };

  return {
    getEnrollmentVerificationMessages: getEnrollmentVerificationMessages
  };
});
