'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Transfer Credit Controller
 */
angular.module('calcentral.controllers').controller('TransferCreditController', function(apiService, $scope, transferCreditFactory) {
  var parseTransferCredit = function(data) {
    var transferCredit = _.get(data, 'data.feed.transferCredit');
    if (transferCredit) {
      $scope.transferCredit.hasCredit = !_.isEmpty(transferCredit.creditTypes);
      angular.extend($scope.transferCredit, transferCredit);
    }
    $scope.transferCredit.isLoading = false;
  };

  var loadTransferCredit = function() {
    $scope.transferCredit = {
      isLoading: true
    };
    transferCreditFactory.getTransferCredit().then(parseTransferCredit);
  };

  loadTransferCredit();
});
