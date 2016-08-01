'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Factory for the enrollment information.
 * The second set of URLs relate to Advisors doing student lookup, NOT a view-as mode.
 */
angular.module('calcentral.factories').factory('enrollmentFactory', function(apiService, $route, $routeParams) {
  var urlEnrollmentInstructions = '/api/my/class_enrollments';
  // var urlEnrollmentInstructions = '/dummy/json/enrollment_instructions.json';
  var urlAdvisingEnrollmentInstructions = '/api/advising/class_enrollments/';
  // var urlAdvisingEnrollmentInstructions = '/dummy/json/enrollment_instructions.json';

  /**
   * Extracts update link and other information from academic planner object
   * @param {object} instructionType enrollment instruction object
   * @param {object} termId          term code for enrollment instruction object
   * @param {object} academicPlanner raw academic planner object
   */
  var setAcademicPlanner = function(instructionType, termId, academicPlanner) {
    var planner = _.get(academicPlanner, termId);
    instructionType.updatePlannerLink = _.get(planner, 'updateAcademicPlanner');
    var academicPlanners = _.get(planner, 'academicplanner');
    instructionType.academicPlanner = _.find(academicPlanners, {
      term: termId
    });
    return instructionType;
  };

  /**
   * Processes raw data feed for presentation
   * @param  {object} data enrollment instructions feed
   * @return {object} prepared enrollment instructions object
   */
  var parseEnrollmentInstructions = function(data) {
    var enrollmentInstructions = [];
    var instructionTypes = _.get(data, 'data.enrollmentTermInstructionTypes');
    var academicPlanner = _.get(data, 'data.enrollmentTermAcademicPlanner');
    var instructions = _.get(data, 'data.enrollmentTermInstructions');
    var hasHolds = _.get(data, 'data.hasHolds');
    if (!instructionTypes || !academicPlanner || !instructions) {
      return;
    }

    if (_.get(instructionTypes, 'length') > 0) {
      enrollmentInstructions = _.mapValues(instructionTypes, function(type) {
        var typeTermId = _.get(type, 'term.termId');
        angular.extend(type, instructions[typeTermId]);
        type.hasHolds = hasHolds;
        type = setAcademicPlanner(type, typeTermId, academicPlanner);
        return type;
      });
    }

    return {
      enrollmentInstructions: enrollmentInstructions
    };
  };

  var getEnrollmentInstructions = function(options) {
    var url = $route.current.isAdvisingStudentLookup ? urlAdvisingEnrollmentInstructions + $routeParams.uid : urlEnrollmentInstructions;
    return apiService.http.request(options, url).then(function(response) {
      return parseEnrollmentInstructions(response);
    });
  };

  return {
    getEnrollmentInstructions: getEnrollmentInstructions
  };
});
