'use strict';

var _ = require('lodash');
var angular = require('angular');

/**
 * Controller populates academic dates from TBD calendar API.
 */
angular.module('calcentral.controllers').controller('AcademicDatesController', function(apiService, $scope) {
  /**
   * TODO: populate the `academicDates.items` array, each item probably in the
   * form `{date: Mmm dd, title: 'some text'}` via TBD academicDateCalendar
   * service API.
   */
  $scope.academicDates = {
    items: [],
    isLoading: true
  };

  /**
   * TODO: replace this hard-coded array of date+title pairs wth call to TBD
   * academicDateCalendar service API.
   *
   * Hard-coded dates starting from GL5, Mar 23, and 3 months forward.
   * source: http://registrar.berkeley.edu/CalendarDisp.aspx?terms=current
   */
  var academicDates = [
    {
      date: 'Mar 21-25',
      title: 'Spring Recess'
    },
    {
      date: 'Mar 25',
      title: 'Academic and Administrative Holiday'
    },
    {
      date: 'Apr 16',
      title: 'Cal Day'
    },
    {
      date: 'Apr 29',
      title: 'Formal Classes End'
    },
    {
      date: 'May 2-6',
      title: 'Reading/Review/Recitation Week'
    },
    {
      date: 'May 6',
      title: 'Last Day of Instruction'
    },
    {
      date: 'May 9-13',
      title: 'Final Examinations'
    },
    {
      date: 'May 13',
      title: 'SPRING SEMESTER ENDS'
    },
    {
      date: 'May 14',
      title: 'Commencement'
    },
    {
      date: 'May 23 - Aug 12',
      title: 'Summer Sessions'
    },
    {
      date: 'May 23',
      title: 'First Six-Week Session begins'
    },
    {
      date: 'May 30',
      title: 'Academic and Administrative Holiday'
    },
    {
      date: 'Jun 6',
      title: 'Ten-Week Session begins'
    },
    {
      date: 'Jun 20',
      title: 'Eight-Week Session begins'
    }
  ];

  /**
   * append colon `:` to each item.date field for display purpose only.
   */
  var parseAcademicDates = function(item) {
    var char = ':';
    var value = item.date;
    var last = value.charAt(value.length - 1);
    if (last !== char) {
      item.date = value.concat(char);
    }
  };

  /**
   * TODO: replace hard-coded data feed with TBD academicDateCalendar service
   * API data.
   */
  var data = {
    data: {
      feed: {
        academicDates: academicDates
      }
    }
  };

  /**
   * TODO: replace hard-coded IFFE with TBD academicDateCalendar service API
   * request and callback.
   */
  ;(function(data) {
    var dates = _.get(data, 'data.feed.academicDates');
    _.each(dates, parseAcademicDates);
    $scope.academicDates.items = dates;
    $scope.academicDates.isLoading = false;
  }(data));
});
