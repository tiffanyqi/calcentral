'use strict';

var angular = require('angular');
var _ = require('lodash');

angular.module('calcentral.controllers').controller('BillingController', function(apiService, financesFactory, $scope) {
  $scope.billing = {
    data: {},
    isLoading: true,
    sort: {
      column: 'itemEffectiveDate',
      descending: true
    }
  };
  $scope.activityIncrement = 50;
  $scope.activityLimit = 100;

  var parseAmounts = function(value) {
    if (_.isNumber(value)) {
      return value.toFixed(2);
    }
    return value;
  };

  var parseBillingInfo = function(data) {
    var billing = _.get(data, 'data.feed.ucSfActivity');

    billing.summary = _.mapValues(billing.summary, function(value) {
      value = parseAmounts(value);
      return value;
    });

    billing.activity = _.map(billing.activity, function(object) {
      var billingItem = _.mapValues(object, function(value) {
        value = parseAmounts(value);
        return value;
      });
      return billingItem;
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

  $scope.printPage = function() {
    apiService.financials.printPage();
  };

  loadBillingInfo();
});
