'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Final exam schedule controller
 */
angular.module('calcentral.controllers').controller('FinalExamScheduleController', function(apiService, finalExamScheduleFactory, enrollmentFactory, $scope, $route) {

  // classes that are not calculated by start time
  var chem = ['CHEM 1A', 'CHEM 1B']; // for slot 3, Monday, 12/12/16, 3-6pm
  var econ = ['ECON 1', 'ECON 100B']; // for slot 6, Tuesday, 12/13/16, 11:30-2:30pm
  var forlang = ['']; // for slot 10, Wednesday, 12/14/16, 11:30-2:30pm

  // create empty hashes to prepare for methods
  var courses = { };
  var schedule = { };

  /*
   * Takes the enrollment json and adds the course and start time to the courses hash
   */
  var parseEnrollmentData = function(data) {
    // enrollment data
    var enrollmentInstructions = _.get(data, 'enrollmentInstructions');
    var sections = ['enrolledClasses', 'waitlistedClasses'];

    // iterate through enrolled and waitlisted classes
    for (var i = 0; i < sections.length; i++) {
      var classObject = enrollmentInstructions[0][sections[i]]; // fix 0 later

      // iterate through each class
      for (var c = 0; c < classObject.length; c++) {
        var course = classObject[c];

        // add course and time to the course hash if it has units
        if (course['units'] != 0) {
          var courseCode = course['subjectCatalog'];
          var time = course['when'];
          courses[courseCode] = time;
        }
      }
    }
  };

  /*
   * Assigns exam schedule to each class from the final exam data
   */
  var assignExams = function(data) {
    // exam data
    var examSchedule = _.get(data, 'data');

    // iterate through each course in enrollments
    for (var course in courses) {

      var courseTime = courses[course].split(' ');

      // days like MWF is the first, take the first letter for the key
      var day = courseTime[0].split(/(?=[A-Z])/)[0];

      // times like 5:00P-6:29P is the first, take the first as its the start
      var startTime = courseTime[1].split('-')[0];
      // transform start time so that it's searchable in the exam data
      if (startTime.substr(startTime.length - 1) === "P") {
        startTime = startTime.replace("P", "pm");
      } else if (startTime.substr(startTime.length - 1) === "A") {
        startTime = startTime.replace("A", "am");
      } else if (startTime[0] < 8) {
        startTime += "pm";
      } else {
        startTime += "am";
      }

      var examKey = day + "-" + startTime;
      schedule[course] = examSchedule[examKey];
      
    }
    $scope.schedule = schedule;
  }

  /**
   * Load the enrollment data and fire off subsequent events
   */
  var loadEnrollmentData = function() {
    enrollmentFactory.getEnrollmentInstructions().then(parseEnrollmentData);
    finalExamScheduleFactory.getSchedule().then(assignExams);
  };

  loadEnrollmentData();
});
