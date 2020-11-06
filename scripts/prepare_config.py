#!/usr/bin/python3.8
# -*- coding: utf-8 -*-

"""
This script aims to prepare the configuration file used
by the rna-dge-salmon-deseq2 pipeline


You can test this script with:
pytest -vv prepare_config.py

Usage example:
python3.8 prepare_config.py --help
"""

import argparse  # Parse command line
import logging  # Traces and loggings
import shlex  # Lexical analysis
import sys  # System related methods
import yaml  # Parse Yaml files


from pathlib import Path  # Paths related methods
from snakemake.utils import makedirs  # Easily build directories
from typing import Dict, Any  # Typing hints

try:
    import scripts.common_script_rna_dge_salmon_deseq2
except ModuleNotFoundError:
    import common_script_rna_dge_salmon_deseq2


def parser() -> argparse.ArgumentParser:
    """
    Build the argument parser object
    """
    main_parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__,
        formatter_class=common_script_rna_dge_salmon_deseq2.CustomFormatter,
        epilog="This script does not make any magic. Please check the prepared"
        " configuration file!",
    )

    main_parser.add_argument(
        "gtf",
        help="Path to GTF file (default: %(default)s)",
        type=str,
        metavar="PATH",
    )

    main_parser.add_argument(
        "--formulas",
        help="space separated list of R formulas designed to build linear "
        "model on your data (use simple commas to avoid bash expension)",
        nargs="+",
        default=["~Condition"],
    )

    main_parser.add_argument(
        "--model-name",
        help="Space separated list of model names. Each of these name should "
        "correspond to a single formula. Each name should be unique",
        nargs="+",
        default=["Condition_model"],
    )

    main_parser.add_argument(
        "--workdir",
        help="Path to working directory (default: %(default)s)",
        type=str,
        metavar="PATH",
        default=".",
    )

    main_parser.add_argument(
        "--design",
        help="Path to design file (default: %(default)s)",
        type=str,
        metavar="PATH",
        default="design.tsv",
    )

    main_parser.add_argument(
        "--output",
        help="Path to output file (default: %(default)s)",
        type=str,
        metavar="PATH",
        default="config.yaml",
    )

    main_parser.add_argument(
        "--threads",
        help="Maximum number of threads used (default: %(default)s)",
        type=int,
        default=1,
    )

    main_parser.add_argument(
        "--singularity",
        help="Docker/Singularity image (default: %(default)s)",
        type=str,
        default="docker://continuumio/miniconda3:4.4.10",
    )

    main_parser.add_argument(
        "--cold-storage",
        help="Space separated list of absolute path to "
        "cold storage mount points (default: %(default)s)",
        nargs="+",
        type=str,
        default=[" "],
    )

    main_parser.add_argument(
        "--alpha-threshold",
        help="The alpha error threshold (default: %(default)s)",
        type=float,
        default=0.05,
    )

    main_parser.add_argument(
        "--fc-threshold",
        help="The Fold Change significance threshold" " (default: %(default)s)",
        type=float,
        default=1.0,
    )

    main_parser.add_argument(
        "--copy-extra",
        help="Optional parameters for bash copy" " (default: %(default)s)",
        type=str,
        default="--verbose",
    )

    main_parser.add_argument(
        "--tximport-extra",
        help="Optional parameters for tximport::tximport"
        " (default: %(default)s)",
        type=str,
        default="type='salmon', ignoreTxVersion=TRUE, ignoreAfterBar=TRUE",
    )

    main_parser.add_argument(
        "--deseq2-estimateSizeFactors-extra",
        help="Extra parameters for estimateSizeFactors"
        " (default: %(default)s)",
        type=str,
        default="type='ratio', quiet=FALSE",
    )

    main_parser.add_argument(
        "--deseq2-estimateDispersions-extra",
        help="Extra parameters for estimateDispersions"
        " (default: %(default)s)",
        type=str,
        default="fitType='local', quiet=FALSE",
    )

    main_parser.add_argument(
        "--deseq2-rlog-extra",
        help="Extra parameters for rlog function" " (default: %(default)s)",
        type=str,
        default="blind=FALSE, fitType=NULL",
    )

    main_parser.add_argument(
        "--deseq2-vst-extra",
        help="Extra parameters for rlog function" " (default: %(default)s)",
        type=str,
        default="blind=FALSE, fitType=NULL",
    )

    main_parser.add_argument(
        "--deseq2-nbinomWaldTest-extra",
        help="Extra parameters for nbinomWaldTest" " (default: %(default)s)",
        type=str,
        default="quiet=FALSE",
    )

    main_parser.add_argument(
        "--pcaexplorer-limmaquickpca2go-extra",
        help="Extra parameters for limma pca to go in pcaExplorer",
        type=str,
        default="organism = 'Hs'",
    )

    main_parser.add_argument(
        "--pcaexplorer-distro-expr-extra",
        help="Extra parameters for pcaExplorer's expression distribution plot",
        type=str,
        default="plot_type='density'",
    )

    main_parser.add_argument(
        "--pcaexplorer-scree-extra",
        help="Extra parameters for PCA scree in pcaExplorer",
        type=str,
        default="type='pev', pc_nr=10",
    )

    main_parser.add_argument(
        "--pcaexplorer-pcacorrs-extra",
        help="Extra parameters for PCA axes correlations "
        "with experimental design",
        type=str,
        default="pc=1",
    )

    main_parser.add_argument(
        "--pcaexplorer-pair-corr-extra",
        help="Extra parameters for PCA sample correlations",
        type=str,
        default="use_subset=TRUE, log=FALSE",
    )

    main_parser.add_argument(
        "--use-vst",
        help="Use Variance Stabilized Transformation to normalize data, "
        "instead of regularized log",
        default=True,
        action="store_true",
    )

    main_parser.add_argument(
        "--pca-axes-depth",
        help="Maximum number of axes plotted in PCAs",
        default=2,
        type=int
    )

    # Logging options
    log = main_parser.add_mutually_exclusive_group()
    log.add_argument(
        "-d",
        "--debug",
        help="Set logging in debug mode",
        default=False,
        action="store_true",
    )

    log.add_argument(
        "-q",
        "--quiet",
        help="Turn off logging behaviour",
        default=False,
        action="store_true",
    )
    return main_parser


