'use strict';

var angular = require('angular');

/**
 * Admin Factory
 */
angular.module('calcentral.factories').factory('adminFactory', function(apiService, $http) {
  var actAsUrl = '/act_as';
  var advisorActAsUrl = '/advisor_act_as';
  var delegateActAsUrl = '/delegate_act_as';
  var searchUsersUrl = '/api/search_users/';
  var searchUsersByUidUrl = '/api/search_users/uid/';
  var stopActAsUrl = '/stop_act_as';
  var stopAdvisorActAsUrl = '/stop_advisor_act_as';
  var stopDelegateActAsUrl = '/stop_delegate_act_as';
  var storedUsersUrl = '/stored_users';
  var storeSavedUserUrl = '/store_user/saved';
  var deleteSavedUserUrl = '/delete_user/saved';
  var deleteAllRecentUsersUrl = '/delete_users/recent';
  var deleteAllSavedUsersUrl = '/delete_users/saved';

  var delegateActAs = function(user) {
    return $http.post(delegateActAsUrl, user);
  };

  var stopDelegateActAs = function() {
    return $http.post(stopDelegateActAsUrl);
  };

  var actAs = function(user) {
    var isAdvisorOnly = apiService.user.profile.roles.advisor && !apiService.user.profile.isSuperuser && !apiService.user.profile.isViewer;
    var url = isAdvisorOnly ? advisorActAsUrl : actAsUrl;
    return $http.post(url, user);
  };

  var stopActAs = function() {
    var url = apiService.user.profile.advisorActingAsUid ? stopAdvisorActAsUrl : stopActAsUrl;
    return $http.post(url);
  };

  var userLookup = function(options) {
    return apiService.http.request(options, searchUsersUrl + options.id);
  };

  var userLookupByUid = function(options) {
    return apiService.http.request(options, searchUsersByUidUrl + options.id);
  };

  var getStoredUsers = function(options) {
    return apiService.http.request(options, storedUsersUrl);
  };

  var storeUser = function(options) {
    return $http.post(storeSavedUserUrl, options);
  };

  var deleteUser = function(options) {
    return $http.post(deleteSavedUserUrl, options);
  };

  var deleteAllRecentUsers = function() {
    return $http.post(deleteAllRecentUsersUrl);
  };

  var deleteAllSavedUsers = function() {
    return $http.post(deleteAllSavedUsersUrl);
  };

  return {
    actAs: actAs,
    delegateActAs: delegateActAs,
    deleteAllRecentUsers: deleteAllRecentUsers,
    deleteAllSavedUsers: deleteAllSavedUsers,
    deleteUser: deleteUser,
    getStoredUsers: getStoredUsers,
    stopActAs: stopActAs,
    stopDelegateActAs: stopDelegateActAs,
    storeUser: storeUser,
    userLookup: userLookup,
    userLookupByUid: userLookupByUid
  };
});
