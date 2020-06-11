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
git = "https://raw.githubusercontent.com/tdayris/snakemake-wrappers/Unofficial"

local = "file:/home/tdayris/Documents/Developments/snakemake-wrappers/"

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

reserved = {"Sample_id", "Upstream_file",
            "Downstream_file", "Salmon"}


wildcard_constraints:
    design = "|".join(config["models"].keys()),
    #intgroup = "|".join(get_intgroups(design, columns_to_drop=reserved)),
    elipse = "|".join(["with_elipse", "without_elipse"])

report: "../report/general.rst"


def gsea_tsv(wildcards: Any) -> Generator[str, None, None]:
    """
    This function solves the checkpoint IO streams for DESeq2
    """
    intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "GSEA/{design}/{intgroup}.{content}.tsv",
        design=wildcards.design,
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"],
        content=[
            "complete",
            "filtered_on_padj.stat_change_is_fold_change",
            "filtered_on_padj_and_fc.stat_change_is_fold_change",
            "filtered_on_padj_and_fc.stat_change_is_padj",
            "filtered_on_padj.stat_change_is_padj"
        ]
    )


def volcano_png(wildcards: Any) -> Generator[str, None, None]:
    intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "figures/{design}/Volcano_{intgroup}.png",
        design=wildcards.design,
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def maplot_png(wildcards: Any) -> Generator[str, None, None]:
    intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "figures/{design}/plotMA/plotMA_{intgroup}.png",
        design=wildcards.design,
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def multiqc_reports(wildcards: Any) -> Generator[str, None, None]:
    intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "multiqc/{design}_{intgroup}/report.html",
        design=wildcards.design,
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def pca_plots(wildcards: Any) -> Generator[str, None, None]:
    intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "figures/{design}/pca/pca_{intgroup}_ax_1_ax_2_without_elipse.png",
        design=wildcards.design,
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def get_rdsd_targets(get_tximport: bool = False,
                     get_deseq2: bool = False) -> Dict[str, Any]:
    """
    This function retuans the targets of the snakefile
    according to the users requests
    """
    targets = {}
    reserved = {"Sample_id", "Upstream_file",
                "Downstream_file", "Salmon",
                "Salmon_quant"}
    if get_tximport is True:
        targets["tximport"] = "tximport/txi.RDS"

    if get_deseq2 is True:
        targets["deseq2_dds"] = expand(
            "deseq2/{design}/Wald.RDS",
            design=config["models"].keys()
        )

        targets["rlog"] = expand(
            "deseq2/{design}/rlog.RDS",
            design=config["models"].keys()
        )

        targets["vsd"] = expand(
            "deseq2/{design}/VST.RDS",
            design=config["models"].keys()
        )

        targets["gseapp"] = expand(
            "GSEA/gsea.{design}.tar.bz2",
            design=config["models"].keys()
        )

        targets["volcano"] = expand(
            "Results/{design}/Results_archive.tar.bz2",
            design=config["models"].keys()
        )

        targets["pcaexplorer_annot"] = expand(
            "pcaExplorer/{design}/annotation.RDS",
            design=config["models"].keys()
        )

        targets["distro_expr"] = expand(
            "figures/{design}/distro_expr.png",
            design=config["models"].keys()
        )

        targets["pca_scree"] = expand(
            "figures/{design}/pca_scree.png",
            design=config["models"].keys()
        )

        targets["pca_corrs"] = expand(
            "figures/{design}/pcacorrs.png",
            design=config["models"].keys()
        )

        targets["pair_corr"] = expand(
            "figures/{design}/pairwise_scatterplot_{design}.png",
            design=config["models"].keys()
        )



    return targets
