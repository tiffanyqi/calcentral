'use strict';

var angular = require('angular');

/**
 * Finances Links Factory
 */
angular.module('calcentral.factories').factory('financesLinksFactory', function(apiService) {
  var urlEftEnrollment = '/api/my/eft_enrollment';
  var urlFppEnrollment = '/api/campus_solutions/fpp_enrollment';

  var getEftEnrollment = function(options) {
    return apiService.http.request(options, urlEftEnrollment);
  };

  var getFppEnrollment = function(options) {
    return apiService.http.request(options, urlFppEnrollment);
  };

  return {
    getEftEnrollment: getEftEnrollment,
    getFppEnrollment: getFppEnrollment
  };
});
