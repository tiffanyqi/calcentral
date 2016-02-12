'use strict';

var _ = require('lodash');
var angular = require('angular');

/**
 * Advising Resources Controller
 * Show Campus Solutions links and favorite reports
 */
angular.module('calcentral.controllers').controller('AdvisingResourcesController', function(apiService, advisingFactory, $scope) {
  var backToText = 'My Dashboard';
  $scope.advisingResources = {
    isLoading: true
  };

  /**
   * Add the back to text (used for Campus Solutions) to the link
   */
  var addBackToTextLink = function(link) {
    console.log(link.url);
    link.backToText = backToText;
    return link;
  };

  /**
   * Add the back to text
   */
  var addBackToText = function(resources) {
    if (_.get(resources, 'ucAdvisingResources.ucAdvisingFavoriteReports.length')) {
      _.map(resources.ucAdvisingResources.ucAdvisingFavoriteReports, addBackToTextLink);
    }

    if (_.get(resources, 'ucAdvisingResources.ucAdvisingLinks')) {
      _.mapValues(resources.ucAdvisingResources.ucAdvisingLinks, addBackToTextLink);
    }

    return resources;
  };

  /**
   * Parse the advising resources
   */
  var parseResources = function(data) {
    var resources = _.get(data, 'data.feed');
    resources = addBackToText(resources);
    angular.extend($scope, resources);
    $scope.advisingResources.isLoading = false;
  };

  /**
   * Load the advising resources
   */
  var loadResources = function() {
    advisingFactory.getResources().then(parseResources);
  };

  loadResources();
});
