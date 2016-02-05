#!/bin/bash

# cd to 'calcentral' directory
cd $( dirname "${BASH_SOURCE[0]}" )/../..

LOG_RELATIVE_PATH="log/sis_api_test_$(date +"%Y-%m-%d_%H%M%S")"
LOG_DIRECTORY="${PWD}/${LOG_RELATIVE_PATH}"

# Include utility
. "${PWD}/script/sis/sis_script_utils.sh"

# --------------------
# Verify API endpoints: Crosswalk, Campus Solutions, Hub
# https://jira.ets.berkeley.edu/jira/browse/CLC-6123
# --------------------

if [[ $# -eq 0 ]] ; then
  echo; echo "USAGE"; echo "    ${0} [Path to YAML file]"; echo
  exit 0
fi

# Load YAML file
yaml_filename="${1}"

if [[ ! -f "${yaml_filename}" ]] ; then
  echo; echo "ERROR"; echo "    YAML file not found: ${yaml_filename}"; echo
  exit 0
fi

eval $(parse_yaml ${yaml_filename} 'yml_')

# --------------------
UID_CROSSWALK=1022796
SID=11667051
CAMPUS_SOLUTIONS_ID=3030556855

echo "DESCRIPTION"
echo "    Verify API endpoints: Crosswalk, Campus Solutions, Hub"; echo

echo "OUTPUT"
echo "    Directory: ${LOG_RELATIVE_PATH}"; echo

echo "--------------------"
echo "VERIFY: CROSSWALK API"; echo
mkdir -p "${LOG_DIRECTORY}/calnet_crosswalk"

API_CALLS=(
  "/CAMPUS_SOLUTIONS_ID/${CAMPUS_SOLUTIONS_ID}"
  "/LEGACY_SIS_STUDENT_ID/${SID}"
  "/UID/${UID_CROSSWALK}"
)

for path in ${API_CALLS[@]}; do
  log_file="${LOG_DIRECTORY}/calnet_crosswalk/${path//\//_}.log"
  url="${yml_calnet_crosswalk_proxy_base_url//\'}${path}"
  http_code=$(curl -k -w "%{http_code}\n" \
    -so "${log_file}" \
    --digest \
    -u "${yml_calnet_crosswalk_proxy_username//\'}:${yml_calnet_crosswalk_proxy_password//\'}" \
    "${url}")
  validate_api_response "${log_file}" "${url}"
  report_response_code "${path}" "${http_code}" "${url}"
done

echo "--------------------"
echo "VERIFY: CAMPUS SOLUTIONS API"; echo
mkdir -p "${LOG_DIRECTORY}/campus_solutions"


API_CALLS=(
  # GoLive 4: cs_profile
  "/UC_CC_ADDR_LBL.v1/get?COUNTRY=ESP"
  "/UC_CC_ADDR_TYPE.v1/getAddressTypes/"
  "/UC_COUNTRY.v1/country/get"
  "/UC_CC_CURRENCY_CD.v1/Currency_Cd/Get"
  "/UC_CC_SS_ETH_SETUP.v1/GetEthnicitytype/"
  "/UC_CC_SERVC_IND.v1/Servc_ind/Get?/EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_CC_LANGUAGES.v1/get/languages/"
  "/UC_CC_NAME_TYPE.v1/getNameTypes/"
  "/UC_CC_COMM_PEND_MSG.v1/get/pendmsg?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_SIR_CONFIG.v1/get/sir/config/?INSTITUTION=UCB01"
  "/UC_STATE_GET.v1/state/get/?COUNTRY=ESP"
  "/UC_CM_XLAT_VALUES.v1/GetXlats?FIELDNAME=PHONE_TYPE"

  # GoLive 4: cs_sir
  "/UC_CC_CHECKLIST.v1/get/checklist?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_DEPOSIT_AMT.v1/deposit/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&ADM_APPL_NBR=00000087"
  "/UC_OB_HIGHER_ONE_URL_GET.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}"

  # GoLive 4: show_notifications_archive_link
  "/UC_CC_COMM_DB_URL.v1/dashboard/url/"

  # GoLive 5: CalCentral code might not have these URLs; they are used by the Hub to query Campus Solutions.
  "/UcEmailAddressesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_PER_ADDR_GET.v1/person/address/get?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcSccAflPersonRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcPersPhonesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcIdentifiersRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcNamesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcApiEmergencyContactGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcCitizenshpIRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcUrlRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcEthnicityIGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcGenderRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcMilitaryStatusRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcPassportsRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcLanguagesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcVisasRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_PERSON_DOB_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcConftlStdntRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_CC_WORK_EXPERIENCES_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UcPersonsFullLoadRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_CC_STDNT_DEMOGRAPHIC_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_CC_STDNT_CONTACTS_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_SR_STDNT_REGSTRTN_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_CC_INTERNTNL_STDNTS_R.v1/Students?EMPLID=${CAMPUS_SOLUTIONS_ID}"
  "/UC_CM_UID_CROSSWALK.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}"
)

if [ "${yml_features_cs_fin_aid}" == "true" ] ; then
  API_CALLS+=("/UC_FA_FINANCIAL_AID_DATA.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01&AID_YEAR=2015")
  API_CALLS+=("/UC_FA_FUNDING_SOURCES.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01&AID_YEAR=2015")
  API_CALLS+=("/UC_FA_FUNDING_SOURCES_TERM.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01&AID_YEAR=2015")
  API_CALLS+=("/UC_FA_GET_T_C.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01")
fi

#if [ "${yml_features_cs_profile_emergency_contacts}" == "true" ] ; then
#  # -> PostingProxy only
#fi

if [ "${yml_features_cs_delegated_access}" == "true" ] ; then
  API_CALLS+=("/UC_CC_DELEGATED_ACCESS.v1/DelegatedAccess/get?SCC_DA_PRXY_OPRID=${UID_CROSSWALK}")
  API_CALLS+=("/UC_CC_DELEGATED_ACCESS_URL.v1/get")
fi

if [ "${yml_features_cs_enrollment_card}" == "true" ] ; then
  API_CALLS+=("/UC_SR_CURR_TERMS.v1/GetCurrentItems?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  API_CALLS+=("/UC_SR_STDNT_CLASS_ENROLL.v1/Get?EMPLID=${CAMPUS_SOLUTIONS_ID}&STRM=2168")
  API_CALLS+=("/UC_SR_ACADEMIC_PLAN.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&STRM=2168")
  API_CALLS+=("/UC_SR_COLLEGE_SCHDLR_URL.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&STRM=2168&ACAD_CAREER=UGRD&INSTITUTION=UCB01")
fi

for path in ${API_CALLS[@]}; do
  log_file="${LOG_DIRECTORY}/campus_solutions/${path//\//_}.log"
  url="${yml_campus_solutions_proxy_base_url//\'}${path}"
  http_code=$(curl -k -w "%{http_code}\n" \
    -so "${log_file}" \
    -u "${yml_campus_solutions_proxy_username//\'}:${yml_campus_solutions_proxy_password//\'}" \
    "${url}")
  validate_api_response "${log_file}" "${url}"
  report_response_code "${path}" "${http_code}" "${url}"
done

echo "--------------------"
echo "VERIFY: HUB API"; echo
mkdir -p "${LOG_DIRECTORY}/hub_edos"

API_CALLS=(
  "/${CAMPUS_SOLUTIONS_ID}/affiliation"
  "/${CAMPUS_SOLUTIONS_ID}/contacts"
  "/${CAMPUS_SOLUTIONS_ID}/demographic"
  "/${CAMPUS_SOLUTIONS_ID}/all"
  "/${CAMPUS_SOLUTIONS_ID}/work-experiences"
)

for path in ${API_CALLS[@]}; do
  log_file="${LOG_DIRECTORY}/hub_edos/${path//\//_}.log"
  url="${yml_hub_edos_proxy_base_url//\'}${path}"
  http_code=$(curl -k -w "%{http_code}\n" \
    -so "${log_file}" \
    -H "Accept:application/json" \
    -u "${yml_hub_edos_proxy_username//\'}:${yml_hub_edos_proxy_password//\'}" \
    --header "app_id: ${yml_hub_edos_proxy_app_id//\'}" \
    --header "app_key: ${yml_hub_edos_proxy_app_key//\'}" \
    "${url}")
  validate_api_response "${log_file}" "${url}"
  report_response_code "${path}" "${http_code}" "${url}"
done

echo; echo "--------------------"; echo
echo "DONE"
echo "    Results can be found in the directory: ${LOG_RELATIVE_PATH}"
echo; echo

exit 0