def parse(args: Any) -> argparse.ArgumentParser:
    """
    Return an argument parser from command line
    """
    return parser().parse_args(args)


def test_parse_args() -> None:
    """
    Test the argument parsing function
    """
    options = parse(shlex.split("/path/to/file.gtf --debug "))
    expected = argparse.Namespace(
        alpha_threshold=0.05,
        cold_storage=[" "],
        copy_extra="--verbose",
        debug=True,
        deseq2_estimateDispersions_extra="fitType='local', quiet=FALSE",
        deseq2_estimateSizeFactors_extra="type='ratio', quiet=FALSE",
        deseq2_nbinomWaldTest_extra="quiet=FALSE",
        deseq2_rlog_extra="blind=FALSE, fitType=NULL",
        deseq2_vst_extra="blind=FALSE, fitType=NULL",
        design="design.tsv",
        fc_threshold=1.0,
        formulas=["~Condition"],
        gtf="/path/to/file.gtf",
        model_name=["Condition_model"],
        output="config.yaml",
        pca_axes_depth=2,
        pcaexplorer_distro_expr_extra="plot_type='density'",
        pcaexplorer_limmaquickpca2go_extra="organism = 'Hs'",
        pcaexplorer_pair_corr_extra="use_subset=TRUE, log=FALSE",
        pcaexplorer_pcacorrs_extra="pc=1",
        pcaexplorer_scree_extra="type='pev', pc_nr=10",
        quiet=False,
        singularity="docker://continuumio/miniconda3:4.4.10",
        threads=1,
        tximport_extra="type='salmon', ignoreTxVersion=TRUE, ignoreAfterBar=TRUE",
        use_vst=False,
        workdir=".",
    )
    assert options == expected


