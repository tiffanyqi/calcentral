'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Final exam schedule controller
 */
angular.module('calcentral.controllers').controller('FinalExamScheduleController', function(apiService, $scope) {
  var url = '/api/final_exam_schedule';
  $scope.schedule = _.get_feed
});
