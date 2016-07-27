'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Final exam schedule factory
 */
angular.module('calcentral.factories').factory('finalExamScheduleFactory', function(apiService, $route, $routeParams) {
  // var instructions_url = '/api/final_exam_schedule';
  // var enrollments_url = '/api/my/class_enrollments';
  var enrollments_url = '/dummy/json/class_enrollments.json';
  var urlAdvisingEnrollmentInstructions = '/api/advising/class_enrollments/';

  var getEnrollments = function(options) {
    // var url =  $route.current.isAdvisingStudentLookup ? urlAdvisingEnrollmentInstructions + $routeParams.uid : enrollments_url;
    return apiService.http.request(options, enrollments_url);
  };

  return {
    getEnrollments: getEnrollments
  };
});
