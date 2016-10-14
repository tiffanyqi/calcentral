'use strict';

var angular = require('angular');

angular.module('calcentral.factories').factory('degreeProgressFactory', function(apiService) {

  var url = '/api/campus_solutions/degree_progress';

  var getDegreeProgress = function(options) {
    return apiService.http.request(options, url);
  };

  return {
    getDegreeProgress: getDegreeProgress
  };
});
