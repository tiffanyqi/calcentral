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

  var loadAdvisingResources = function() {
    advisingFactory.getAdvisingResources({
      uid: $routeParams.uid
    }).then(function(data) {
      $scope.ucAdvisingResources = _.get(data, 'data.feed.ucAdvisingResources');
    });
  };

  var loadStudent = function() {
    advisingFactory.getStudent({
      uid: $routeParams.uid
    }).then(function(data) {
      $scope.student = _.get(data, 'data');
      apiService.util.setTitle($scope.student.attributes.defaultName);
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
      loadStudent();
      loadAcademics();
      loadAdvisingResources();
    }
  });
});
