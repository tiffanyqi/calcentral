'use strict';

var angular = require('angular');

/**
 * Advisor student overview controller
 */
angular.module('calcentral.controllers').controller('AdvisorStudentOverviewController', function(apiService, advisorStudentOverviewFactory, $routeParams, $scope) {
  $scope.academics = {
    isLoading: true,
    excludeLinksToRegistrar: true
  };

  var loadInformation = function() {
    advisorStudentOverviewFactory.getStudent({
      uid: $routeParams.uid
    }).then(function(data) {
      $scope.student = data.data;
      apiService.util.setTitle($scope.student.attributes.defaultName);
      // The university_requirements widget is also used on My Academics.
      $scope.academics.universityRequirements = $scope.student.academics.requirements;
      $scope.academics.isLoading = false;
    });
  };

  $scope.$on('calcentral.api.user.isAuthenticated', function(event, isAuthenticated) {
    if (isAuthenticated) {
      loadInformation();
    }
  });
});
