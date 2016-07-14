'use strict';

var angular = require('angular');

angular.module('calcentral.services').service('statusHoldsService', function() {
  /**
   * Parses any terms past the legacy cutoff.  Mirrors current functionality for now, but this will be changed in redesigns slated
   * for GL6.
   */
  var parseCsTerm = function(term) {
    var termReg = {
      isSummer: term.isSummer,
      termName: term.termName,
      termId: term.termId,
      summary: null,
      explanation: null
    };
    if (term.registered === true) {
      termReg.summary = 'Officially Registered';
      termReg.explanation = term.isSummer ? 'You are officially registered for this term.' : 'You are officially registered and are entitled to access campus services.';
    }
    if (term.registered === false) {
      termReg.summary = 'Not Officially Registered';
      termReg.explanation = term.isSummer ? 'You are not officially registered for this term.' : 'You are not entitled to access campus services until you are officially registered.  In order to be officially registered, you must pay your Tuition and Fees, and have no outstanding holds.';
    }

    return termReg;
  };

  /**
   * Parses any terms on or before the legacy cutoff.  Mirrors current functionality, this should be able to be removed in Fall 2016.
   */
  var parseLegacyTerm = function(term) {
    var termReg = {
      isSummer: term.isSummer,
      termName: term.termName,
      termId: term.termId,
      summary: null,
      explanation: null
    };
    termReg.summary = term.regStatus.summary;
    termReg.explanation = term.regStatus.explanation;

    // Special summer parsing for the last legacy term (Summer 2016)
    if (term.isSummer) {
      if (term.regStatus.summary !== 'Registered') {
        termReg.summary = 'Not Officially Registered';
        termReg.explanation = 'You are not officially registered for this term.';
      } else {
        termReg.summary = 'Officially Registered';
        termReg.explanation = 'You are officially registered for this term.';
      }
    }

    return termReg;
  };

  return {
    parseCsTerm: parseCsTerm,
    parseLegacyTerm: parseLegacyTerm
  };
});
