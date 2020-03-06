"""
While other .smk files contains rules and pure snakemake instructions, this
one gathers all the python instructions surch as config mappings or input
validations.
"""

from snakemake.utils import validate
from typing import Any, Dict, List, Union

import os.path as op    # Path and file system manipulation
import os               # OS related operations
import pandas as pd     # Deal with TSV files (design)
import sys              # System related operations

# Snakemake-Wrappers version
# WARNING: Don't forget to agree this with subworkflows !
swv = "0.49.0"
# github prefix
git = "https://raw.githubusercontent.com/tdayris-perso/snakemake-wrappers"

# Loading configuration
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


def sample_id() -> List[str]:
    """
    Return the list of samples identifiers
    """
    return design["Sample_id"].tolist()


def get_quant_files() -> List[Union[str, Path]]:
    """
    This function returns the list of all quantifications files prduced
    by Salmon in the rna-count-salmon pipeline
    """
    return expand(
        "pseudo_mapping/{sample}/quant.sf",
        sample=sample_id_list
    )


def get_fodmula_w(wildcards) -> str:
    """
    Return a formula based on a model name
    """
    return config["params"]["models"][wildcards.model]


def get_targets() -> Dict[str, Any]:
    """
    This function call final files
    """
    print(config["params"])
    results = {
        # "quant": quant_file_list,
        # "txi": "tximport/txi.RDS",
        # "datasets": expand(
        #     "deseq2/DESeq2_Dataset_{model}.RDS",
        #     model=config["params"]["models"].keys()
        # ),
        # "size_factors": expand(
        #     "deseq2/size_factors/{model}.RDS",
        #     model=config["params"]["models"].keys()
        # ),
        # "dispersions": expand(
        #     "deseq2/disp_estimate/{model}.RDS",
        #     model=config["params"]["models"].keys()
        # ),
        "wald": expand(
            "deseq2/wald_test/{model}.RDS",
            model=config["params"]["models"].keys()
        ),
        # "deseq2_vsd": expand(
        #     "deseq2/vsd/{model}.RDS",
        #     model=config["params"]["models"].keys()
        # ),
        "pcaexplorer_annotation": expand(
            "pcaexplorer/{model}/annotation_{model}.RDS",
            model=config["params"]["models"].keys()
        ),
        "pcaexplorer_limmago": expand(
            "pcaexplorer/{model}/limmago_{model}.RDS",
            model=config["params"]["models"].keys()
        )


    }
    return results


sample_id_list = sample_id()
quant_file_list = get_quant_files()
targets_dict = get_targets()
