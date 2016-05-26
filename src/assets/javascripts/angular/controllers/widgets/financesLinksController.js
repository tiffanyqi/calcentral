'use strict';

var angular = require('angular');

/**
 * Footer controller
 */
angular.module('calcentral.controllers').controller('FinancesLinksController', function(apiService, campusLinksFactory, financesLinksFactory, $scope) {
  $scope.isLoading = true;
  $scope.campuslinks = {
    data: {}
  };
  $scope.eft = {
    data: {},
    studentActive: true,
    eftLink: {
      url: 'http://studentbilling.berkeley.edu/eft.htm',
      title: 'Some refunds, payments, and paychecks may be directly deposited to your bank account'
    },
    manageAccountLink: {
      url: 'https://eftstudent.berkeley.edu/',
      title: 'Manage your electronic fund transfer accounts'
    }
  };
  $scope.fpp = {
    data: {},
    fppLink: {
      url: 'http://studentbilling.berkeley.edu/deferredPay.htm',
      title: 'Details about tuition and fees payment plan'
    },
    activatePlanLink: {
      title: 'Activate your tuition and fees payment plan'
    }
  };

  var parseCampusLinks = function(data) {
    angular.extend($scope.campuslinks.data, data);
  };

  /**
   Parse incoming response from EFT.  If the response returns a 404 for the searched
   SID, this likely means the SID has never logged on to the EFT web app before,
   so we parse it the same way we would an 'inactive' student.
   **/
  var parseEftEnrollment = function(data) {
    angular.merge($scope.eft, data);
    if ($scope.eft.data.statusCode === 404 || $scope.eft.data.data.eftStatus === 'inactive') {
      $scope.eft.studentActive = false;
    }
  };

  var parseFppEnrollment = function(data) {
    angular.extend($scope.fpp.data, data.data.feed.ucSfFppEnroll);
  };

  var loadEftEnrollment = function() {
    financesLinksFactory.getEftEnrollment()
      .then(parseEftEnrollment);
  };

  var loadFppEnrollment = function() {
    if (apiService.user.profile.isDirectlyAuthenticated) {
      financesLinksFactory.getFppEnrollment()
        .then(parseFppEnrollment);
    }
    return;
  };

  var initialize = function() {
    campusLinksFactory.getLinks({
      category: 'finances'
    }).then(parseCampusLinks)
      .then(loadEftEnrollment)
      .then(loadFppEnrollment)
      .finally(function() {
        $scope.isLoading = false;
      });
  };

  initialize();
});
