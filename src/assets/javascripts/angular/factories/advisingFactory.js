'use strict';

var angular = require('angular');

/**
 * Advising Factory
 */
angular.module('calcentral.factories').factory('advisingFactory', function(apiService) {
  // var url = '/dummy/json/advising_resources.json';
  var urlResources = '/api/campus_solutions/advising_resources';
  // var url = '/dummy/json/advising_student_academics.json';
  var urlAdvisingStudent = '/api/advising/student/';
  // var url = '/dummy/json/advising_student_academics.json';
  var urlAdvisingAcademics = '/api/advising/academics/';
  // var url = '/dummy/json/advising_resources.json';
  var urlAdvisingResources = '/api/advising/resources/';

  var getResources = function(options) {
    return apiService.http.request(options, urlResources);
  };

  var getAdvisingResources = function(options) {
    return apiService.http.request(options, urlAdvisingResources + options.uid);
  };

  var getStudent = function(options) {
    return apiService.http.request(options, urlAdvisingStudent + options.uid);
  };

  var getStudentAcademics = function(options) {
    return apiService.http.request(options, urlAdvisingAcademics + options.uid);
  };

  return {
    getAdvisingResources: getAdvisingResources,
    getResources: getResources,
    getStudent: getStudent,
    getStudentAcademics: getStudentAcademics
  };
});
