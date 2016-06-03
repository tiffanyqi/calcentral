/* jshint camelcase: false */
'use strict';

var angular = require('angular');

angular.module('calcentral.directives').directive('ccAcademicsClassInfoEnrollmentDirective', function() {
  return {
    scope: true,
    link: function(scope, elem, attrs) {
      scope.studentInSectionFilter = function(student) {
        return (!scope.selectedSection || student.section_ccns.indexOf(scope.selectedSection.ccn) !== -1);
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
