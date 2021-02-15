"""
While other .smk files contains rules and pure snakemake instructions, this
one gathers all the python instructions surch as config mappings or input
validations.
"""

import itertools        # Handle iterators
import os               # OS related operations
import os.path as op    # Path and file system manipulation
import sys              # System related operations


from pathlib import Path               # Easily handle file paths
from typing import Any, Dict, Generator, List     # Give IO information
import pandas as pd                    # Deal with TSV files (design)
from snakemake.utils import validate   # Check Yaml/TSV formats

from common_rna_dge_salmon_deseq2 import *

# Snakemake-Wrappers version
wrapper_version = "https://raw.githubusercontent.com/snakemake/snakemake-wrappers/0.67.0"
# github prefix
git = "https://raw.githubusercontent.com/tdayris/snakemake-wrappers/Unofficial"
#git = "file:/home/tdayris/Documents/Developments/snakemake-wrappers/"

# Loading configuration
if config == dict():
    configfile: "config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# Loading design file
design = pd.read_csv(
    config["design"],
    sep="\t",
    header=0,
    index_col=None,
    dtype=str
)
design.set_index(design["Sample_id"])
validate(design, schema="../schemas/design.schema.yaml")

# Define Pipeline-dependent column name, that are not going to be plotted
# or appear in reports
reserved = {"Sample_id", "Upstream_file",
            "Downstream_file", "Salmon"}


wildcard_constraints:
    design = "|".join(config["models"].keys()),
    elipse = "|".join(["with_elipse", "without_elipse"]),
    intgroup = r"[^/]+",
    a = '|'.join(map(str, range(1, 10))),
    b = '|'.join(map(str, range(1, 10)))

report: "../report/general.rst"


def get_targets(get_deseq2 : bool = False,
                get_pca_exp: bool = False,
                get_figures: bool = False,
                get_gseaapp: bool = False,
                get_multiqc: bool = False) -> Dict[str, Any]:
    """
    This function retuans the targets of the snakefile
    according to the users requests
    """
    # Initialize list of final targets
    targets = {}

    # Remove unnecessary columns
    reserved = {
        "Sample_id",
        "Upstream_file",
        "Downstream_file",
        "Upstream_name",
        "Downstream_name",
        "Salmon",
        "Salmon_quant",
        "Unconcatenated_fq_R1_files",
        "Unconcatenated_fq_R2_files"
    }

    # short cuts for further work
    first_model = list(config["models"].keys())[0]
    multiqc_flag = True  # False if missing input files

    if add_target(config, "deseq2", get_deseq2):
        # Add DESeq2 result files
        targets["deseq2"] = expand(
            "deseq2/{design}/Wald_{design}.RDS",
            design=config["models"].keys()
        )

    if add_target(config, "pca_explorer", get_pca_exp):
        # Add pcaExplorer required files
        targets["pca_explorer"] = expand(
            "pcaExplorer/{design}/{object}_{design}.RDS",
            design=config["models"].keys(),
            object=["annotation", "limmago"]
        )

        # Add reporting figures
        targets["pca_explorer_figures"] = expand(
            "figures/{design}/{figures}_{design}.png",
            design=config["models"].keys(),
            figures=["pca_scree", "distro_expr", "pcacorrs"]
        )

        pca_groups = config.get("columns", None)
        if pca_groups is None:
            pca_groups = get_groups(design, columns_to_drop=reserved, nest=1)

        targets["pca"] = expand(
            "figures/{design}/pca/pca_{intgroup}_{axes}_{elipse}.png",
            design=config["models"].keys(),
            intgroup=pca_groups,
            axes=[
                f"ax_{a}_ax_{b}"
                for a, b in get_axes(config["params"].get("pca_axes_depth", 4))
            ],
            elipse=["with_elipse", "without_elipse"]
        )

        # Add pcaExplorer launch script for developper
        targets["pca_explorer_scripts"] = expand(
            "pcaExplorer/{design}/pcaExplorer_launcher_{design}.R",
            design=config["models"].keys()
        )
    else:
        # If no pca-explorer is asked, then no multiqc will be produced
        multiqc_flag = False

    if add_target(config, "gseaapp", get_gseaapp):
        targets["gseaapp"] = expand(
            "GSEAapp/{design}/{design}_{content}.tsv",
            design=config["models"].keys(),
            content=["complete", "padj_fc", "fc_fc"],
        )

    if add_target(config, "additional_figures", get_figures):
        targets["enhancedVolcano"] = expand(
            "figures/{design}/Volcano_{design}.png",
            design=config["models"].keys()
        )

        targets["seaborn_clustermaps"] = expand(
            "figures/{design}/sample_clustered_heatmap_{design}.png",
            design=config["models"].keys()
        )
    else:
        # If no additional figures are built, the no multiqc is produced
        multiqc_flag = False

    if add_target(config, "multiqc", get_multiqc) and multiqc_flag:
        targets["multiqc"] = expand(
            "multiqc/{design}/multiqc_config.yaml",
            design=config["models"].keys()
        )

    return targets
