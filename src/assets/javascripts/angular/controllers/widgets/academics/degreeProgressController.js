'use strict';

var angular = require('angular');
var _ = require('lodash');

angular.module('calcentral.controllers').controller('DegreeProgressController', function(degreeProgressFactory, $scope) {

  var config = {
    AAGADVMAS1: {
      hasForm: true
    },
    AAGQEAPRV: {
      hasForm: true
    },
    AAGADVPHD: {
      hasForm: true
    }
  };
  $scope.degreeProgress = {
    isLoading: true
  };

  var transformRequirements = function(progress) {
    _.each(progress.requirements, function(requirement) {
      requirement.hasForm = _.get(config, '[' + requirement.code + '][hasForm]', false);
    });
  };

  var transform = function(data) {
    var progresses = _.get(data, 'data.feed.degreeProgress');
    _.each(progresses, transformRequirements);
    return {
      progresses: progresses
    };
  };

  var loadDegreeProgress = function() {
    degreeProgressFactory.getDegreeProgress()
      .then(function(data) {
        angular.extend($scope.degreeProgress, transform(data));
        $scope.degreeProgress.links = _.get(data, 'data.feed.links');
        $scope.degreeProgress.errored = _.get(data, 'data.errored');
      })
      .finally(function() {
        $scope.degreeProgress.isLoading = false;
      });
  };

  loadDegreeProgress();
});
