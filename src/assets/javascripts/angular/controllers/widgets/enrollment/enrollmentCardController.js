'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Enrollment Card Controller
 * Main controller for the enrollment card on the My Academics page
 */
angular.module('calcentral.controllers').controller('EnrollmentCardController', function(apiService, enrollmentFactory, holdsFactory, $scope, $q) {
  var backToText = 'Class Enrollment';
  $scope.enrollment = {
    holds: {
      isLoading: true,
      hasHolds: false
    },
    isLoading: true,
    terms: [],
    sections: [
      {
        id: 'meet_advisor',
        title: 'Meet Advisor'
      },
      {
        id: 'plan',
        title: 'Plan'
      },
      {
        id: 'explore',
        title: 'Explore'
      },
      {
        id: 'schedule',
        title: 'Schedule'
      },
      {
        id: 'decide',
        title: 'Decide',
        show: true
      },
      {
        id: 'adjust',
        title: 'Adjust'
      }
    ]
  };

  /**
   * Stop the main spinner.
   * This happens when
   * 	- the terms data has loaded
   * 	- or when there is no term data
   */
  var stopMainSpinner = function() {
    $scope.enrollment.isLoading = false;
  };

  /**
   * Set the data for a specific term
   */
  var setTermData = function(data) {
    var term = _.find($scope.enrollment.terms, {
      termId: data.term
    });

    if (term) {
      angular.extend(term, data);
    }
  };

  /**
   * Map enrollment periods by id (e.g. 'phase1')
   * This makes it easier to look it up in JavaScript
   */
  var mapEnrollmentPeriodsById = function(data) {
    if (!data.enrollmentPeriod) {
      return data;
    }

    data.enrollmentPeriodsById = _.indexBy(data.enrollmentPeriod, 'id');

    return data;
  };

  /**
   * Add aditional metadata to the links
   */
  var mapLinks = function(data) {
    if (!data.links) {
      return data;
    }

    data.links = _.mapValues(data.links, function(link) {
      link.backToText = backToText;
      return link;
    });

    return data;
  };

  /**
   * Parse a certain enrollment term
   */
  var parseEnrollmentTerm = function(data) {
    var termData = _.get(data, 'data.feed.enrollmentTerm');
    if (!termData) {
      return;
    }

    termData = mapEnrollmentPeriodsById(termData);
    termData = mapLinks(termData);

    setTermData(termData);
  };

  /**
   * Create a promise for a specific enrollment term
   */
  var createEnrollmentPromise = function(enrollmentTerm) {
    return enrollmentFactory.getEnrollmentTerm({
      termId: enrollmentTerm.termId
    }).then(parseEnrollmentTerm);
  };

  /**
   * Create promises for all the enrollment terms
   */
  var createEnrollmentPromises = function(enrollmentTerms) {
    var promiseArray = _.map(enrollmentTerms, createEnrollmentPromise);
    return $q.all(promiseArray);
  };

  /**
   * Parse all the terms and create an array of promises for each
   */
  var parseEnrollmentTerms = function(data) {
    if (!_.get(data, 'data.feed.enrollmentTerms.length')) {
      return;
    }

    var enrollmentTerms = _.get(data, 'data.feed.enrollmentTerms');
    $scope.enrollment.terms = enrollmentTerms;
    return createEnrollmentPromises(enrollmentTerms);
  };

  /**
   * Load the enrollment data and fire off subsequent events
   */
  var loadEnrollmentData = function() {
    enrollmentFactory.getEnrollmentTerms()
      .then(parseEnrollmentTerms)
      .then(stopMainSpinner);
  };

  /**
   * Load the holds information for this student.
   * If they do have a hold, we need to show a message to the student.
   */
  var loadHolds = function() {
    return holdsFactory.getHolds().then(function(data) {
      $scope.enrollment.holds.isLoading = false;
      $scope.enrollment.holds.hasHolds = !!_.get(data, 'data.feed.serviceIndicators.length');
    });
  };

  /**
   * We should check the roles of the current person since we should only load
   * the enrollment card for students
   */
  var checkRoles = function(data) {
    if (_.get(data, 'student')) {
      loadEnrollmentData();
      loadHolds();
    } else {
      stopMainSpinner();
    }
  };

  $scope.$watch('api.user.profile.roles', checkRoles);
});
