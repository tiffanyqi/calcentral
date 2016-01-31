#!/bin/sh

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

validate_api_response() {
  # Grep file for known error types (see below)
  local path_to_file="${1}"
  local url="${2}"
  if [[ ! -f "${path_to_file}" ]] ; then
    echo "      [ERROR] File not found: ${path_to_file}"
    echo "               Absolute URL: ${url}"
  else
    error_count=$(grep -i 'error\|unable to find a routing\|not authorized\|no service was found' ${path_to_file} | wc -l)
    if [ "${error_count}" -ne "0" ]; then
      echo "      [WARN] Errors found in ${path_to_file}"
      echo "             Absolute URL: ${url}"
      cat "${path_to_file}"; echo
    fi
  fi
}

report_response_code() {
  # Report error per HTTP Response code
  local api_path="${1}"
  local http_code="${2}"
  local url="${3}"
  if [[ ("${http_code}" -lt "200") || ("${http_code}" -ge "400") ]] ; then
    echo "    ${api_path} --> [ERROR] HTTP status code: ${http_code}"
    echo "      Absolute URL: ${url}"
  else
    echo "    ${api_path} --> ${http_code}"
  fi
}
