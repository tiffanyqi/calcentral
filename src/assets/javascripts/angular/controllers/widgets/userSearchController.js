'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Search and view-as users.
 */
angular.module('calcentral.controllers').controller('UserSearchController', function(adminFactory, apiService, $scope) {
  $scope.userSearch = {
    title: 'View as',
    tabs: {
      search: {
        label: 'Search',
        inProgress: false,
        users: null
      },
      saved: {
        label: 'Saved',
        isLoading: true,
        users: null
      },
      recent: {
        label: 'Recent',
        isLoading: true,
        users: null
      }
    }
  };

  var reportError = function(tab, status, errorDescription) {
    tab.error = {
      summary: status === 403 ? 'Access Denied' : 'Unexpected Error',
      description: errorDescription || 'Sorry, there was a problem. Contact CalCentral support if the problem persists.'
    };
  };

  var loadStoredUsers = function(tab, refresh) {
    if (refresh || $scope.userSearch.tabs.saved.users === null) {
      adminFactory.getStoredUsers().success(function(data) {
        $scope.userSearch.tabs.saved.users = _.get(data, 'users.saved');
        $scope.userSearch.tabs.recent.users = _.get(data, 'users.recent');
        if (tab.users === null || tab.users.length === 0) {
          tab.message = 'No ' + tab.label.toLowerCase() + ' items.';
        }
      }).error(function(data, status) {
        reportError(tab, status, data.error);
      });
    }
    tab.isLoading = false;
  };

  $scope.userSearch.byNameOrId = function() {
    $scope.userSearch.tabs.search.message = null;
    $scope.userSearch.tabs.search.inProgress = true;
    var nameOrId = $scope.userSearch.tabs.search.nameOrId;
    adminFactory.searchUsers(nameOrId).success(function(data) {
      if (!data.users || data.users.length === 0) {
        $scope.userSearch.tabs.search.message = 'Your search on ' + nameOrId + ' did not match any users.';
      }
      $scope.userSearch.tabs.search.users = data.users;
    }).error(function(data, status) {
      reportError($scope.userSearch.tabs.search, status, data.error);
    }).finally(function() {
      $scope.userSearch.tabs.search.inProgress = false;
    });
  };

  $scope.userSearch.loadTab = function(tab) {
    tab.message = '';
    $scope.userSearch.selectedTab = tab;
    if (tab !== $scope.userSearch.tabs.search) {
      loadStoredUsers(tab, false);
    }
  };

  var init = function() {
    if (apiService.user.profile.roles.advisor) {
      $scope.userSearch.title = 'Student Lookup';
      $scope.userSearch.loadTab($scope.userSearch.tabs.search);
    }
  };

  init();
});
