'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Academics status, holds & blocks controller
 */
angular.module('calcentral.controllers').controller('AcademicsStatusHoldsBlocksController', function(apiService, profileFactory, slrDeeplinkFactory, residencyMessageFactory, registrationsFactory, $scope) {
  // Data for studentInfo and csHolds are pulled by the AcademicsController that
  // governs the academics template. The statusHoldsBlocks segment watches those
  // for changes in order to display the corresponding UI elements.
  $scope.statusHoldsBlocks = {};
  $scope.regStatus = {
    summary: null,
    explanation: null,
    needsAction: null,
    isLoading: true
  };

  $scope.$watchGroup(['regStatus.summary', 'api.user.profile.features.csHolds'], function(newValues) {
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

  var getRegistrations = function() {
    registrationsFactory.getRegistrations()
      .then(parseRegistrations);
  };

  /**
   * Checks to see whether the registration is on or before Settings.terms.legacy_cutoff.
   * This code should be able to be removed by Fall 2016, when we should start getting term data exclusively from the hub.
   * There is also the possibility of the hub bringing over more than one registration for a term.  This will be addressed
   * in the redesign for Status/Blocks/Holds, slated for GL6.
   */
  var parseRegistrations = function(data) {
    var currentTerm = data.data.terms.current.id;
    var regStatus = data.data.registrations[currentTerm];

    if (regStatus[0].isLegacy) {
      parseLegacyTerm(regStatus[0]);
    } else {
      parseCsTerm(regStatus[0]);
    }

    return;
  };

  /**
   * Parses any terms past the legacy cutoff.  Mirrors current functionality for now, but this will be changed in redesigns slated
   * for GL6.
   */
  var parseCsTerm = function(term) {
    if (term.registered === true) {
      $scope.regStatus.summary = 'Registered';
      $scope.regStatus.explanation = 'You are officially registered for this term and are entitled to access campus services.';
      $scope.regStatus.needsAction = false;
    }
    if (term.registered === false) {
      $scope.regStatus.summary = 'Not Registered';
      $scope.regStatus.explanation = 'In order to be officially registered, you must pay at least 20% of your tuition and fees, have no outstanding holds, and be enrolled in at least one class.';
      $scope.regStatus.needsAction = true;
    }
  };

  /**
   * Parses any terms on or before the legacy cutoff.  Mirrors current functionality, this should be able to be removed in Fall 2016.
   */
  var parseLegacyTerm = function(term) {
    $scope.regStatus.summary = term.regStatus.summary;
    $scope.regStatus.explanation = term.regStatus.explanation;
    $scope.regStatus.needsAction = term.regStatus.needsAction;
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
    .then(getRegistrations)
    .then(function() {
      $scope.residency.isLoading = false;
    });
  };

  loadResidencyInformation();
});
