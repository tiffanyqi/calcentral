'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Final exam schedule controller
 */
angular.module('calcentral.controllers').controller('FinalExamScheduleController', function(apiService, finalExamScheduleFactory, enrollmentFactory, $scope) {

  // classes that are not calculated by start time
  var chem = ['CHEM 1A', 'CHEM 1B']; // for slot 3
  var econ = ['ECON 1', 'ECON 100B']; // for slot 6
  var forlang = ['']; // for slot 10

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

        // add course and time to the course hash if it is a lecture
        if (course.ssrComponent === 'LEC') {
          var courseCode = course.subjectCatalog;
          var time = course.when;
          if (i === 0) {
            courses[courseCode] = [time, false]; // false means class is enrolled
          } else {
            courses[courseCode] = [time, true];
          }
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

      var courseArray = courses[course];
      var courseTime = courseArray[0].split(' ');
      var courseWaitlisted = courseArray[1];

      // days like MWF is the first, take the first letter for the key
      var day = courseTime[0].split(/(?=[A-Z])/)[0];

      // times like 5:00P-6:29P is the first, take the first as its the start
      var startTime = courseTime[1].split('-')[0];
      // transform start time so that it's searchable in the exam data
      if (startTime.substr(startTime.length - 1) === 'P') {
        startTime = startTime.replace('P', 'pm');
      } else if (startTime.substr(startTime.length - 1) === 'A') {
        startTime = startTime.replace('A', 'am');
      } else if (startTime[0] < 8) {
        startTime += 'pm';
      } else {
        startTime += 'am';
      }
      var examKey = day + '-' + startTime;

      // check to see if course is chem, econ, or forlang
      if (chem.includes(course)) {
        schedule[course] = ['Mon Dec 12', '3-6pm'];
      } else if (econ.includes(course)) {
        schedule[course] = ['Tue Dec 13', '11:30-2:30pm'];
      } else if (forlang.includes(course)) {
        schedule[course] = ['Wed Dec 14', '11:30-2:30pm'];
      } else {
        var exam = examSchedule[examKey].split(',');
        var examDate = exam[0].substr(0, 3) + ' ' + exam[1];
        var examTime = exam[2];

        schedule[course] = [examDate, examTime, courseWaitlisted];
      }
    }
    $scope.schedule = schedule;
  };

  /**
   * Load the enrollment data and fire off subsequent events
   */
  var loadEnrollmentData = function() {
    enrollmentFactory.getEnrollmentInstructions().then(parseEnrollmentData);
    finalExamScheduleFactory.getSchedule().then(assignExams);
  };

  loadEnrollmentData();
});
