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
      $scope.profile = _.get(data, 'data.attributes');
      $scope.profile.uid = $routeParams.uid;
      $scope.profile.addresses = apiService.profile.fixFormattedAddresses(_.get(data, 'data.contacts.feed.student.addresses'));
      $scope.profile.phones = _.get(data, 'data.contacts.feed.student.phones');
      $scope.profile.emails = _.get(data, 'data.contacts.feed.student.emails');
      apiService.util.setTitle($scope.profile.defaultName);
      // Get links to advising resources
      advisingFactory.getAdvisingResources({
        uid: $routeParams.uid
      }).then(function(data) {
        $scope.ucAdvisingResources = _.get(data, 'data.feed.ucAdvisingResources');
        $scope.profile.isLoading = false;
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
