'use strict';

var angular = require('angular');

/**
 * Dashboard controller
 */
angular.module('calcentral.controllers').controller('DashboardController', function(apiService, userService) {
  var init = function() {
    if (apiService.user.profile.hasDashboardTab) {
      apiService.util.setTitle('Dashboard');
    } else {
      userService.redirectToHome();
    }
  };

  init();
});
