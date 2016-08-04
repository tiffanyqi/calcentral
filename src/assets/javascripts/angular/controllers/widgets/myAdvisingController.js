'use strict';

var angular = require('angular');
// var _ = require('lodash');

/**
 * My Advising controller
 */
angular.module('calcentral.controllers').controller('MyAdvisingController', function(myAdvisingFactory, $scope) {
  var getMyAdvisorInfo = function() {
    $scope = myAdvisingFactory.getStudentAdvisingInfo;
  };
  getMyAdvisorInfo();
});
