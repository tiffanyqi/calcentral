/* jshint camelcase: false */
'use strict';

var angular = require('angular');

angular.module('calcentral.services').service('adminService', function(adminFactory, apiService) {
  var actAs = function(user) {
    var isAdvisorOnly = apiService.user.profile.roles.advisor &&
      !apiService.user.profile.isSuperuser &&
      !apiService.user.profile.isViewer;
    var actAs = isAdvisorOnly ? adminFactory.advisorActAs : adminFactory.actAs;
    return actAs({
      uid: user.ldap_uid
    }).success(apiService.util.redirectToHome);
  };

  return {
    actAs: actAs
  };
});
