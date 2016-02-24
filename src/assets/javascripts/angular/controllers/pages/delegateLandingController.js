'use strict';

var angular = require('angular');

/**
 * The delegate user is sent to this page after creating a new CalNet account.
 */
angular.module('calcentral.controllers').controller('DelegateLandingController', function($scope, $timeout) {
  // Give IDM a moment to create the delegate's CalNet account prior to CAS authentication prompt.
  var waitTimeMilliseconds = 5 * 1000;

  $scope.delegate = {
    isWaiting: true
  };

  var init = function() {
    $timeout(function() {
      $scope.delegate.isWaiting = false;
    }, waitTimeMilliseconds);
  };

  init();
});
