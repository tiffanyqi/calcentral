'use strict';

var angular = require('angular');

/**
 * Advisor student overview controller
 */
angular.module('calcentral.controllers').controller('AdvisorStudentOverviewController', function(apiService, advisorStudentOverviewFactory, $routeParams, $scope) {
  $scope.student = {
    isLoading: true
  };

  var loadInformation = function() {
    advisorStudentOverviewFactory.getPerson({
      uid: $routeParams.uid
    }).then(function(data) {
      $scope.student.attributes = data.data;
      apiService.util.setTitle($scope.student.attributes.defaultName);
      $scope.student.isLoading = false;
    });
  };

  $scope.$on('calcentral.api.user.isAuthenticated', function(event, isAuthenticated) {
    if (isAuthenticated) {
      loadInformation();
    }
  });
});
