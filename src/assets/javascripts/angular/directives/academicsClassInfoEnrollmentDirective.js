/* jshint camelcase: false */
'use strict';

var _ = require('lodash');
var angular = require('angular');

angular.module('calcentral.directives').directive('ccAcademicsClassInfoEnrollmentDirective', function(rosterService) {
  return {
    scope: true,
    link: function(scope, elem, attrs) {
      scope.bmailLink = rosterService.bmailLink;

      scope.toggleAddresses = function(boolValue) {
        scope.showAddresses = boolValue;
      };

      /*
       * Returns true if student is in the selected section
       * @returns {Boolean}
       */
      var isStudentInSection = function(student) {
        return (student.section_ccns.indexOf(scope.selectedSection.ccn) !== -1);
      };

      /*
       * Returns students in selected section
       * @returns {Array}
       */
      var studentsInSelectedSection = function() {
        if (!scope.selectedSection) {
          return scope.students;
        }
        return _.filter(scope.students, isStudentInSection);
      };

      /*
       * Returns true if no section selected, or if student is in the selected section
       * @param {object} student - A student object
       * @returns {Boolean}
       */
      scope.studentInSectionFilter = function(student) {
        return (!scope.selectedSection || isStudentInSection(student));
      };

      /*
       * Returns list of student email addresses for the currently selected section
       * @returns {string}
       */
      scope.studentsInSectionEmailList = function() {
        var students = studentsInSelectedSection();
        if (students) {
          return _.map(students, function(student) {
            return student.email;
          }).join(',');
        } else {
          return '';
        }
      };

      scope.$watch(
        function() {
          return scope.$eval(attrs.students);
        },
        function(newValue) {
          scope.students = newValue;
          var studentCount = Array.isArray(newValue) ? newValue.length : 0;
          scope.seatsAvailable = scope.seatsLimit - studentCount;
        }
      );

      scope.toggleAddresses(false);
      scope.seatsLimit = scope.$eval(attrs.seatsLimit);
      scope.showPosition = scope.$eval(attrs.showPosition);
      scope.studentRole = (attrs.title === 'Wait List') ? 'waitlisted' : 'enrolled';
      scope.tableSort = {
        'column': (scope.showPosition ? 'waitlist_position' : 'last_name'),
        'reverse': false
      };
      scope.title = attrs.title;
    },
    templateUrl: 'directives/academics_class_info_enrollment.html'
  };
});
