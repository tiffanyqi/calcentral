'use strict';

var angular = require('angular');

/**
 * L & S Advising controller
 */
angular.module('calcentral.controllers').controller('LsAdvisingController', function(lsAdvisingFactory, $scope) {
  lsAdvisingFactory.getAdvisingInfo().then(function(data) {
    angular.extend($scope, data.data);

    if (data.statusCode && data.statusCode >= 400) {
      $scope.lsAdvisingError = data;
    }
  });
});
