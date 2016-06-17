'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Preview of user profile prior to viewing-as
 */
angular.module('calcentral.controllers').controller('UserOverviewController', function(adminService, advisingFactory, holdsFactory, residencyMessageFactory, apiService, $routeParams, $scope) {
  $scope.academics = {
    isLoading: true,
    excludeLinksToRegistrar: true
  };
  $scope.holdsInfo = {
    isLoading: true
  };
  $scope.regBlocks = {
    isLoading: true
  };
  $scope.regStatus = {
    summary: null,
    explanation: null,
    needsAction: null,
    isLoading: true
  };
  $scope.residency = {
    isLoading: true
  };
  $scope.targetUser = {
    isLoading: true
  };
  $scope.statusHoldsBlocks = {};

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

  var defaultErrorDescription = function(status) {
    if (status === 403) {
      return 'You are not authorized to view this user\'s data.';
    } else {
      return 'Sorry, there was a problem fetching this user\'s data. Contact CalCentral support if the error persists.';
    }
  };

  var errorReport = function(status, errorDescription) {
    return {
      summary: status === 403 ? 'Access Denied' : 'Unexpected Error',
      description: errorDescription || defaultErrorDescription(status)
    };
  };

  var loadProfile = function() {
    var targetUserUid = $routeParams.uid;
    advisingFactory.getStudent({
      uid: targetUserUid
    }).success(function(data) {
      angular.extend($scope.targetUser, _.get(data, 'attributes'));
      angular.extend($scope.residency, _.get(data, 'residency.feed.student.residency'));
      $scope.targetUser.ldapUid = targetUserUid;
      $scope.targetUser.addresses = apiService.profile.fixFormattedAddresses(_.get(data, 'contacts.feed.student.addresses'));
      $scope.targetUser.phones = _.get(data, 'contacts.feed.student.phones');
      $scope.targetUser.emails = _.get(data, 'contacts.feed.student.emails');
      // 'student.fullName' is expected by shared code (e.g., photo unavailable widget)
      $scope.targetUser.fullName = $scope.targetUser.defaultName;
      apiService.util.setTitle($scope.targetUser.defaultName);
      parseCalResidency();
      // Get links to advising resources
      advisingFactory.getAdvisingResources({
        uid: targetUserUid
      }).then(function(data) {
        $scope.ucAdvisingResources = _.get(data, 'data.feed.ucAdvisingResources');
      });
    }).error(function(data, status) {
      $scope.targetUser.error = errorReport(status, data.error);
    }).finally(function() {
      $scope.residency.isLoading = false;
      $scope.targetUser.isLoading = false;
    });
  };

  var loadAcademics = function() {
    advisingFactory.getStudentAcademics({
      uid: $routeParams.uid
    }).success(function(data) {
      angular.extend($scope, data);
      // We use aliases in scope because the user overview page has cards that are shared with My Academics, etc.
      $scope.academics.universityRequirements = $scope.requirements;
    }).error(function(data, status) {
      $scope.academics.error = errorReport(status, data.error);
    }).finally(function() {
      $scope.academics.isLoading = false;
    });
  };

  var loadBlocks = function() {
    advisingFactory.getStudentBlocks({
      uid: $routeParams.uid
    }).success(function(data) {
      angular.extend($scope.regBlocks, data);
    }).finally(function() {
      $scope.regBlocks.isLoading = false;
    });
  };

  var loadHolds = function() {
    holdsFactory.getHolds({
      uid: $routeParams.uid
    }).success(function(data) {
      $scope.holds = _.get(data, 'data.feed');
    }).finally(function() {
      $scope.holdsInfo.isLoading = false;
    });
  };

  var loadRegistrations = function() {
    advisingFactory.getStudentRegistrations({
      uid: $routeParams.uid
    }).success(function(data) {
      var currentTerm = data.terms.current.id;
      var regStatus = data.registrations[currentTerm];

      if (regStatus[0].isLegacy) {
        parseLegacyTerm(regStatus[0]);
      } else {
        parseCsTerm(regStatus[0]);
      }
      return;
    }).finally(function() {
      $scope.regStatus.isLoading = false;
    });
  };

  var parseCalResidency = function() {
    var messageCode = $scope.residency.message.code;
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

  $scope.targetUser.actAs = function() {
    adminService.actAs($scope.targetUser);
  };

  $scope.$on('calcentral.api.user.isAuthenticated', function(event, isAuthenticated) {
    if (isAuthenticated) {
      // Refresh user properties because the canSeeCSLinks property is sensitive to the current route.
      apiService.user.fetch()
      .then(loadProfile)
      .then(loadAcademics)
      .then(loadHolds)
      .then(loadBlocks)
      .then(loadRegistrations);
    }
  });
});
