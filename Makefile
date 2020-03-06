SHELL := bash
.ONESHELL:
.SHELLFLAGS := -euio pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

### Variables ###
# Tools
PYTEST           = pytest
BASH             = bash
CONDA            = conda
PYTHON           = python3.7
SNAKEMAKE        = snakemake
CONDA_ACTIVATE   = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate

# Paths
TEST_CONFIG      = scripts/prepare_configs.py
TEST_DESIGN      = scripts/prepare_designs.py
SNAKE_FILE       = Snakefile
ENV_YAML         = envs/workflow.yaml
TRANSCRIPT_PATH  = rna-count-salmon/tests/genomes/transcriptome.fasta
GTF_PATH         = rna-count-salmon/tests/genomes/transcriptome.gtf
READS_PATH       = rna-count-salmon/tests/reads/

# Arguments
ENV_NAME         = rna-dge-salmon-deseq2
SNAKE_THREADS    = 1
SAINDEX_ARGS     = ' --kmerLen 5 '
SAQUANT_ARGS     = ' --noBiasLengthThreshold --minAssignedFrags 1 --noEffectiveLengthCorrection --noLengthCorrection --fasterMapping --noFragLengthDist --allowDovetail --numPreAuxModelSamples 0 --numAuxModelSamples 0 '
FORMULAS         = ' \\~1 '
PYTEST_ARGS      = -vv

# Recipes
default: all-unit-tests


# Environment building through conda
conda-tests:
	${CONDA_ACTIVATE} base && \
	${CONDA} env create --file ${ENV_YAML} --force && \
	${CONDA} activate ${ENV_NAME}


# Running tests on configuration only
config-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_CONFIG} && \
	${PYTHON} $(TEST_CONFIG) ${TRANSCRIPT_PATH} --salmon-index-extra ${SAINDEX_ARGS} --salmon-quant-extra ${SAQUANT_ARGS} --aggregate --libType "ISF" --workdir tests --debug


test-conda-report.html:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason
	${SNAKEMAKE}  -s ${SNAKE_FILE} --report test-conda-report.html



# Display pipeline graph
workflow.png:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --force --configfile ${PWD}/tests/config.yaml --directory ${PWD}/tests --rulegraph | dot -T png > workflow.png

example.png:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --force --configfile ${PWD}/tests/config.yaml --directory ${PWD}/tests --dag | dot -T png > example.png
