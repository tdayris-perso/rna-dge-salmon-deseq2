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
    intgroup = "|".join(get_intgroups(design, columns_to_drop=reserved)),
    elipse = "|".join(["with_elipse", "without_elipse"])

report: "../report/general.rst"


def deseq2_png(wildcards: Any) -> Generator[str, None, None]:
    """
    This function solves the checkpoint IO streams for Snakemake
    """
    tsvs = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "figures/{design}/{name}_pval_histogram.png",
        design=wildcards.design,
        name=glob_wildcards(os.path.join(tsvs, "Deseq2_{name}.tsv")).name
    )


def gsea_tsv(wildcards: Any) -> Generator[str, None, None]:
    """
    This function solves the checkpoint IO streams for DESeq2
    """
    names = checkpoints.nbinomWaldTest.get(**wildcards).output.tsv
    return expand(
        "GSEA/{design}/{factor}.{content}.tsv",
        design=wildcards.design,
        factor=[n for n in glob_wildcards(os.path.join(names, "Deseq2_{factor}.tsv")).factor if n != "Intercept"],
        content=[
            "complete",
            "filtered_on_padj.stat_change_is_fold_change",
            "filtered_on_padj_and_fc.stat_change_is_fold_change",
            "filtered_on_padj_and_fc.stat_change_is_padj",
            "filtered_on_padj.stat_change_is_padj"
        ]
    )

def clusterProfiler_figures(wildcards: Any) -> Generator[str, None, None]:
    """
    This function solves the checkpoint IO streams for clusterProfiler
    """
    names = checkpoints.gene_list.get(**wildcards).output.gene_lists
    result = expand(
        "figures/{design}/clusterProfiler/{tool}/{name}.png",
        tool=["GSEAGO", "barplot"],
        design=wildcards.design,
        name=[n for n in glob_wildcards(os.path.join(names, "{name}.tsv")).name if n != "Intercept"]
    )
    print(result)
    return result


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

        # targets["deseq2_reports"] = expand(
        #     "reports.{design}.tar.bz2",
        #     design=config["models"].keys()
        # )

    # if get_aggregation is True:
    #     targets["aggrgation"] = "aggrgated_counts/TPM.tsv"

    # if get_plots is True:
    #     targets["pval_histograms"] = expand(
    #         "figures.{design}.tar.bz2",
    #         design=config["models"].keys()
    #     )

        # targets["plots"] = [
        #     "figures/Box_plot_non_null_counts.png",
        #     "figures/pairwise_scatterplot.png"
        # ]
        # targets["pca"] = expand(
        #     "figures/{design}/pca.png",
        #     design=config["models"].keys()
        # )
        # targets["clustermaps"] = expand(
        #     "figures/Clustermap/Clustered_heatmap_{factor}.png",
        #     factor=set(design.columns) - reserved
        # )

        # targets["clusterProfiler_figures"] = expand(
        #     "figures.clusterProfiler.{design}.tar.bz2",
        #     design=config["models"].keys()
        # )

    # if get_pca_explorer is True:
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

        targets["pcas"] = expand(
            "figures/{design}/pca/{intgroup}_{axes}_{elipse}.png",
            design=config["models"].keys(),
            intgroup=get_intgroups(design, columns_to_drop=reserved),
            axes=[f"ax_{a}_ax_{b}" for a, b in get_axes(5)],
            elipse=["with_elipse", "without_elipse"]
        )

        targets["pair_corr"] = expand(
            "figures/{design}/pairwise_scatterplot_{design}.png",
            design=config["models"].keys()
        )

        targets["seaborn_clustermap"] = expand(
            "figures/{design}/sample_clustered_heatmap/sample_clustered_heatmap_{factor}.png",
            design=config["models"].keys(),
            factor=list(set(design.columns) - reserved)
        )

        targets["multiqc_report"] = expand(
            "multiqc/{design}/report.html",
            design=config["models"].keys()
        )
    #     targets["pcaExplorer_limmago"] = expand(
    #         "pcaExplorer/{design}/limmago.RDS",
    #         design=config["models"].keys()
    #     )


    return targets
