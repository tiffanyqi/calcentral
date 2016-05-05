'use strict';

var angular = require('angular');

angular.module('calcentral.directives').directive('ccSortableColumnDirective', function() {
  return {
    scope: true,
    link: function(scope, elem, attrs) {
      scope.sortAttribute = attrs.ccSortableColumnDirective;
      scope.columnHeading = attrs.columnHeading;
      scope.applySort = function(sortAttribute) {
        scope.tableSort.reverse = (scope.tableSort.column === sortAttribute ? !scope.tableSort.reverse : false);
        scope.tableSort.column = sortAttribute;
      };
    },
    templateUrl: 'directives/sortable_column.html'
  };
});
