import snakemake.utils  # Load snakemake API
import sys              # System related operations

# Python 3.7 is required
if sys.version_info < (3, 7):
    raise SystemError("Please use Python 3.7 or later.")

# Snakemake 5.10.0 at least is required
snakemake.utils.min_version("5.10.0")


include: "rules/common.smk"
include: "rules/copy.smk"
include: "rules/tximport.smk"
include: "rules/deseq2.smk"
include: "rules/pandas.smk"


rule all:
    input:
        **get_rdsd_targets(get_deseq2 = True,
                           get_aggregation = True,
                           get_plots = True)
    message:
        "Finishing the differential gene expression pipeline"
