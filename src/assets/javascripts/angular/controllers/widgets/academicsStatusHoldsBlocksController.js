'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Academics status, holds & blocks controller
 */
angular.module('calcentral.controllers').controller('AcademicsStatusHoldsBlocksController', function(apiService, profileFactory, slrDeeplinkFactory, residencyMessageFactory, $scope) {
  // Data for studentInfo and csHolds are pulled by the AcademicsController that
  // governs the academics template. The statusHoldsBlocks segment watches those
  // for changes in order to display the corresponding UI elements.
  $scope.statusHoldsBlocks = {};

  $scope.$watchGroup(['studentInfo.regStatus.code', 'api.user.profile.features.csHolds'], function(newValues) {
    var enabledSections = [];

    if (newValues[0] !== null && newValues[0] !== undefined) {
      enabledSections.push('Status');
    }

    if (newValues[1]) {
      enabledSections.push('Holds');
    }

    enabledSections.push('Blocks');

    $scope.statusHoldsBlocks.enabledSections = enabledSections;
  });

  // Request-and-parse sequence for the Statement of Legal Residency deeplink
  var fetchSlrDeeplink = slrDeeplinkFactory.getUrl;

  var parseSlrDeeplink = function(data) {
    $scope.slr.deeplink = _.get(data, 'data.feed.root.ucSrSlrResources.ucSlrLinks.ucSlrLink');
    $scope.slr.isErrored = _.get(data, 'data.errored');
    $scope.slr.isLoading = false;
  };

  var getSlrDeeplink = function() {
    // Users in 'view-as' mode are not allowed to access the student's SLR link.
    // Guard here to keep this function self-contained.
    if (apiService.user.profile.actingAsUid || !apiService.user.profile.canSeeCSLinks) {
      return;
    }

    angular.extend($scope, {
      slr: {
        backToText: 'My Academics',
        deeplink: false,
        isErrored: false,
        isLoading: true
      }
    });

    fetchSlrDeeplink().then(parseSlrDeeplink);
  };

  // Request-and-parse sequence on the student feed for California Residency status.
  angular.extend($scope, {
    residency: {
      isLoading: true,
      message: {}
    }
  });

  var getPerson = profileFactory.getPerson;

  var parseCalResidency = function(residency) {
    angular.merge($scope.residency, residency);

    var messageCode = _.get(residency, 'message.code');
    if (messageCode) {
      var getResidencyMessage = function(options) {
        return residencyMessageFactory.getMessage(options);
      };

      getResidencyMessage({
        messageNbr: messageCode
      })
      .then(function(data) {
        var messageCatDefn = _.get(data, 'data.feed.root.getMessageCatDefn');
        if (messageCatDefn) {
          angular.merge($scope.residency.message, {
            description: messageCatDefn.descrlong,
            label: messageCatDefn.messageText
          });
        }
      });
    }
  };

  var parsePerson = function(data) {
    var residency = _.get(data, 'data.feed.student.residency');

    if (!residency) {
      return;
    }

    parseCalResidency(residency);
  };

  var loadResidencyInformation = function() {
    getPerson()
    .then(parsePerson)
    .then(getSlrDeeplink)
    .then(function() {
      $scope.residency.isLoading = false;
    });
  };

  loadResidencyInformation();
});
