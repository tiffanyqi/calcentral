'use strict';

var angular = require('angular');
var _ = require('lodash');

/**
 * Emergency Contact controller
 */
angular.module('calcentral.controllers').controller('EmergencyContactController', function(apiService, profileFactory, $scope) {

  angular.extend($scope, {
    currentObject: {},
    emptyObject: {
      country: 'USA',
      primaryContact: 'N',
      sameAddressEmpl: 'N',
      samePhoneEmpl: 'N'
    },
    errorMessage: '',
    isLoading: true,
    isSaving: false,
    items: {
      content: [],
      editorEnabled: false
    }
  });

  /**
   * Contact editor controls
   */

  var actionCompleted = function(data) {
    apiService.profile.actionCompleted($scope, data, loadInformation);
  };

  var deleteCompleted = function(data) {
    $scope.isDeleting = false;
    actionCompleted(data);
  };

  var saveCompleted = function(data) {
    $scope.isSaving = false;
    actionCompleted(data);
  };

  var normalizePostData = function normalizePostData(value) {
    // JSHint objects to `value == null`... but this is way cooler anyway...
    return /null|undefined/.test(value) ? '' : value;
  };

  $scope.closeEditor = function() {
    apiService.profile.closeEditor($scope);
  };

  $scope.cancelEdit = function() {
    $scope.isSaving = false;
    $scope.closeEditor();
  };

  $scope.deleteContact = function(item) {
    return apiService.profile.delete($scope, profileFactory.deleteEmergencyContact, {
      contactName: item.contactName
    }).then(deleteCompleted);
  };

  $scope.saveContact = function(item) {
    // take only the first phone in the list
    var phone = item.emergencyPhones && item.emergencyPhones[0] || {};

    apiService.profile.save($scope, profileFactory.postEmergencyContact, {
      // Let Campus Solutions growl about any required field errors
      contactName: item.contactName,
      isPrimaryContact: item.primaryContact,
      relationship: item.relationship,
      isSameAddressEmpl: item.sameAddressEmpl,
      isSamePhoneEmpl: item.samePhoneEmpl,

      // Allow these items to be empty strings
      addrField1: normalizePostData(item.addrField1),
      addrField2: normalizePostData(item.addrField2),
      addrField3: normalizePostData(item.addrField3),
      address1: normalizePostData(item.address1),
      address2: normalizePostData(item.address2),
      address3: normalizePostData(item.address3),
      address4: normalizePostData(item.address4),
      addressType: normalizePostData(item.addressType),
      city: normalizePostData(item.city),
      country: normalizePostData(item.country),
      county: normalizePostData(item.county),
      emailAddr: normalizePostData(item.emailAddr),
      geoCode: normalizePostData(item.geoCode),
      houseType: normalizePostData(item.houseType),
      inCityLimit: normalizePostData(item.inCityLimit),
      num1: normalizePostData(item.num1),
      num2: normalizePostData(item.num2),
      phone: normalizePostData(phone.phone),
      phoneType: normalizePostData(phone.phoneType),
      extension: normalizePostData(phone.extension),
      postal: normalizePostData(item.postal),
      state: normalizePostData(item.state)
    }).then(saveCompleted);
  };

  $scope.showAdd = function() {
    apiService.profile.showAdd($scope, $scope.emptyObject);
  };

  $scope.showEdit = function(item) {
    apiService.profile.showEdit($scope, item);
  };

  /**
   * Phone editor controls
   */

  angular.extend($scope, {
    emergencyPhone: {
      currentObject: {},
      emptyObject: {},
      errorMessage: '',
      isLoading: true,
      isSaving: false,
      items: {
        content: [],
        editorEnabled: false
      },
      phoneTypes: {
        // Map phoneTypes to match Campus Solutions emergency contact phoneTypes.
        'BUSN': 'Business',
        'CAMP': 'Campus',
        'HOME': 'Home/Permanent',
        'INTL': 'International',
        'LOCL': 'Local',
        'CELL': 'Mobile',
        'OTR': 'Other'
      }
    }
  });

  $scope.emergencyPhone.cancelEdit = function() {
    $scope.emergencyPhone.isSaving = false;
    $scope.emergencyPhone.closeEditor();
  };

  $scope.emergencyPhone.closeEditor = function() {
    apiService.profile.closeEditor($scope.emergencyPhone);
  };

  $scope.emergencyPhone.deletePhone = function(item) {
    // profileFactory.deleteEmergencyContact
  };

  $scope.emergencyPhone.save = function(item) {
    // profileFactory.postEmergencyContact
  };

  $scope.emergencyPhone.showAdd = function() {
    apiService.profile.showAdd($scope.emergencyPhone, $scope.emergencyPhone.emptyObject);
  };

  $scope.emergencyPhone.showEdit = function(item) {
    apiService.profile.showEdit($scope.emergencyPhone, item);
  };

  var initEmergencyPhones = function(emergencyContacts) {
    var phones = _.map(emergencyContacts, function(contact) {
      return contact.emergencyPhone;
    });

    $scope.emergencyPhone.items.content = _.flattenDeep(phones);
  };

  /**
   * Sequence of functions for loading emergencyContact data
   */
  var getEmergencyContacts = profileFactory.getEmergencyContacts;

  var parseEmergencyContacts = function(data) {
    var emergencyContacts = _.get(data, 'data.feed.students.student.emergencyContacts.emergencyContact') || [];

    initEmergencyPhones(emergencyContacts);

    _(emergencyContacts).each(function(emergencyContact) {
      fixFormattedAddress(emergencyContact);
    });

    $scope.items.content = emergencyContacts;
  };

  var fixFormattedAddress = function(emergencyContact) {
    emergencyContact.formattedAddress = emergencyContact.formattedAddress || '';

    if (emergencyContact.formattedAddress) {
      emergencyContact.formattedAddress = apiService.profile.fixFormattedAddress(emergencyContact.formattedAddress);
    }
  };

  /**
   * handle relationshipTypes, country, address, states.
   */
  var getTypesRelationship = profileFactory.getTypesRelationship;

  var parseTypesRelationship = function(data) {
    var relationshipTypes = apiService.profile.filterTypes(_.get(data, 'data.feed.xlatvalues.values'), $scope.items);

    $scope.relationshipTypes = sortRelationshipTypes(relationshipTypes);
  };

  /**
   * Sort relationshipTypes array in ascending order by description (text
   * displayed in select element), while pushing options representing "Other
   * Relative" (`R`), and generic "Other" (`O`) to the end of the sorted array.
   * @return {Array} The sorted array of relationship types.
   */
  var sortRelationshipTypes = function(types) {
    var RE_RELATIONSHIP_OTHER = /^(O|R)$/;

    return types.sort(function(a, b) {
      var left = a.fieldvalue;
      var right = b.fieldvalue;

      if (RE_RELATIONSHIP_OTHER.test(left)) {
        return 1;
      } else if (RE_RELATIONSHIP_OTHER.test(right)) {
        return -1;
      } else {
        return a.xlatlongname > b.xlatlongname;
      }
    });
  };

  var getCountries = profileFactory.getCountries;

  var parseCountries = function(data) {
    $scope.countries = _.sortBy(_.filter(_.get(data, 'data.feed.countries'), {
      hasAddressFields: true
    }), 'descr');
  };

  var countryWatch = function(country) {
    if (!country) {
      return;
    }

    $scope.currentObject.whileAddressFieldsLoading = true;

    profileFactory.getAddressFields({
      country: country
    })
    .then(parseAddressFields)
    .then(function() {
      // Get the states for specified country (if available)
      return profileFactory.getStates({
        country: country
      });
    })
    .then(parseStates)
    .then(function() {
      $scope.currentObject.whileAddressFieldsLoading = false;
    });
  };

  var parseAddressFields = function(data) {
    $scope.currentObject.addressFields = _.get(data, 'data.feed.labels');
  };

  var parseStates = function(data) {
    $scope.states = _.sortBy(_.get(data, 'data.feed.states'), 'descr');
  };

  /**
   * We need to watch when the country changes, if so, load the address fields
   * dynamically depending on the country.
   */
  var countryWatcher;

  var startCountryWatcher = function() {
    countryWatcher = $scope.$watch('currentObject.data.country', countryWatch);
  };

  var loadInformation = function() {
    // If we were previously watching a country, we need to remove that
    if (countryWatcher) {
      countryWatcher();
    }

    getEmergencyContacts({
      refresh: true
    })
    .then(parseEmergencyContacts)
    .then(getTypesRelationship)
    .then(parseTypesRelationship)
    .then(getCountries)
    .then(parseCountries)
    .then(startCountryWatcher)
    .then(function() {
      $scope.isLoading = false;
    });
  };

  loadInformation();
});
