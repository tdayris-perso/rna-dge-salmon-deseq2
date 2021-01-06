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
CONDA_ACTIVATE   = source $$(conda info --base)/etc/profile.d/conda.sh && conda activate && conda activate

# Paths
TEST_CONFIG      = scripts/prepare_config.py
TEST_DESIGN      = scripts/prepare_design.py
TEST_COMMON      = rules/common_rna_dge_salmon_deseq2.py
SNAKE_FILE       = Snakefile
ENV_YAML         = envs/workflow.yaml
GTF_PATH         = '${PWD}/test/annotation.chr21.gtf'
READS_PATH       = '${PWD}/test/pseudo_mapping'

RUN_CONFIG       = ${PYTHON} rna-dge-salmon-deseq2.py config
RUN_DESIGN       = ${PYTHON} rna-dge-salmon-deseq2.py design
RUN_SKMAKE       = ${PYTHON} rna-dge-salmon-deseq2.py snakemake
RUN_REPORT       = ${PYTHON} rna-dge-salmon-deseq2.py report

# Arguments
ENV_NAME         = rna-dge-salmon-deseq2
SNAKE_THREADS    = 1
PYTEST_ARGS      = -vv

# Parameters
LIMMA_ARGS       = 'organism = "Hs", pca_ngenes=100, loadings_ngenes=90'
PCA_CORRS_ARGS   = 'pc=1'

# Recipes
default: all-unit-tests


# Installation
conda-install-flamingo:
	${CONDA_ACTIVATE} base && \
	${CONDA} env create --file ${ENV_FLAMINGO} --force && \
	${CONDA} activate ${ENV_NAME}
.PHONY: conda-tests


conda-install-local:
	${CONDA_ACTIVATE} base && \
	${CONDA} env create --file ${ENV_LOCAL} --force && \
	${CONDA} activate ${ENV_NAME}
.PHONY: conda-tests


# Environment building through conda
conda-tests:
	${CONDA_ACTIVATE} base && \
	${CONDA} env create --file ${ENV_YAML} --force && \
	${CONDA} activate ${ENV_NAME}
.PHONY: conda-tests


# Running script tests
all-unit-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_CONFIG} ${TEST_DESIGN} ${TEST_COMMON}
.PHONY: all-unit-tests


config-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_CONFIG} && \
	${RUN_CONFIG} test/${GTF_PATH} --output test/config.yaml
.PHONY: config-tests


design-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_DESIGN} && \
	${RUN_DESIGN} ${READS_PATH} --output test/design.tsv
.PHONY: design-tests


common-tests:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTEST} ${PYTEST_ARGS} ${TEST_COMMON}
.PHONY: common-tests


test-cli-wrapper-report.html:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	declare -x SNAKEMAKE_OUTPUT_CACHE="${PWD}/test/snakemake/cache" && \
	declare -x SNAKEFILE="${PWD}/Snakefile" && \
	declare -x PROFILE="${PWD}/.igr/profile/local" && \
	declare -x PREPARE_CONFIG="${PWD}/scripts/prepare_config.py" && \
	declare -x PREPARE_DESIGN="${PWD}/scripts/prepare_design.py" && \
	declare -x GTF="${PWD}/test/annotation.chr21.gtf" && \
	declare -x DGE_LAUNCHER="${PWD}/rna-dge-salmon-deseq2.py" && \
	export SNAKEMAKE_OUTPUT_CACHE SNAKEFILE PROFILE PREPARE_CONFIG PREPARE_DESIGN GTF DGE_LAUNCHER && \
	mkdir -p "test/snakemake/cache" && \
	${RUN_CONFIG} ${GTF_PATH}  --models 'Condition,C1,C2,~Nest*Condition' 'Nest,N1,N2,~Nest*Condition' --output ${PWD}/test/config.yaml --debug --design ${PWD}/test/design.tsv --pcaexplorer-limmaquickpca2go-extra ${LIMMA_ARGS} --pcaexplorer-pcacorrs-extra ${PCA_CORRS_ARGS} && \
	${RUN_DESIGN} ${READS_PATH} --output ${PWD}/test/design.tsv --debug --import design.tsv && \
	${RUN_SKMAKE} --snakemake-args "--configfile ${PWD}/test/config.yaml --directory test" && \
	${RUN_REPORT} --snakemake-args "--configfile ${PWD}/test/config.yaml --directory test"
	#${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml && \
	#${SNAKEMAKE} -s ${SNAKE_FILE} --report test-conda-report.html --config "report=True" --directory ${PWD}/test --forceall --printshellcmds --reason --use-conda -j ${SNAKE_THREADS} --configfile ${PWD}/test/config.yaml


clean:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml --delete-all-output
.PHONY: clean



# Display pipeline graph
workflow.png:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTHON} ${TEST_CONFIG} ${GTF_PATH} --output ${PWD}/test/config.yaml --debug --design ${PWD}/test/design.tsv --pcaexplorer-limmaquickpca2go-extra ${LIMMA_ARGS} --pcaexplorer-pcacorrs-extra ${PCA_CORRS_ARGS} && \
	${PYTHON} ${TEST_DESIGN} ${READS_PATH} --output ${PWD}/test/design.tsv --debug --import design.tsv && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml --rulegraph | dot -T png > workflow.png

example.png:
	${CONDA_ACTIVATE} ${ENV_NAME} && \
	${PYTHON} ${TEST_CONFIG} ${GTF_PATH} --output ${PWD}/test/config.yaml --debug --design ${PWD}/test/design.tsv --pcaexplorer-limmaquickpca2go-extra ${LIMMA_ARGS} --pcaexplorer-pcacorrs-extra ${PCA_CORRS_ARGS} && \
	${PYTHON} ${TEST_DESIGN} ${READS_PATH} --output ${PWD}/test/design.tsv --debug --import design.tsv && \
	${SNAKEMAKE} -s ${SNAKE_FILE} --use-conda -j ${SNAKE_THREADS} --printshellcmds --reason --forceall --directory ${PWD}/test --configfile ${PWD}/test/config.yaml --dag | dot -T png > example.png
