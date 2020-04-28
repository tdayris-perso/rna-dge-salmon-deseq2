#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script aims to prepare the configuration file used
by the rna-dge-salmon-deseq2 pipeline

It goes through a rna-count-salmon directory an searches
output files in order to make this configuration file

You can test this script with:
pytest -vv prepare_config.py

Usage example:
python3.8 prepare_config.py /path/to/rna-count-salmon-results/
"""


import argparse
import logging
import os
import pandas
import pytest
import shlex
import sys
import yaml

from pathlib import Path
from snakemake.utils import makedirs
from typing import Dict, Any

from common_script_rna_dge_salmon_deseq2 import CustomFormatter, write_yaml



def parser() -> argparse.ArgumentParser:
    """
    Build the argument parser object
    """
    main_parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__,
        formatter_class=CustomFormatter,
        epilog="This script does not make any magic. Please check the prepared"
               " configuration file!"
    )

    # Mendatory arguments
    main_parser.add_argument(
        "--formulas",
        help="space separated list of R formulas designed to build linear "
             "model on your data (use simple commas to avoid bash expension)",
        nargs="+",
        default=['~Condition']
    )

    main_parser.add_argument(
        "--model-name",
        help="Space separated list of model names. Each of these name should "
             "correspond to a single formula. Each name should be unique",
        nargs="+",
        default=["Condition_model"]
    )

    # Opitional arguments
    main_parser.add_argument(
        "--results-config",
        help="Path to tne configfile in the result-directory "
             "of previously-executed rna-count-salmon pipeline",
        type=str,
        default="config.yaml"
    )

    main_parser.add_argument(
        "--workdir",
        help="Path to working directory (default: %(default)s)",
        type=str,
        metavar="PATH",
        default="."
    )

    main_parser.add_argument(
        "--threads",
        help="Maximum number of threads used (default: %(default)s)",
        type=int,
        default=1
    )

    main_parser.add_argument(
        "--singularity",
        help="Docker/Singularity image (default: %(default)s)",
        type=str,
        default="docker://continuumio/miniconda3:4.4.10"
    )

    main_parser.add_argument(
        "--cold-storage",
        help="Space separated list of absolute path to "
             "cold storage mount points (default: %(default)s)",
        nargs="+",
        type=str,
        default=[" "]
    )

    main_parser.add_argument(
        "--alpha-threshold",
        help="The alpha error threshold (default: %(default)s)",
        type=float,
        default=0.05
    )

    main_parser.add_argument(
        "--fc-threshold",
        help="The Fold Change significance threshold"
             " (default: %(default)s)",
        type=float,
        default=1.0
    )

    main_parser.add_argument(
        "--copy-extra",
        help="Optional parameters for bash copy"
             " (default: %(default)s)",
        type=str,
        default="--verbose"
    )

    main_parser.add_argument(
        "--tximport-extra",
        help="Optional parameters for tximport::tximport"
             " (default: %(default)s)",
        type=str,
        default="type = 'salmon', ignoreTxVersion = TRUE"
    )

    main_parser.add_argument(
        "--deseq2-estimateSizeFactors-extra",
        help="Extra parameters for estimateSizeFactors"
             " (default: %(default)s)",
        type=str,
        default="quiet=FALSE"
    )

    main_parser.add_argument(
        "--deseq2-estimateDispersions-extra",
        help="Extra parameters for estimateDispersions"
             " (default: %(default)s)",
        type=str,
        default="quiet=FALSE"
    )

    main_parser.add_argument(
        "--deseq2-rlog-extra",
        help="Extra parameters for rlog function"
             " (default: %(default)s)",
        type=str,
        default="blind=FALSE"
    )

    main_parser.add_argument(
        "--deseq2-nbinomWaldTest-extra",
        help="Extra parameters for nbinomWaldTest"
             " (default: %(default)s)",
        type=str,
        default="quiet=FALSE"
    )

    main_parser.add_argument(
        "--limmaquickpca2go-extra",
        help="Extra parameters for limmaquickpca2go"
             " (default: %(default)s)",
        type=str,
        default="organism = 'Hs'"
    )

    main_parser.add_argument(
        "--pcaexplorer-distro-expr-extra",
        help="Extra parameters to plot expression "
             " distribution (default: %(default)s)",
        type=str,
        default="plot_type='boxplot'"
    )

    main_parser.add_argument(
        "--pcaexplorer-scree-extra",
        help="Extra parameters for pca scree plot"
             " (default: %(default)s)",
        type=str,
        default="pc_nr=10"
    )

    main_parser.add_argument(
        "--pcaexplorer-pcacorrs-extra",
        help="Extra parameters for pca correlations"
             " (default: %(default)s)",
        type=str,
        default="logp=TRUE"
    )

    # Logging options
    log = main_parser.add_mutually_exclusive_group()
    log.add_argument(
        "-d", "--debug",
        help="Set logging in debug mode",
        default=False,
        action='store_true'
    )

    log.add_argument(
        "-q", "--quiet",
        help="Turn off logging behaviour",
        default=False,
        action='store_true'
    )

    return main_parser


def parse(args: Any) -> argparse.ArgumentParser:
    """
    Return an argument parser from command line
    """
    return parser().parse_args(args)


def load_old_config(yaml_path: str) -> Dict[str, Any]:
    """
    Load rna-count-salmon configfile
    """
    with open(yaml_path, "r") as config_stream:
        return yaml.safe_load(config_stream)


def args_to_dict(args: argparse.ArgumentParser,
                 old_config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Build config dictionnary from parsed command line arguments
    """
    agr_dir = f"{old_config['workdir']}/aggregated_salmon_counts"

    result_dict = {
        "design": f"{os.path.abspath(args.workdir)}/design.tsv",
        "config": f"{os.path.abspath(args.workdir)}/config.yaml",
        "workdir": os.path.abspath(args.workdir),
        "threads": args.threads,
        "singularity_docker_image": args.singularity,
        "cold_storage": args.cold_storage,
        "ref": old_config["ref"],
        "aggregation": {
            "TPM_genes": f"{agr_dir}/TPM.genes.tsv",
            "TPM": f"{agr_dir}/TPM.tsv",
            "T2G": f"{agr_dir}/transcript_to_gene.tsv"
        },
        "thresholds": {
            "alpha_threshold": args.alpha_threshold,
            "fc_threshold": args.fc_threshold
        },
        "params": {
            "copy_extra": args.copy_extra,
            "tximport_extra": args.tximport_extra,
            "DESeq2_estimateSizeFactors_extra": args.deseq2_estimateSizeFactors_extra,
            "DESeq2_estimateDispersions_extra": args.deseq2_estimateDispersions_extra,
            "DESeq2_rlog_extra": args.deseq2_rlog_extra,
            "DESeq2_nbinomWaldTest_extra": args.deseq2_nbinomWaldTest_extra,
            "limmaquickpca2go_extra": args.limmaquickpca2go_extra,
            "pcaexplorer_distro_expr_extra": args.pcaexplorer_distro_expr_extra,
            "pcaexplorer_scree_extra": args.pcaexplorer_scree_extra,
            "pcaexplorer_pcacorrs_extra": args.pcaexplorer_pcacorrs_extra
        },
        "models": {
            name: formula
            for name, formula
            in zip(args.model_name, args.formulas)
        }
    }

    logging.debug(result_dict)
    return result_dict


