'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Advisor student overview controller
 */
angular.module('calcentral.controllers').controller('AdvisingStudentController', function(advisingFactory, apiService, $routeParams, $scope) {
  $scope.academics = {
    isLoading: true,
    excludeLinksToRegistrar: true
  };

  var loadProfile = function() {
    advisingFactory.getStudent({
      uid: $routeParams.uid
    }).then(function(data) {
      $scope.student = _.get(data, 'data.attributes');
      $scope.student.uid = $routeParams.uid;
      $scope.student.addresses = apiService.profile.fixFormattedAddresses(_.get(data, 'data.contacts.feed.student.addresses'));
      $scope.student.phones = _.get(data, 'data.contacts.feed.student.phones');
      $scope.student.emails = _.get(data, 'data.contacts.feed.student.emails');
      // 'student.fullName' is expected by shared code (e.g., photo unavailable widget)
      $scope.student.fullName = $scope.student.defaultName;
      apiService.util.setTitle($scope.student.defaultName);
      // Get links to advising resources
      advisingFactory.getAdvisingResources({
        uid: $routeParams.uid
      }).then(function(data) {
        $scope.ucAdvisingResources = _.get(data, 'data.feed.ucAdvisingResources');
        $scope.student.isLoading = false;
      });
    });
  };

  var loadAcademics = function() {
    advisingFactory.getStudentAcademics({
      uid: $routeParams.uid
    }).then(function(data) {
      $scope.academics = _.get(data, 'data.academics');
      $scope.collegeAndLevel = $scope.academics.collegeAndLevel;
      $scope.examSchedule = _.get(data, 'data.examSchedule');
      // The university_requirements widget is also used on My Academics.
      $scope.academics.universityRequirements = $scope.academics.requirements;
      $scope.academics.isLoading = false;
    });
  };

  $scope.$on('calcentral.api.user.isAuthenticated', function(event, isAuthenticated) {
    if (isAuthenticated) {
      loadProfile();
      loadAcademics();
    }
  });
});
