'use strict';

var angular = require('angular');

/**
 * Factory for the enrollment information
 */
angular.module('calcentral.factories').factory('enrollmentFactory', function(apiService) {
  // var urlAcademicPlan = '/dummy/json/academic_plan.json';
  var urlAcademicPlan = '/api/campus_solutions/academic_plan';
  // var urlEnrollmentTerm = '/dummy/json/enrollment_term.json';
  var urlEnrollmentTerm = '/api/campus_solutions/enrollment_term';
  // var urlEnrollmentTerms = '/dummy/json/enrollment_terms.json';
  var urlEnrollmentTerms = '/api/campus_solutions/enrollment_terms';

  var getAcademicPlan = function(options) {
    return apiService.http.request(options, urlAcademicPlan);
  };
  var getEnrollmentTerm = function(options) {
    return apiService.http.request(options, urlEnrollmentTerm + '?term_id=' + options.termId);
  };
  var getEnrollmentTerms = function(options) {
    return apiService.http.request(options, urlEnrollmentTerms);
  };

  return {
    getAcademicPlan: getAcademicPlan,
    getEnrollmentTerm: getEnrollmentTerm,
    getEnrollmentTerms: getEnrollmentTerms
  };
});
