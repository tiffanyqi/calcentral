'use strict';

var angular = require('angular');

angular.module('calcentral.directives').directive('ccLoadErrorDirective', function() {
  return {
    link: function(scope, elm, attrs) {
      elm.bind('error', function() {
        scope.$apply(function() {
          scope[attrs.ccLoadErrorDirective].loadError = true;
        });
      });
    }
  };
});
