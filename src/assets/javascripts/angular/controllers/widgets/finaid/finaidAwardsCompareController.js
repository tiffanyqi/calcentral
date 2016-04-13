'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Financial Aid - Awards controller
 */
angular.module('calcentral.controllers').controller('FinaidAwardsCompareController', function(
  $location,
  $q,
  $routeParams,
  $scope,
  finaidFactory,
  finaidService) {
  // Expose everything to the view
  $scope.finaidAwardsCompare = {
    information: {},
    isLoading: true,
    isLoadingCurrentAndPrior: false,
    data: {
      current: {},
      list: {},
      prior: {}
    },
    sections: [
      {
        id: 'summary',
        title: 'Summary Information'
      },
      {
        id: 'netcost',
        title: 'Net Cost'
      },
      {
        id: 'packages',
        title: 'Packages'
      }
    ],
    selected: {
      aidYear: '',
      package: ''
    },
    showCurrentAndPrior: false,
    toggle: {},
    types: [
      {
        title: 'Prior',
        id: 'prior'
      },
      {
        title: 'Current',
        id: 'current'
      }
    ]
  };
  $scope.isMainFinaid = false;

  /**
   * Check whether we should update the URL or not
   */
  var checkUpdateUrl = function() {
    if ($routeParams.finaidYearId !== finaidService.options.finaidYear.id) {
      $location.path('finances/finaid/compare/' + finaidService.options.finaidYear.id, false);
    }
  };

  /**
   * Set the Financial Aid year to what's available in the service
   */
  var setFinaidYear = function() {
    $scope.finaidAwardsCompare.selected.aidYear = finaidService.options.finaidYear;
  };

  /**
   * Parse the list of packages
   */
  var parseFinaidAwardCompareList = function(data) {
    $scope.finaidAwardsCompare.data.list = _.get(data, 'data.feed.awardParms');
    $scope.finaidAwardsCompare.errored = data.errored;
    $scope.finaidAwardsCompare.isLoading = false;
  };

  /**
   * Get the list of all the packages on different dates and times
   */
  var getFinaidAwardCompareList = function() {
    return finaidFactory.getAwardCompareList({
      finaidYearId: finaidService.options.finaidYear.id
    }).then(parseFinaidAwardCompareList);
  };

  /**
   * Select the first package in the dropdown (if there are any)
   */
  var selectFirstPackage = function() {
    var packages = _.get($scope, 'finaidAwardsCompare.data.list.data');
    if (_.get(packages, 'length')) {
      $scope.finaidAwardsCompare.selected.package = packages[0];
    }
  };

  /**
   * Parse the current package data
   */
  var parseCurrent = function(data) {
    angular.extend($scope.finaidAwardsCompare.data.current, _.get(data, 'data.feed'));
  };

  /**
   * Parse the current package data
   */
  var parsePrior = function(data) {
    angular.extend($scope.finaidAwardsCompare.data.prior, _.get(data, 'data.feed'));
  };

  /**
   * Load the current and prior data after changing the selected option in the dropdown
   */
  var loadCurrentAndPrior = function(priorDate) {
    if (!priorDate) {
      $scope.finaidAwardsCompare.data.current = {};
      $scope.finaidAwardsCompare.data.prior = {};
      $scope.finaidAwardsCompare.showCurrentAndPrior = false;
    } else {
      $scope.finaidAwardsCompare.isLoadingCurrentAndPrior = true;
      $scope.finaidAwardsCompare.showCurrentAndPrior = true;
      $q.all({
        current: finaidFactory.getAwardCompareCurrent({
          finaidYearId: finaidService.options.finaidYear.id
        }),
        prior: finaidFactory.getAwardComparePrior({
          finaidYearId: finaidService.options.finaidYear.id,
          date: priorDate.csdate
        })
      }).then(function(data) {
        parseCurrent(data.current);
        parsePrior(data.prior);
        $scope.finaidAwardsCompare.isLoadingCurrentAndPrior = false;
      });
    }
  };

  /**
   * By default, show all the different sections (e.g. "Summary Information", "Net Cost")
   */
  var showSectionsByDefault = function() {
    _.forEach($scope.finaidAwardsCompare.sections, function(section) {
      $scope.finaidAwardsCompare.toggle[section.id] = {
        show: true
      };
    });
  };

  /**
   * Load the compare list
   */
  var loadFinaidAwardsCompareList = function() {
    checkUpdateUrl();
    setFinaidYear();

    return getFinaidAwardCompareList()
      .then(selectFirstPackage);
  };

  $scope.$on('calcentral.custom.api.finaid.finaidYear', loadFinaidAwardsCompareList);
  $scope.$watch('finaidAwardsCompare.selected.package', loadCurrentAndPrior);
  showSectionsByDefault();
});
