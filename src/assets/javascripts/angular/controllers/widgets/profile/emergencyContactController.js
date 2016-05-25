'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Emergency Contact controller
 */
angular.module('calcentral.controllers').controller('EmergencyContactController', function(apiService, profileFactory, $scope, $q) {

  angular.extend($scope, {
    items: {
      content: []
    }
  });

  var fixFormattedAddress = function(emergencyContact) {
    emergencyContact.formattedAddress = emergencyContact.formattedAddress || '';

    if (emergencyContact.formattedAddress) {
      emergencyContact.formattedAddress = apiService.profile.fixFormattedAddress(emergencyContact.formattedAddress);
    }
  };

  var parseEmergencyContacts = function(data) {
    var emergencyContacts = _.get(data, 'data.feed.students.student.emergencyContacts.emergencyContact') || [];

    _(emergencyContacts).each(function(emergencyContact) {
      fixFormattedAddress(emergencyContact);
    });

    $scope.items.content = emergencyContacts;
  };

  var getEmergencyContacts = profileFactory.getEmergencyContacts().then(parseEmergencyContacts);

  var loadInformation = function() {
    $q.all(getEmergencyContacts).then(function() {
      $scope.isLoading = false;
    });
  };

  loadInformation();
});
