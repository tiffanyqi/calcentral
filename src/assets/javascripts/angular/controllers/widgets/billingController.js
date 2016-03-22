'use strict';

var angular = require('angular');
var _ = require('lodash');

angular.module('calcentral.controllers').controller('BillingController', function(apiService, financesFactory, $scope) {
  $scope.billing = {
    data: {},
    isLoading: true
  };

  var parseAmount = function(value) {
    if (_.isNumber(value)) {
      return value.toFixed(2);
    }
  };

  var parseBillingInfo = function(data) {
    var billing = _.get(data, 'data.feed.ucSfActivity');

    billing.summary = _.mapValues(billing.summary, function(value) {
      value = parseAmount(value);
      return value;
    });

    $scope.billing.data = billing;
  };

  var loadBillingInfo = function() {
    financesFactory.getCsFinances()
      .then(parseBillingInfo)
      .then(function() {
        $scope.billing.isLoading = false;
      });
  };

  loadBillingInfo();
});
