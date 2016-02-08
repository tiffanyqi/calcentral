'use strict';

var _ = require('lodash');
var angular = require('angular');

/**
 * Controller populates academic dates from TBD calendar API.
 */
angular.module('calcentral.controllers').controller('AcademicDatesController', function(apiService, academicDatesFactory, $scope) {
  angular.extend($scope, {
    academicDates: {
      items: [],
      isLoading: true
    }
  });

  var getAcademicDates = function() {
    academicDatesFactory.getAcademicDates().then(function(data) {
      var dates = _.get(data, 'data.feed.academicDates');
      $scope.academicDates.items = dates;
      $scope.academicDates.isLoading = false;
    });
  };

  getAcademicDates();
});
