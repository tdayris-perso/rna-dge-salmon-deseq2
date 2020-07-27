import snakemake.utils  # Load snakemake API
import sys              # System related operations

# Python 3.7 is required
if sys.version_info < (3, 8):
    raise SystemError("Please use Python 3.7 or later.")

# Snakemake 5.10.0 at least is required
snakemake.utils.min_version("5.20.1")


include: "rules/common.smk"
include: "rules/copy.smk"
include: "rules/tximport.smk"
include: "rules/gseaapp.smk"
include: "rules/deseq2.smk"
include: "rules/pandas.smk"
include: "rules/pcaExplorer.smk"
include: "rules/multiqc.smk"
include: "rules/enhancedVolcano.smk"
# include: "rules/clusterProfiler.smk"


rule all:
    input:
        **get_rdsd_targets(get_deseq2 = True)
    message:
        "Finishing the differential gene expression pipeline"
