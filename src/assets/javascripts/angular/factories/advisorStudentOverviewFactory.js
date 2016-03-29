'use strict';

var angular = require('angular');

/**
 * Advisor student overview factory
 */
angular.module('calcentral.factories').factory('advisorStudentOverviewFactory', function($http) {
  var getStudent = function(options) {
    return $http.get('/api/student/' + options.uid);
  };

  return {
    getStudent: getStudent
  };
});
