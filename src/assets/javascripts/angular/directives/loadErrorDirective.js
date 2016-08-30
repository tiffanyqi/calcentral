'use strict';

var angular = require('angular');

/**
 * Set a scope flag to signal an error during ng-load, enabling fallback to a default image.
 */
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
