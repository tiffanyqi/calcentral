'use strict';

var angular = require('angular');
var _ = require('lodash');

angular.module('calcentral.controllers').controller('ClassInfoEnrollmentController', function(rosterFactory, $scope) {
  var partitionStudentsByEnrollmentStatus = function() {
    var partitions = _.partition($scope.students, {
      'enroll_status': 'E'
    });
    $scope.enrolledStudents = partitions[0];
    $scope.waitlistedStudents = partitions[1];
  };

  var getStudents = function() {
    rosterFactory.getRoster('campus', $scope.campusCourseId).success(function(data) {
      angular.extend($scope, data);
      partitionStudentsByEnrollmentStatus();
    }).error(function(data, status) {
      angular.extend($scope, data);
      $scope.errorStatus = status;
    });
  };

  getStudents();
});
