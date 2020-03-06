#!/bin/bash

# This script only copies design to the rna-count-salmon working directory
# While this could be done by user, I expect possible further controls and
# processes to be added in future.


# This function will take error messages and exit the program
function error_handling() {
  # Geathering input parameter (message, third parameter is optionnal)
  echo -ne "\n"
  local parent_lineno="$1"
  local code="$2"
  local message="${3:-1}"

  # Checking the presence or absence of message
  if [[ -n "$message" ]] ; then
    # Case message is present
    message ERROR "Error on or near line ${parent_lineno}:\n ${message}"
    message ERROR "Exiting with status ${code}"
  else
    # Case message is not present
    message ERROR "Error on or near line ${parent_lineno}"
    message ERROR "Exiting with status ${code}"
  fi

  # Exiting with given error code
  exit "${code}"
}


# This function only changes echo headers
# for user's sake.
function message() {
  # Define local variables
  local status=${1}         # Either INFO, CMD, ERROR or DOC
  local message="${2:-1}"   # Your message

  # Classic switch based on status
  if [ ${status} = INFO ]; then
    echo -e "\033[1;36m@INFO:\033[0m ${message}"
  elif [ ${status} = CMD ]; then
    echo -e "\033[1;32m@CMD:\033[0m ${message}"
  elif [ ${status} = ERROR ]; then
    echo -e "\033[41m@ERROR:\033[0m ${message}"
  elif [ ${status} = DOC ]; then
    echo -e "\033[0;33m@DOC:\033[0m ${message}"
  else
    error_handling ${LINENO} 1 "Unknown message type"
  fi
}

function help_message() {
  message DOC "This script deploys both configuration and design files"
  message DOC "into the subworkflow's working directory."
  echo ""
  message DOC "-d | --design        Path to design file (default: design.tsv)"
  message DOC "-c | --config        Path to config file (default: config.yaml)"
  message DOC "-r | --rna_count_wd  Path to rna-count-salmon working directory"
  message DOC "                     (default: rna-count-salmon-results)"
  message DOC "-h | --help          Print this help message, then exit."
  echo ""
  message DOC "Error status:"
  message DOC "1 = Command line error"
  message DOC "2 = Input file(s) not found"
  message DOC "3 = Copy error"
  echo ""
  message DOC "Example:"
  message DOC "bash scripts/deploy_design.sh"
  echo ""
  message DOC "bash scripts/deploy_design.sh -d /path/to/design \\"
  message DOC "                              -c /path/to/config \\"
  message DOC "                              -r /path/to/workdir"
}


function copy_file() {
  local SOURCE="${1}"
  local DEST="${2}"

  if [ -f "${SOURCE}" ]; then
    message INFO "Soft linking ${SOURCE} to ${DEST}"
    message CMD "cp--symbolic-link  --verbose ${SOURCE} ${DEST}"
    cp --symbolic-link --force --verbose "${SOURCE}" "${DEST}" || error_handling ${LINENO} 3 "Could not link ${SOURCE}"
  else
    error_handling ${LINENO} 2 "Could not find ${SOURCE}"
  fi
}


# VARS:
DESIGN="design.tsv"
CONFIG="config.yaml"
RNACOUNTWD="rna-count-salmon-results"


# Parse command line
while [[ "$#" -gt 0 ]]; do
  case "${1}" in
    -d|--design) DESIGN="${2}"; shift 2;;
    -c|--config) CONFIG="${2}"; shift 2;;
    -r|--rna_count_wd) RNACOUNTWD="${2}"; shift 2;;
    -h|--help) help_message; exit 1;;
    *) error_handling ${LINENO} 1 "Unknown arguments ${1}"; exit 1;;
  esac
done


if [ ! -d "${RNACOUNTWD}" ]; then
  message INFO "Missing output directory, it shall be created:"
  message CMD "mkdir --verbose --parents ${RNACOUNTWD}"
  mkdir --verbose --parents "${RNACOUNTWD}"
fi

CONFIG=$(realpath "${CONFIG}")
DESIGN=$(realpath "${DESIGN}")
RNACOUNTWD=$(realpath "${RNACOUNTWD}")

copy_file "${CONFIG}" "${RNACOUNTWD}"
copy_file "${DESIGN}" "${RNACOUNTWD}"
