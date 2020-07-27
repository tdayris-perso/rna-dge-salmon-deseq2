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

# Define Pipeline-dependent column name, that are not going to be plotted
# or appear in reports
reserved = {"Sample_id", "Upstream_file",
            "Downstream_file", "Salmon"}


wildcard_constraints:
    design = "|".join(config["models"].keys()),
    elipse = "|".join(["with_elipse", "without_elipse"]),
    a = '|'.join(map(str, range(1, 10))),
    b = '|'.join(map(str, range(1, 10)))

report: "../report/general.rst"


def gsea_tsv(wildcards: Any) -> Generator[str, None, None]:
    """
    This function solves the checkpoint IO streams for DESeq2
    """
    try:
        intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    except TypeError:
        intgroups = wildcards

    intgroups_w = glob_wildcards(
        os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
    ).intgroup
    return expand(
        "GSEA/{design}/{intgroup}.{content}.tsv",
        design=(intgroups if isinstance(intgroups, str) else wildcards.design),
        intgroup=[n for n in intgroups_w if n != "Intercept"],
        content=["complete", "fc_fc", "padj_fc"]
    )



def volcano_png(wildcards: Any) -> Generator[str, None, None]:
    try:
        intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    except TypeError:
        intgroups = wildcards
    return expand(
        "figures/{design}/Volcano_{intgroup}.png",
        design=(intgroups if isinstance(intgroups, str) else wildcards.design),
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def maplot_png(wildcards: Any) -> Generator[str, None, None]:
    try:
        intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    except TypeError:
        intgroups = wildcards
    return expand(
        "figures/{design}/plotMA/plotMA_{intgroup}.png",
        design=(intgroups if isinstance(intgroups, str) else wildcards.design),
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def multiqc_reports(wildcards: Any) -> Generator[str, None, None]:
    try:
        intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    except TypeError:
        intgroups = wildcards
    return expand(
        "multiqc/{design}_{intgroup}/report.html",
        design=(intgroups if isinstance(intgroups, str) else wildcards.design),
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"]
    )


def pca_plots(wildcards: Any) -> Generator[str, None, None]:
    try:
        intgroups = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    except TypeError:
        intgroups = wildcards

    axes_w = [
        f"ax_{a}_ax_{b}"
        for a, b in get_axes(max_axes=config["params"].get("max_axes", 4))
    ]
    return expand(
        "figures/{design}/pca/pca_{intgroup}_{axes}_{ellipse}.png",
        design=(intgroups if isinstance(intgroups, str) else wildcards.design),
        intgroup=[n for n in glob_wildcards(
            os.path.join(intgroups, "Deseq2_{intgroup}.tsv")
        ).intgroup if n != "Intercept"],
        axes=axes_w,
        elipse=["with_elipse", "with_elipse"]
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

        if config["params"].get("use_rlog", False) == True:
            targets["rlog"] = expand(
                "deseq2/{design}/rlog.tsv",
                design=config["models"].keys()
            )
        else:
            targets["vsd"] = expand(
                "deseq2/{design}/VST.tsv",
                design=config["models"].keys()
            )

        targets["gseapp"] = expand(
            "GSEA/gsea.{design}.tar.bz2",
            design=config["models"].keys()
        )

        targets["archive"] = expand(
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

        targets["pca"] = expand(
            "figures/{design}/pca/pca_{intgroup}_{axes}_{elipse}.png",
            design=config["models"].keys(),
            intgroup=get_intgroups(design, columns_to_drop=reserved, nest=1),
            axes=[
                f"ax_{a}_ax_{b}"
                for a, b in get_axes(
                    max_axes=config["params"].get("max_axes", 4)
                )
            ],
            elipse=["with_elipse", "with_elipse"]
        )

        targets["pcaExplorer_script"] = expand(
            "pcaExplorer/{design}/pcaExplorer_launcher_{design}.R",
            design=config["models"].keys()
        )

        targets["clustermap_samples"] = expand(
            "figures/{design}/sample_clustered_heatmap/sample_clustered_heatmap_{factor}.png",
            design=config["models"].keys(),
            factor=get_intgroups(design, columns_to_drop=reserved, nest=1)
        )

        if config.get("report", False):
            targets["gsea"] = expand(
                gsea_tsv("{design}"),
                design = config["models"].keys()
            )

            targets["volcano_plots"] = expand(
                volcano_png("{design}"),
                design = config["models"].keys()
            )

            targets["maplots"] = expand(
                maplot_png("{design}"),
                design = config["models"].keys()
            )

            targets["multiqc"] = expand(
                multiqc_reports("{design}"),
                design=config["models"].keys()
            )

    return targets
