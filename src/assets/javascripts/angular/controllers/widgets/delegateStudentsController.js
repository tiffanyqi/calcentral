'use strict';

var _ = require('lodash');
var angular = require('angular');

/**
 * Controller gets student linked to delegate user account
 */
angular.module('calcentral.controllers').controller('DelegateStudentsController', function(apiService, adminFactory, delegateFactory, $scope) {
  $scope.delegateStudents = {
    isLoading: true
  };

  /**
   * `delegateAccessPrivileges` here mean __only__ those that allow the delegate
   * "linkable" access to the student's profile. The `phone` privilege by itself
   * does not grant that access.
   */
  var delegateAccessPrivileges = [
    'financial',
    'phone',
    'viewEnrollments',
    'viewGrades'
  ];

  /**
   * setDelegateAccess() adds `delegateAccess` property on student, if and only
   * if the student has granted at least one `viewable` (i.e., other than phone)
   * privilege.
   */
  var setDelegateAccess = function(student) {
    var phone = 'phone';
    var viewable = _.some(delegateAccessPrivileges, function(key) {
      return student.privileges[key] && key !== phone;
    });

    student.delegateAccess = viewable;

    /**
     * If at least one student grants no privileges, this flag lets us show the
     * global 'No privileges' explanatory paragraph in the template.
     */
    if (!viewable && !$scope.showNoPrivilegesMessage && !student.privileges[phone]) {
      $scope.showNoPrivilegesMessage = true;
    }

    /**
     * If at least one student grants only phone privilege, this flag lets us
     * show the global 'phone-and-in-person privileges' explanatory paragraph in
     * the template.
     */
    if (!viewable && !$scope.showPhoneInPersonPrivilegesMessage && student.privileges[phone]) {
      $scope.showPhoneInPersonPrivilegesMessage = true;
    }
  };

  /**
   * TODO:
   * REPLACE THIS PROPERTY-SETTING METHOD WITH BACK-END PROPERTY SETTING ON THE
   * STUDENT OBJECT.
   *
   * setStudentPhotoApi() adds the `profilePhotoUrl` property for a fictitious
   * API to retrieve a delegate student's profile photo.
   *
   * For testing purposes, you can commment out the single assignment to display
   * the img-not-available case in the template.
   */
  var setStudentPhotoApi = function(student) {
    student.profilePhotoApi = '/api/student/photo/' + student.uid;
  };

  var getStudents = function() {
    return delegateFactory.getStudents().then(function(data) {
      angular.extend($scope, _.get(data, 'data.feed'));

      var students = _.get(data, 'data.feed.students');
      /**
       * TODO: replace setStudentPhotoApi() function with back-end photo URL
       * property (see above).
       */
      _.each(students, setStudentPhotoApi);

      _.each(students, setDelegateAccess);
      $scope.students = students;
      $scope.delegateStudents.isLoading = false;
    });
  };

  $scope.delegateStudents.actAs = function(uid) {
    return adminFactory.delegateActAs({
      uid: uid
    }).success(apiService.util.redirectToHome);
  };

  getStudents();
});
