'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Final exam schedule controller
 */
angular.module('calcentral.controllers').controller('FinalExamScheduleController', function(apiService, finalExamScheduleFactory, emrollmentFactory, $scope, $route) {

  // classes that are not calculated by start time
  var chem = ['CHEM 1A', 'CHEM 1B']; // for slot 3, Monday, 12/12/16, 3-6pm
  var econ = ['ECON 1', 'ECON 100B']; // for slot 6, Tuesday, 12/13/16, 11:30-2:30pm
  var forlang = ['']; // for slot 10, Wednesday, 12/14/16, 11:30-2:30pm

  // takes the enrollment json and converts into classes for display
  var parseEnrollmentData = function(data) {
    console.log(data);
    var schedule = { };
    var enrollmentInstructions = _.get(data, 'data.enrollmentTermInstructions');
    var sections = ['enrolledClasses', 'waitlistedClasses'];
    for (var i = 0; i < sections.length; i++) {
      var classObject = enrollmentInstructions['2168'][sections[i]];
      for (var c = 0; c < classObject.length; c++) {
        var course = classObject[c];
        // this signifies that there may be a final exam associated with it
        if (course['units'] != 0) {
          var courseCode = course['subjectCatalog'];
          var startTime = course['when'];
          schedule[courseCode] = startTime;
        }
      }
    }
    $scope.schedule = schedule;
  };

  /**
   * Load the enrollment data and fire off subsequent events
   */
  var loadEnrollmentData = function() {
    finalExamScheduleFactory.getEnrollments().then(parseEnrollmentData);
  };

  loadEnrollmentData();
});
