'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Transfer Credit Controller
 */
angular.module('calcentral.controllers').controller('TransferCreditController', function(apiService, $scope, transferCreditFactory) {

  // Temporary MVP functionality, using cumulativeUnits from the academics feed.
  /*
  var parseCumulativeUnits = function(data) {
    var cumulativeUnits = _.get(data, 'data.collegeAndLevel.cumulativeUnits');
    _.some(cumulativeUnits, function(entry) {
      if (_.get(entry, 'type.code') === 'Total') {
        $scope.transferCredit.hasCredit = entry.unitsTransferAccepted > 0 || entry.unitsTest > 0 || entry.unitsOther > 0;
        $scope.transferCredit.cumulativeUnits = entry;
        return true;
      }
    });
    $scope.transferCredit.isLoading = false;
  };
  */

  // TransferCredit functionality hidden while CS data API is not complete.
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
      isLoading: true,
      cumulativeUnits: ''
    };
    // cumulativeUnits removed from MyAcademics::CollegeAndLevel as requirement in SISRP-22377
    // academicsFactory.getAcademics().then(parseCumulativeUnits);

    transferCreditFactory.getTransferCredit().then(parseTransferCredit);
  };

  loadTransferCredit();
});