def update_design(input_path: str) -> pandas.DataFrame:
    """
    This function updates existing design file
    """
    base = os.path.dirname(input_path)
    design = pandas.read_csv(
        input_path,
        sep="\t",
        header=0,
        index_col=0,
        dtype=str
    )

    design["Salmon_quant"] = [
        f"{base}/pseudo_mapping/{sample}"
        for sample in design.index
    ]

    logging.debug(design.head())
    return design


# Yaml formatting
def dict_to_yaml(indict: Dict[str, Any]) -> str:
    """
    This function makes the dictionnary to yaml formatted text

    Parameters:
        indict  Dict[str, Any]  The dictionnary containing the pipeline
                                parameters, extracted from command line

    Return:
                str             The yaml formatted string, directly built
                                from the input dictionnary

    Examples:
    >>> import yaml
    >>> example_dict = {
        "bar": "bar-value",
        "foo": ["foo-list-1", "foo-list-2"]
    }
    >>> dict_to_yaml(example_dict)
    'bar: bar-value\nfoo:\n- foo-list-1\n- foo-list-2\n'
    >>> print(dict_to_yaml(example_dict))
    bar: bar-value
    foo:
    - foo-list-1
    - foo-list-2
    """
    return yaml.dump(indict, default_flow_style=False)


def test_dict_to_yaml() -> None:
    """
    This function tests the dict_to_yaml function with pytest

    Example:
    >>> pytest -v prepare_config.py -k test_dict_to_yaml
    """
    expected = 'bar: bar-value\nfoo:\n- foo-list-1\n- foo-list-2\n'
    example_dict = {
        "bar": "bar-value",
        "foo": ["foo-list-1", "foo-list-2"]
    }
    assert dict_to_yaml(example_dict) == expected


def main(args: argparse.ArgumentParser) -> None:
    """
    This function performs the whole design update and configuration calls
    """
    logging.debug("Loading rna-count-salmon configuration, building new one")
    old_config = load_old_config(args.results_config)
    new_config = args_to_dict(args, old_config)
    design = update_design(old_config['design'])

    logging.debug("Saving output files")
    makedirs(new_config["workdir"])
    write_yaml(Path(new_config["config"]), new_config)
    design.to_csv(new_config["design"], sep="\t")


# Running programm if not imported
if __name__ == '__main__':
    # Parsing command line
    args = parse(sys.argv[1:])
    makedirs("logs/prepare")

    # Build logging object and behaviour
    logging.basicConfig(
        filename="logs/prepare/config.log",
        filemode="w",
        level=10
    )

    try:
        main(args)
    except Exception as e:
        logging.exception("%s", e)
        sys.exit(1)
    sys.exit(0)
    logging.info("Process over")
