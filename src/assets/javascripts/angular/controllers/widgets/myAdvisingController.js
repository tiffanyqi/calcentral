'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * My Advising controller
 */
angular.module('calcentral.controllers').controller('MyAdvisingController', function(myAdvisingFactory, $scope) {
  $scope.myAdvising = {
    isLoading: true
  };

  var loadAdvisingInfo = function() {
    myAdvisingFactory.getStudentAdvisingInfo().then(function(data) {
      angular.extend($scope.myAdvising, _.get(data, 'data.feed'));
      $scope.myAdvising.errored = _.get(data, 'data.errored');
      $scope.myAdvising.isLoading = false;
    });
  };

  loadAdvisingInfo();
});
