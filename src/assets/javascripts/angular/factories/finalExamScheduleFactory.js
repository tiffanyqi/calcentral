'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Final exam schedule factory
 */
angular.module('calcentral.factories').factory('finalExamScheduleFactory', function(apiService, $route, $routeParams) {
  var url = '/api/final_exam_schedule';

  var getSchedule = function(options) {
    return apiService.http.request(options, url);
  };

  return {
    getSchedule: getSchedule
  };
});
