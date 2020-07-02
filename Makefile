SHELL := bash
.ONESHELL:
.SHELLFLAGS := -euic
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

### Variables ###
# Tools
PYTEST           = pytest
BASH             = bash
CONDA            = conda
PYTHON           = python3.8
SNAKEMAKE        = snakemake
CONDA_ACTIVATE   = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate

# Paths
TEST_CONFIG      = scripts/prepare_config.py
TEST_DESIGN      = scripts/prepare_design.py
SNAKE_FILE       = Snakefile
ENV_YAML         = envs/workflow.yaml
GTF_PATH         = '${PWD}/test/annotation.chr21.gtf'
READS_PATH       = '${PWD}/test/pseudo_mapping'

# Arguments
ENV_NAME         = rna-dge-salmon-deseq2
SNAKE_THREADS    = 1
PYTEST_ARGS      = -vv

# Parameters
LIMMA_ARGS       = 'organism = "Hs", pca_ngenes=100, loadings_ngenes=90'
PCA_CORRS_ARGS   = 'pc=1'
# Recipes
default: all-unit-tests


all-unit-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_CONFIG} ${TEST_DESIGN}
.PHONY: all-unit-tests


# Environment building through conda
conda-tests:
	${CONDA_ACTIVATE} base && \
	${CONDA} env create --file ${ENV_YAML} --force && \
	${CONDA} activate ${ENV_NAME}
.PHONY: conda-tests


# Running tests on configuration only
config-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_CONFIG} && \
	${PYTHON} ${TEST_CONFIG} test/${GTF_PATH} --output test/config.yaml
.PHONY: config-tests


design-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_DESIGN} && \
	${PYTHON} ${TEST_DESIGN} test/${READS_PATH} --output test/design.tsv
.PHONY: design-tests

test-conda-report.html:
	${CONDA_ACTIVATE} ${ENV_NAME} &&
	${PYTHON} ${TEST_CONFIG} ${GTF_PATH} --output ${PWD}/test/config.yaml --debug --design ${PWD}/test/design.tsv --pcaexplorer-limmaquickpca2go-extra ${LIMMA_ARGS} --pcaexplorer-pcacorrs-extra ${PCA_CORRS_ARGS} && \
	${PYTHON} ${TEST_DESIGN} ${READS_PATH} --output ${PWD}/test/design.tsv --debug --import design.tsv && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --report test-conda-report.html --directory ${PWD}/test --forceall --printshellcmds --reason --use-conda -j ${SNAKE_THREADS}



# Display pipeline graph
workflow.png:
	${CONDA_ACTIVATE} ${ENV_NAME} &&
	${PYTHON} ${TEST_CONFIG} ${GTF_PATH} --output ${PWD}/test/config.yaml --debug --design ${PWD}/test/design.tsv --pcaexplorer-limmaquickpca2go-extra ${LIMMA_ARGS} --pcaexplorer-pcacorrs-extra ${PCA_CORRS_ARGS} && \
	${PYTHON} ${TEST_DESIGN} ${READS_PATH} --output ${PWD}/test/design.tsv --debug --import design.tsv && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml --rulegraph | dot -T png > workflow.png

example.png:
	${CONDA_ACTIVATE} ${ENV_NAME} &&
	${PYTHON} ${TEST_CONFIG} ${GTF_PATH} --output ${PWD}/test/config.yaml --debug --design ${PWD}/test/design.tsv --pcaexplorer-limmaquickpca2go-extra ${LIMMA_ARGS} --pcaexplorer-pcacorrs-extra ${PCA_CORRS_ARGS} && \
	${PYTHON} ${TEST_DESIGN} ${READS_PATH} --output ${PWD}/test/design.tsv --debug --import design.tsv && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml --dag | dot -T png > example.png
