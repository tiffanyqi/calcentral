'use strict';

var _ = require('lodash');
var angular = require('angular');

/**
 * Enrollment Verification Controller
 */
angular.module('calcentral.controllers').controller('EnrollmentVerificationController', function(apiService, enrollmentVerificationFactory, $scope) {
  var title = 'My Enrollment Verification';
  apiService.util.setTitle(title);

  $scope.enrollmentMessages = {
    isLoading: true,
    hasMessages: false,
    messages: {
      lawVerification: {},
      requestOfficial: {},
      viewOnline: {}
    }
  };

  var parseMessages = function(data) {
    var messages = data.data.feed.root.getMessageCatDefn;

    if (messages) {
      $scope.enrollmentMessages.messages.viewOnline = _.find(messages, {
        'messageNbr': '1'
      });
      $scope.enrollmentMessages.messages.requestOfficial = _.find(messages, {
        'messageNbr': '2'
      });
      $scope.enrollmentMessages.messages.lawVerification = _.find(messages, {
        'messageNbr': '3'
      });
      $scope.enrollmentMessages.hasMessages = true;
    }
  };

  var getMessages = function() {
    enrollmentVerificationFactory.getEnrollmentVerificationMessages()
      .then(parseMessages)
      .finally(function() {
        $scope.enrollmentMessages.isLoading = false;
      });
  };

  getMessages();
});
