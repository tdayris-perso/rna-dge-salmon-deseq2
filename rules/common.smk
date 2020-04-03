"""
While other .smk files contains rules and pure snakemake instructions, this
one gathers all the python instructions surch as config mappings or input
validations.
"""

import itertools        # Handle iterators
import os               # OS related operations
import os.path as op    # Path and file system manipulation
import sys              # System related operations


from pathlib import Path
from typing import Any, Dict, Generator, List     # Give IO information
import pandas as pd                    # Deal with TSV files (design)
from snakemake.utils import validate   # Check Yaml/TSV formats


try:
    from common_rna_dge_salmon_deseq2 import *
except ImportError:
    raise

# Snakemake-Wrappers version
wrapper_version = "https://raw.githubusercontent.com/snakemake/snakemake-wrappers/0.50.3"
# github prefix
git = "https://raw.githubusercontent.com/tdayris-perso/snakemake-wrappers"

# Loading configuration
if config == dict():
    configfile: "config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# Loading deisgn file
design = pd.read_csv(
    config["design"],
    sep="\t",
    header=0,
    index_col=None,
    dtype=str
)
design.set_index(design["Sample_id"])
validate(design, schema="../schemas/design.schema.yaml")

report: "../report/general.rst"


def deseq2_png(wildcards: Any) -> Generator[str, None, None]:
    """
    This function solves the checkpoint IO streams for Snakemake
    """
    tsvs = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "figures/pval_histogram/{design}/{name}_pval_histogram.png",
        design=wildcards.design,
        name=glob_wildcards(os.path.join(tsvs, "Deseq2_{name}.tsv")).name
    )


def get_rdsd_targets(get_tximport: bool = False,
                     get_deseq2: bool = False,
                     get_aggregation: bool = False,
                     get_plots: bool = False,
                     get_pca_explorer: bool = False) -> Dict[str, Any]:
    """
    This function retuans the targets of the snakefile
    according to the users requests
    """
    targets = {}
    reserved = {"Sample_id", "Upstream_file",
                "Downstream_file", "Salmon_quant"}
    if get_tximport is True:
        targets["tximport"] = "tximport/txi.RDS"

    if get_deseq2 is True:
        targets["deseq2_dds"] = expand(
            "deseq2/{design}/Wald.RDS",
            design=config["models"].keys()
        )

        targets["vst"] = expand(
            "deseq2/{design}/rlog.RDS",
            design=config["models"].keys()
        )

    if get_aggregation is True:
        targets["aggrgation"] = "aggrgated_counts/TPM.tsv"

    if get_plots is True:
        targets["pval_histograms"] = expand(
            "figures.{design}.tar.bz2",
            design=config["models"].keys()
        )

        targets["plots"] = [
            "figures/Box_plot_non_null_counts.png",
            "figures/pairwise_scatterplot.png"
        ]
        targets["pca"] = expand(
            "figures/PCA/PCA_{factor}_{axes}.png",
            axes=[
                f"PC{i}_PC{j}"
                for i, j in itertools.permutations(range(1, 4, 1), 2)
            ],
            factor=set(design.columns) - reserved
        )
        targets["clustermaps"] = expand(
            "figures/Clustermap/Clustered_heatmap_{factor}.png",
            factor=set(design.columns) - reserved
        )

    if get_pca_explorer is True:
        targets["pcaexplorer_annot"] = expand(
            "pcaExplorer/{design}/annotation.RDS",
            design=config["models"].keys()
        )
        # targets["pcaExplorer_limmago"] = expand(
        #     "pcaExplorer/{design}/limmago.RDS",
        #     design=config["models"].keys()
        # )
    return targets
