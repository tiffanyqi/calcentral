'use strict';

var angular = require('angular');

angular.module('calcentral.controllers').controller('BillingDetailsController', function(apiService, financesFactory, $scope) {
  apiService.util.setTitle('My Finances');
  $scope.billingTerm = {
    // We want to show this text only during the transition period, so we'll remove this for GL7.
    fallText: null,
    isLoading: true
  };

  var getCurrentTerm = function(data) {
    // Toggles the "Fall 2016" text needed for transition period, remove this for GL7.
    if (data.data.feed.summary.currentTerm === 'Summer 2016' || data.data.feed.summary.currentTerm === 'Fall 2016') {
      $scope.billingTerm.fallText = 'Fall 2016';
    }
  };

  var loadBillingInfo = function() {
    financesFactory.getCsFinances()
      .then(getCurrentTerm)
      .then(function() {
        $scope.billingTerm.isLoading = false;
      });
  };

  loadBillingInfo();
});
