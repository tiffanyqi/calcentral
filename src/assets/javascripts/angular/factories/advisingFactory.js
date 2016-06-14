'use strict';

var angular = require('angular');

/**
 * Advising Factory
 */
angular.module('calcentral.factories').factory('advisingFactory', function(apiService) {
  var urlResources = '/api/campus_solutions/advising_resources';
  // var urlResources = '/dummy/json/advising_resources.json';
  var urlAdvisingStudent = '/api/advising/student/';
  // var urlAdvisingStudent = '/dummy/json/advising_student_academics.json';
  var urlAdvisingAcademics = '/api/advising/academics/';
  // var urlAdvisingAcademics = '/dummy/json/advising_student_academics.json';
  var urlAdvisingResources = '/api/advising/resources/';
  // var urlAdvisingResources = '/dummy/json/advising_resources.json';
  var urlAdvisingRegistrations = '/api/advising/registrations/';
  var urlAdvisingBlocks = '/api/advising/blocks/';

  var getResources = function(options) {
    return apiService.http.request(options, urlResources);
  };

  var getAdvisingResources = function(options) {
    return apiService.http.request(options, urlAdvisingResources + options.uid);
  };

  var getStudent = function(options) {
    return apiService.http.request(options, urlAdvisingStudent + options.uid);
  };

  var getStudentBlocks = function(options) {
    return apiService.http.request(options, urlAdvisingBlocks + options.uid);
  };

  var getStudentAcademics = function(options) {
    return apiService.http.request(options, urlAdvisingAcademics + options.uid);
  };

  var getStudentRegistrations = function(options) {
    return apiService.http.request(options, urlAdvisingRegistrations + options.uid);
  };

  return {
    getAdvisingResources: getAdvisingResources,
    getResources: getResources,
    getStudent: getStudent,
    getStudentBlocks: getStudentBlocks,
    getStudentAcademics: getStudentAcademics,
    getStudentRegistrations: getStudentRegistrations
  };
});
