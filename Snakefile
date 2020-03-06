import snakemake.utils  # Load snakemake API
import sys              # System related operations

# Python 3.7 is required
if sys.version_info < (3, 7):
    raise SystemError("Please use Python 3.7 or later.")

# Snakemake 5.10.0 at least is required
snakemake.utils.min_version("5.10.0")

# include: "rna-count-salmon/rules/common.smk"
# include: "rna-count-salmon/rules/copy.smk"
# include: "rna-count-salmon/rules/fastqc.smk"
# include: "rna-count-salmon/rules/multiqc.smk"
# include: "rna-count-salmon/rules/salmon.smk"
# include: "rna-count-salmon/rules/aggregation.smk"

# workdir: config["workdir"]
# singularity: config["singularity_docker_image"]
# localrules: copy_fastq, copy_extra

include: "rules/common.smk"
include: "rules/rna-count-salmon.smk"
include: "rules/tximport.smk"
include: "rules/deseq2.smk"
include: "rules/pcaExplorer.smk"

rule all:
    input:
        **targets_dict
    message:
        "Finishing the differential gene expression pipeline"
