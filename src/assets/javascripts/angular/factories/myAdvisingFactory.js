'use strict';

var angular = require('angular');

/**
 * Serves data to Students about Advising Relationships, Action Items, and Appointments
 */
angular.module('calcentral.factories').factory('myAdvisingFactory', function($http) {
  var getStudentAdvisingInfo = function() {
    var urlStudentAdvisingInfo = '/api/advising/my_advising';
    // var urlStudentAdvisingInfo = '/dummy/json/my_advising.json';
    return $http.get(urlStudentAdvisingInfo);
  };

  return {
    getStudentAdvisingInfo: getStudentAdvisingInfo
  };
});
