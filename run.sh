#!/bin/bash
set -eu

# This function only changes echo headers
# for user's sake.
function message() {
  # Define local variables
  local status=${1}         # Either INFO, CMD, ERROR or DOC
  local message="${2:-1}"   # Your message

  # Classic switch based on status
  if [ ${status} = INFO ]; then
    echo -e "\033[1;36m@INFO:\033[0m ${message}"
  elif [ ${status} = ERROR ]; then
    echo -e "\033[41m@ERROR:\033[0m ${message}"
  elif [ ${status} = DOC ]; then
    echo -e "\033[0;33m@DOC:\033[0m ${message}"
  else
    error_handling ${LINENO} 1 "Unknown message type"
  fi
}

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

function help_message() {
  message DOC "Hi, thanks for using me as your script for running "
  message DOC "rna-dge-salmon-deseq2 I'm very proud to be your script today,"
  message DOC "and I hope you'll enjoy working with me."
  echo ""
  message DOC "Please note that I am only intended to run on IGR's Flamingo."
  message DOC "If you are not currently on IGR's Flamingo, please follow "
  message DOC "manual instructions on Github's wiki pages."
  echo ""
  message DOC "Every time you'll see a line starting with '@', "
  message DOC "it will be because I speak."
  message DOC "In fact, I always start my speech with :"
  message DOC "'\033[0;33m@DOC:\033[0m' when i't about my functions,"
  message DOC "'\033[1;36m@INFO:\033[0m' when it's about my intentions, "
  message DOC "'\033[41m@ERROR:\033[0m', when I tell you weather things went wrong."
  echo ""
  message DOC "I understand very fiew things, and here they are:"
  message DOC "-h | --help        Print this help message, then exit."
  message DOC "-i | --exp-design  Path to TSV-formatted experimental-design."
  message DOC "                   default: exp-design.tsv"
  message DOC "-m | --models      Four values, separated by commas:"
  message DOC "                   (1) = the name of a column in the design."
  message DOC "                   (2) = the tested confition."
  message DOC "                   (3) = the reference condition."
  message DOC "                   (4) = the R formula"
  message DOC "                   Default: 'Condtion,B,A,~Condition'"
  message DOC "-s | --salmon      Path to salmon quantification directory"
  message DOC "                   default: ${PWD}"
  message DOC "Otherwise, run me without any arguments and I'll do magic."
  echo ""
  message DOC "A typical command line would be:"
  message DOC "bash /path/to/run.sh"
  exit 0
}

DESIGN_PATH="exp-design.tsv"
MODELS='Condtion,B,A,~Condition'
QUANT_DIR="${PWD}"
CONDA_YAML="/mnt/beegfs/pipelines/rna-dge-salmon-deseq2/pipeline/rna-dge-salmon-deseq2/envs/workflow_flamingo.yaml"

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -h|--help)
    help_message
    ;;
    -i|--exp-design)
    DESIGN_PATH="${2}"
    shift 2
    ;;
    -m|--models)
    MODELS="${2}"
    shift 2
    ;;
    -s|--salmon)
    QUANT_DIR="${2}"
    shift 2
    ;;
    *)
    error_handling ${LINENO} 1 "Unknown argument ${1}"
    shift
    ;;
  esac
done

# Loading conda
message INFO "Sourcing conda for users who did not source it before."
source "$(conda info --base)/etc/profile.d/conda.sh" && conda activate || exit error_handling "${LINENO}" 1 "Could not source conda environment."

# Install conda environment if not installed before
message INFO "Installing environment if and only if this action is needed."
$(conda info --envs | grep "rna-dge-salmon-deseq2" > "/dev/null" && conda compare -n rna-dge-salmon-deseq2 "${CONDA_YAML}") &&  message INFO "Pipeline already installed! What a chance!" || conda env create --force -f "${CONDA_YAML}"

# Check on environment variables: if env are missing
message INFO "Loading 'rna-dge-salmon-deseq2' environment"
conda activate rna-dge-salmon-deseq2 || error_handling "${LINENO}" 2 "Could not activate the environment 'rna-dge-salmon-deseq2'."

# then installation process did not work properly
echo INFO "Running pipeline if and only if it is possible"
$(export -p | grep "DGE_LAUNCHER" --quiet) && python3 ${DGE_LAUNCHER} flamingo --experimental-design "${DESIGN_PATH}" --salmon-dir "${QUANT_DIR}" --models-to-analyse ${MODELS} || error_handling ${LINENO} 3 "Could not locate rna-dge-salmon-deseq2 launcher at: ${DGE_LAUNCHER}"