def args_to_dict(args: argparse.ArgumentParser) -> Dict[str, Any]:
    """
    Build config dictionnary from parsed command line arguments
    """
    result_dict = {
        "design": args.design,
        "config": args.output,
        "workdir": args.workdir,
        "threads": args.threads,
        "singularity_docker_image": args.singularity,
        "cold_storage": args.cold_storage,
        "ref": {"gtf": args.gtf},
        "thresholds": {
            "alpha_threshold": args.alpha_threshold,
            "fc_threshold": args.fc_threshold,
        },
        "params": {
            "copy_extra": args.copy_extra,
            "tximport_extra": args.tximport_extra,
            "DESeq2_estimateSizeFactors_extra": args.deseq2_estimateSizeFactors_extra,
            "DESeq2_estimateDispersions_extra": args.deseq2_estimateDispersions_extra,
            "DESeq2_rlog_extra": args.deseq2_rlog_extra,
            "DESeq2_vst_extra": args.deseq2_vst_extra,
            "DESeq2_nbinomWaldTest_extra": args.deseq2_nbinomWaldTest_extra,
            "use_rlog": (not args.use_vst),
            "limmaquickpca2go_extra": args.pcaexplorer_limmaquickpca2go_extra,
            "pcaexplorer_distro_expr": args.pcaexplorer_distro_expr_extra,
            "pcaexplorer_scree": args.pcaexplorer_scree_extra,
            "pcaexplorer_pair_corr": args.pcaexplorer_pair_corr_extra,
            "pcaexplorer_pcacorrs": args.pcaexplorer_pcacorrs_extra,
            "pca_axes_depth": args.pca_axes_depth
        },
        "models": dict(zip(args.model_name, args.formulas)),
    }

    logging.debug(result_dict)
    return result_dict


def test_args_to_dict() -> None:
    """
    Test the above functions
    """
    expected = {
        "design": "design.tsv",
        "config": "config.yaml",
        "workdir": ".",
        "threads": 1,
        "singularity_docker_image": "docker://continuumio/miniconda3:4.4.10",
        "cold_storage": [" "],
        "ref": {"gtf": "/path/to/file.gtf"},
        "thresholds": {"alpha_threshold": 0.05, "fc_threshold": 1.0},
        "params": {
            "copy_extra": "--verbose",
            "tximport_extra": "type='salmon', ignoreTxVersion=TRUE, ignoreAfterBar=TRUE",
            "DESeq2_estimateSizeFactors_extra": "type='ratio', quiet=FALSE",
            "DESeq2_estimateDispersions_extra": "fitType='local', quiet=FALSE",
            "DESeq2_rlog_extra": "blind=FALSE, fitType=NULL",
            "DESeq2_vst_extra": "blind=FALSE, fitType=NULL",
            "DESeq2_nbinomWaldTest_extra": "quiet=FALSE",
            "use_rlog": True,
            "limmaquickpca2go_extra": "organism = 'Hs'",
            "pcaexplorer_distro_expr": "plot_type='density'",
            "pcaexplorer_scree": "type='pev', pc_nr=10",
            "pcaexplorer_pair_corr": "use_subset=TRUE, log=FALSE",
            "pcaexplorer_pcacorrs": "pc=1",
            "pca_axes_depth": 2
        },
        "models": {"Condition_model": "~Condition"},
    }
    tested = args_to_dict(parse(shlex.split("/path/to/file.gtf --debug ")))
    assert tested == expected


def main(args: argparse.ArgumentParser) -> None:
    """
    Main function of the script
    """
    config_dict = args_to_dict(args)
    common_script_rna_dge_salmon_deseq2.write_yaml(
        Path(args.output),
        config_dict
    )


if __name__ == "__main__":
    args = parse(sys.argv[1:])
    makedirs("logs/prepare/")

    # Build logging object and behaviour
    logging.basicConfig(
        filename="logs/prepare/config.log", filemode="w", level=10
    )

    try:
        main(args)
    except Exception as e:
        logging.exception("%s", e)
        raise

    logging.info("Process over")
