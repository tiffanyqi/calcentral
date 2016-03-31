'use strict';

var angular = require('angular');

/**
 * Advisor student overview factory
 */
angular.module('calcentral.factories').factory('advisorStudentOverviewFactory', function($http) {
  var getAcademics = function(options) {
    return $http.get('/api/advising/academics/' + options.uid);
  };

  return {
    getAcademics: getAcademics
  };
});
