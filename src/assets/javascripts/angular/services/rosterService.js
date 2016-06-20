'use strict';

var angular = require('angular');

angular.module('calcentral.services').factory('rosterService', function() {
  /**
   * Returns link to gMail compose with TO address specified
   * @param {String} toAddress 'TO' address string
   */
  var bmailLink = function(toAddress) {
    var urlEncodedToAddress = encodeURIComponent(toAddress);
    return 'https://mail.google.com/mail/u/0/?view=cm&fs=1&tf=1&source=mailto&to=' + urlEncodedToAddress;
  };

  return {
    bmailLink: bmailLink
  };
});

