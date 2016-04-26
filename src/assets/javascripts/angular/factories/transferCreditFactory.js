'use strict';

var angular = require('angular');

angular.module('calcentral.factories').factory('transferCreditFactory', function(apiService) {
  var urlTransferCredit = '/dummy/json/transfer_credit.json';
  // var urlTransferCredit = '/api/campus_solutions/transfer_credit';

  var getTransferCredit = function(options) {
    return apiService.http.request(options, urlTransferCredit);
  };

  return {
    getTransferCredit: getTransferCredit
  };
});
