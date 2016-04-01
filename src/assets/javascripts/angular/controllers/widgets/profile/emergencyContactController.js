'use strict';

var angular = require('angular');

/**
 * Emergency Contact controller
 */
angular.module('calcentral.controllers').controller('EmergencyContactController', function(apiService, profileFactory, $scope, $q) {
  var parsePerson = function(data) {
    apiService.profile.parseSection($scope, data, 'emergencyContacts');
    $scope.items.content = apiService.profile.fixFormattedAddresses($scope.items.content);
  };

  var getPerson = profileFactory.getPerson().then(parsePerson);

  var loadInformation = function() {
    $q.all(getPerson).then(function() {
      $scope.isLoading = false;
    });
  };

  loadInformation();
});
