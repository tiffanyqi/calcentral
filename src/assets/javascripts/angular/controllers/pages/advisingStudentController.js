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
  $scope.student = {
    isLoading: true
  };

  var defaultErrorDescription = function(status) {
    if (status === 403) {
      return 'You are not authorized to view this user\'s data.';
    } else {
      return 'Sorry, there was a problem fetching this user\'s data. Contact CalCentral support if the error persists.';
    }
  };

  var errorReport = function(status, errorDescription) {
    return {
      summary: status === 403 ? 'Access Denied' : 'Unexpected Error',
      description: errorDescription || defaultErrorDescription(status)
    };
  };

  var loadProfile = function() {
    advisingFactory.getStudent({
      uid: $routeParams.uid
    }).success(function(data) {
      angular.extend($scope.student, _.get(data, 'attributes'));
      $scope.student.uid = $routeParams.uid;
      $scope.student.addresses = apiService.profile.fixFormattedAddresses(_.get(data, 'contacts.feed.student.addresses'));
      $scope.student.phones = _.get(data, 'contacts.feed.student.phones');
      $scope.student.emails = _.get(data, 'contacts.feed.student.emails');
      // 'student.fullName' is expected by shared code (e.g., photo unavailable widget)
      $scope.student.fullName = $scope.student.defaultName;
      apiService.util.setTitle($scope.student.defaultName);
      // Get links to advising resources
      advisingFactory.getAdvisingResources({
        uid: $routeParams.uid
      }).then(function(data) {
        $scope.ucAdvisingResources = _.get(data, 'data.feed.ucAdvisingResources');
      });
    }).error(function(data, status) {
      $scope.student.error = errorReport(status, data.error);
    }).finally(function() {
      $scope.student.isLoading = false;
    });
  };

  var loadAcademics = function() {
    advisingFactory.getStudentAcademics({
      uid: $routeParams.uid
    }).success(function(data) {
      angular.extend($scope.academics, _.get(data, 'academics'));
      $scope.collegeAndLevel = $scope.academics.collegeAndLevel;
      $scope.examSchedule = $scope.academics.examSchedule;
      // The university_requirements widget is also used on My Academics.
      $scope.academics.universityRequirements = $scope.academics.requirements;
    }).error(function(data, status) {
      $scope.academics.error = errorReport(status, data.error);
    }).finally(function() {
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
