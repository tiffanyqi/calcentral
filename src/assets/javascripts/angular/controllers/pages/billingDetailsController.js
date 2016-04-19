'use strict';

var angular = require('angular');

angular.module('calcentral.controllers').controller('BillingDetailsController', function(apiService, financesFactory, $scope) {
  apiService.util.setTitle('My Finances');
  $scope.billingTerm = {
    currentTerm: '',
    isLoading: true
  };

  var getCurrentTerm = function(data) {
    $scope.billingTerm.currentTerm = data.data.feed.summary.currentTerm;
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
