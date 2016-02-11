#!/bin/bash

parse_yaml() {
  # --------------------------------------------
  # Read YAML file from Bash script and other utilities.
  # See sample usage at https://gist.github.com/pkuczynski/8665367
  # --------------------------------------------
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
       vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
       printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
  }'
}

report_success() {
  local api_path="${1}"
  local http_code="${2}"
  echo "  [INFO] ${api_path} --> ${http_code}"
}

report_error() {
  local api_path="${1}"
  local http_code="${2}"
  local url="${3}"
  local path_to_file="${4}"
  echo; echo
  echo "  [ERROR]"
  echo "    API Endpoint: ${api_path}"
  echo "    HTTP status: ${http_code}"
  echo "    Log: log/${path_to_file#*/log}"
  echo "    URL: ${url}"
  echo
}

validate_api_response() {
  # Report error per HTTP Response code
  local api_path="${1}"
  local http_code="${2}"
  local url="${3}"
  local path_to_file="${4}"
  if [[ ("${http_code}" -lt "200") || ("${http_code}" -ge "400") ]] ; then
    report_error $@
  elif [[ ! -f "${path_to_file}" ]] ; then
    report_error $@
  else
    error_count=$(grep -i 'error\|unable to find a routing\|not authorized\|no service was found' ${path_to_file} | wc -l)
    if [ "${error_count}" -ne "0" ]; then
      report_error $@
    else
      report_success $@
    fi
  fi
}

# cd to 'calcentral' directory
cd $( dirname "${BASH_SOURCE[0]}" )/../..

LOG_RELATIVE_PATH="log/sis_api_test_$(date +"%Y-%m-%d_%H%M%S")"
LOG_DIRECTORY="${PWD}/${LOG_RELATIVE_PATH}"

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
UID_CROSSWALK=${UID_CROSSWALK:-1022796}
SID=${SID:-11667051}
CAMPUS_SOLUTIONS_ID=${CAMPUS_SOLUTIONS_ID:-24188949}

CROSSWALK_BASE_URL="${yml_calnet_crosswalk_proxy_base_url//\'}"
CROSSWALK_CREDENTIALS="${yml_calnet_crosswalk_proxy_username//\'}:${yml_calnet_crosswalk_proxy_password//\'}"

CS_BASE_URL="${yml_campus_solutions_proxy_base_url//\'}"
CS_CREDENTIALS="${yml_campus_solutions_proxy_username//\'}:${yml_campus_solutions_proxy_password//\'}"

HUB_BASE_URL="${yml_hub_edos_proxy_base_url//\'}"
HUB_CREDENTIALS="${yml_hub_edos_proxy_username//\'}:${yml_hub_edos_proxy_password//\'}"
HUB_APP_ID="${yml_hub_edos_proxy_app_id//\'}"
HUB_APP_KEY="${yml_hub_edos_proxy_app_key//\'}"

# Feature flags
[ "${yml_features_cs_fin_aid}" == "true" ] ; CS_FIN_AID=$?
[ "${yml_features_cs_delegated_access}" == "true" ] ; CS_DELEGATED_ACCESS=$?
[ "${yml_features_cs_enrollment_card}" == "true" ] ; CS_ENROLLMENT_CARD=$?
[ "${yml_features_cs_profile_emergency_contacts}" == "true" ] ; CS_PROFILE_EMERGENCY_CONTACTS=$?

# --------------------

echo "DESCRIPTION"
echo "    Verify API endpoints: Crosswalk, Campus Solutions, Hub"; echo

echo "OUTPUT"
echo "    Directory: ${LOG_RELATIVE_PATH}"; echo

echo "----------------------------------------------------------------------------------------------------"
echo "SIS ENVIRONMENTS"; echo
echo "  Campus Solutions: ${CS_BASE_URL}"
echo "  Crosswalk: ${CROSSWALK_BASE_URL}"
echo "  Hub: ${HUB_BASE_URL}"
echo
echo "----------------------------------------------------------------------------------------------------"
echo "FEATURE FLAGS (ONLY THE RELEVANT)"; echo
echo "  cs_fin_aid=${CS_FIN_AID}"
echo "  cs_delegated_access=${CS_DELEGATED_ACCESS}"
echo "  cs_enrollment_card=${CS_ENROLLMENT_CARD}"
echo "  cs_profile_emergency_contacts=${CS_PROFILE_EMERGENCY_CONTACTS}"
echo
echo "----------------------------------------------------------------------------------------------------"
echo "VERIFY: CROSSWALK API"; echo
mkdir -p "${LOG_DIRECTORY}/calnet_crosswalk"

CROSSWALK_ENDPOINTS=(
  "/CAMPUS_SOLUTIONS_ID/${CAMPUS_SOLUTIONS_ID}"
  "/LEGACY_SIS_STUDENT_ID/${SID}"
  "/UID/${UID_CROSSWALK}"
)

for path in ${CROSSWALK_ENDPOINTS[@]}; do
  log_file="${LOG_DIRECTORY}/calnet_crosswalk/${path//\//_}.log"
  url="${CROSSWALK_BASE_URL}${path}"
  http_code=$(curl -k -w "%{http_code}\n" -so "${log_file}" --digest -u "${CROSSWALK_CREDENTIALS}" "${url}")
  validate_api_response "${path}" "${http_code}" "${url}" "${log_file}"
done

echo; echo "----------------------------------------------------------------------------------------------------"
echo "VERIFY: CAMPUS SOLUTIONS API"; echo
mkdir -p "${LOG_DIRECTORY}/campus_solutions"

