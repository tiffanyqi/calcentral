'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Academic Profile controller
 */
angular.module('calcentral.controllers').controller('AcademicProfileController', function($scope) {
  $scope.profilePictureLoading = true;

  /**
   * Returns last expected graduation term name when student is not an undergrad
   * @param  {Object} collegeAndLevel College And Level node of My Academics feed
   * @return {String}                 Name for graduation term
   */
  $scope.expectedGradTerm = function(collegeAndLevel) {
    var careers = _.get(collegeAndLevel, 'careers');
    if (isNotGradOrLawStudent(careers) && collegeAndLevel.lastExpectedGraduationTerm) {
      return collegeAndLevel.lastExpectedGraduationTerm;
    }
    return '';
  };

  /**
   * Returns true if student is not a Graduate or Law student
   */
  var isNotGradOrLawStudent = function(careers) {
    if (_.get(careers, 'length')) {
      var matches = _.intersection(careers, ['Graduate', 'Law']);
      return matches.length === 0;
    }
    return false;
  };
});