CS_ENDPOINTS=(
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
  "/UC_DEPOSIT_AMT.v1/deposit/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&ADM_APPL_NBR=00000087"
  "/UC_OB_HIGHER_ONE_URL_GET.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}"

  # GoLive 4: show_notifications_archive_link
  "/UC_CC_COMM_DB_URL.v1/dashboard/url/"

  # GoLive 5: advising resources
  "/UC_AA_ADVISING_RESOURCES.v1/UC_ADVISING_RESOURCES?EMPLID=${CAMPUS_SOLUTIONS_ID}"
)

if [[ "${CS_BASE_URL}" == *"dev"* ]] ; then
  # --------------------------------------------
  # These endpoints are used by the Hub when proxying to Campus Solutions. You won't find them referenced in
  # CalCentral code. We only verify these endpoints in dev because they are more restricted in QAT and PROD.
  # --------------------------------------------
  CS_ENDPOINTS+=("/UcEmailAddressesRGet.v1/?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_PER_ADDR_GET.v1/person/address/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcSccAflPersonRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcPersPhonesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcIdentifiersRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcNamesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcApiEmergencyContactGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcCitizenshpIRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcUrlRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcEthnicityIGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcGenderRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcMilitaryStatusRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcPassportsRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcLanguagesRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcVisasRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_PERSON_DOB_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcConftlStdntRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_CC_WORK_EXPERIENCES_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UcPersonsFullLoadRGet.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_CC_STDNT_DEMOGRAPHIC_R.v1/?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_CC_STDNT_CONTACTS_R.v1?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_SR_STDNT_REGSTRTN_R.v1/?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_CC_INTERNTNL_STDNTS_R.v1/Students/?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_CM_UID_CROSSWALK.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}")
fi

if [ ${CS_FIN_AID} == 0 ] ; then
  CS_ENDPOINTS+=("/UC_FA_FINANCIAL_AID_DATA.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01&AID_YEAR=2016")
  CS_ENDPOINTS+=("/UC_FA_FUNDING_SOURCES.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01&AID_YEAR=2016")
  CS_ENDPOINTS+=("/UC_FA_FUNDING_SOURCES_TERM.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01&AID_YEAR=2016")
  CS_ENDPOINTS+=("/UC_FA_GET_T_C.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&INSTITUTION=UCB01")
fi

if [ ${CS_DELEGATED_ACCESS} == 0 ] ; then
  CS_ENDPOINTS+=("/UC_CC_DELEGATED_ACCESS.v1/DelegatedAccess/get?SCC_DA_PRXY_OPRID=${UID_CROSSWALK}")
  CS_ENDPOINTS+=("/UC_CC_DELEGATED_ACCESS_URL.v1/get")
fi

if [ ${CS_ENROLLMENT_CARD} == 0 ] ; then
  CS_ENDPOINTS+=("/UC_SR_CURR_TERMS.v1/GetCurrentItems?EMPLID=${CAMPUS_SOLUTIONS_ID}")
  CS_ENDPOINTS+=("/UC_SR_STDNT_CLASS_ENROLL.v1/get?EMPLID=${CAMPUS_SOLUTIONS_ID}&STRM=2168")
  CS_ENDPOINTS+=("/UC_SR_ACADEMIC_PLAN.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&STRM=2168")
  CS_ENDPOINTS+=("/UC_SR_COLLEGE_SCHDLR_URL.v1/get/?EMPLID=${CAMPUS_SOLUTIONS_ID}&STRM=2168&ACAD_CAREER=UGRD&INSTITUTION=UCB01")
fi

if [ ${CS_PROFILE_EMERGENCY_CONTACTS} == 0 ] ; then
  echo "  [INFO] No API endpoints associated with cs_profile_emergency_contacts feature flag"
fi

for path in ${CS_ENDPOINTS[@]}; do
  log_file="${LOG_DIRECTORY}/campus_solutions/${path//\//_}.log"
  url="${CS_BASE_URL}${path}"
  http_code=$(curl -k -w "%{http_code}\n" -so "${log_file}" -u "${CS_CREDENTIALS}" "${url}")
  validate_api_response "${path}" "${http_code}" "${url}" "${log_file}"
done

echo; echo "----------------------------------------------------------------------------------------------------"
echo "VERIFY: HUB API"; echo
mkdir -p "${LOG_DIRECTORY}/hub_edos"

HUB_ENDPOINTS=(
  "/${CAMPUS_SOLUTIONS_ID}/affiliation"
  "/${CAMPUS_SOLUTIONS_ID}/contacts"
  "/${CAMPUS_SOLUTIONS_ID}/demographic"
  "/${CAMPUS_SOLUTIONS_ID}/all"
  "/${CAMPUS_SOLUTIONS_ID}/work-experiences"
  "/${CAMPUS_SOLUTIONS_ID}?id-type=uid"
)

for path in ${HUB_ENDPOINTS[@]}; do
  log_file="${LOG_DIRECTORY}/hub_edos/${path//\//_}.log"
  url="${HUB_BASE_URL}${path}"
  http_code=$(curl -k -w "%{http_code}\n" -so "${log_file}" -H "Accept:application/json" -u "${HUB_CREDENTIALS}" --header "app_id: ${HUB_APP_ID}" --header "app_key: ${HUB_APP_KEY}" "${url}")
  validate_api_response "${path}" "${http_code}" "${url}" "${log_file}"
done

echo; echo "----------------------------------------------------------------------------------------------------"; echo
echo "DONE"; echo "    Results can be found in the directory: ${LOG_RELATIVE_PATH}"; echo; echo

exit 0
