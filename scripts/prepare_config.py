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

import common_script_rna_dge_salmon_deseq2 as common


def parser() -> argparse.ArgumentParser:
    """
    Build the argument parser object
    """
    main_parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__,
        formatter_class=common.CustomFormatter,
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
        "--models",
        help="A list of models. Each model is composed of [1] "
             "a factor (a column name in your design, or a composition of "
             "several columns separated by dots. See DESeq2 vignette.), "
             "[2] a numerator (your tested condition), [3] a denominator "
             "(your reference condition), and [4] a statistical formula. "
             "These values are separated by commas. To include multiple "
             "models, please separate them by spaces. "
             "See details on rna-dge-salmon-deseq2 wiki.",
        nargs="+",
        default=["Condition,B,A,~Condition"]
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
        help="The alpha error threshold. Warning: "
             "fixing these thresholds here won't set the extra "
             "parameters in DESeq2. It is used for plotting "
             "convenience and table filters (default: %(default)s)",
        type=float,
        default=0.05,
    )

    main_parser.add_argument(
        "--fc-threshold",
        help="The Fold Change significance threshold. Warning: "
             "fixing these thresholds here won't set the extra "
             "parameters in DESeq2. It is used for plotting "
             "convenience and table filters (default: %(default)s)",
        type=float,
        default=1.0,
    )

    pcas = main_parser.add_argument_group("PCA")
    pcas.add_argument(
        "--columns",
        help="While plotting PCAs and other graphs, samples will be colored "
             "and annotated as belonging to a given group, according to each "
             "column in your design file. By default, all columns "
             "will be used ; and may result in a lot of similar graphs.",
        default=None,
        type=str,
        nargs="+"
    )

    pcas.add_argument(
        "--pca-axes-depth",
        help="Maximum number of axes plotted in PCAs"
             " (default: %(default)s)",
        default=2,
        type=int
    )

    pipeline = main_parser.add_argument_group("Pipeline options")
    pipeline.add_argument(
        "--no-pca-explorer",
        help="Do not run pcaExplorer. Warning: many quality control graphs "
             "won't be included (pca, pca correlations, pca scree, pca "
             "axes GO annotation). The multiqc report won't be created.",
        action="store_true",
        default=False
    )
    pipeline.add_argument(
        "--no-gseaapp-files",
        help="Do not produce gseaapp tsv files. Warning: these tables are "
             "human-readable, annotated and filtered (see description in "
             "the final report). No humand-readable DESeq2 results will be "
             "available if this parameter is provided",
        action="store_true",
        default=False
    )
    pipeline.add_argument(
        "--no-additional-figures",
        help="Do not produce additional figures like Volcano plot, Clustered "
             "heatmaps, or pairwise scatterplots. Warning: the multiqc report "
             "will not be created.",
        action="store_true",
        default=False
    )
    pipeline.add_argument(
        "--no-multiqc",
        help="Do not produce multiqc report.",
        action="store_true",
        default=False
    )

    extra = main_parser.add_argument_group("Extra parameters")
    extra.add_argument(
        "--copy-extra",
        help="Optional parameters for bash copy" " (default: %(default)s)",
        type=str,
        default="--verbose",
    )

    extra.add_argument(
        "--tximport-extra",
        help="Optional parameters for tximport::tximport"
        " (default: %(default)s)",
        type=str,
        default="type='salmon', ignoreTxVersion=TRUE, ignoreAfterBar=TRUE",
    )

    extra.add_argument(
        "--deseq2-extra",
        help="Extra parameters for DESeq2::DESeq2 (default: %(default)s)",
        type=str,
        default="quiet=FALSE",
    )

    extra.add_argument(
        "--pcaexplorer-limmaquickpca2go-extra",
        help="Extra parameters for limma pca to go in pcaExplorer"
             " (default: %(default)s)",
        type=str,
        default="organism = 'Hs'",
    )

    extra.add_argument(
        "--pcaexplorer-distro-expr-extra",
        help="Extra parameters for pcaExplorer's expression distribution plot"
             " (default: %(default)s)",
        type=str,
        default="plot_type='density'",
    )

    extra.add_argument(
        "--pcaexplorer-scree-extra",
        help="Extra parameters for PCA scree in pcaExplorer"
             " (default: %(default)s)",
        type=str,
        default="type='pev', pc_nr=10",
    )

    extra.add_argument(
        "--pcaexplorer-pcacorrs-extra",
        help="Extra parameters for PCA axes correlations "
             "with experimental design (default: %(default)s)",
        type=str,
        default="pc=1",
    )

    extra.add_argument(
        "--pcaexplorer-pair-corr-extra",
        help="Extra parameters for PCA sample correlations"
             " (default: %(default)s)",
        type=str,
        default="use_subset=TRUE, log=FALSE",
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
        cold_storage=[' '],
        columns=None,
        copy_extra='--verbose',
        debug=True,
        deseq2_extra='quiet=FALSE',
        design='design.tsv',
        fc_threshold=1.0,
        gtf='/path/to/file.gtf',
        models=['Condition,B,A,~Condition'],
        no_additional_figures=False,
        no_gseaapp_files=False,
        no_multiqc=False,
        no_pca_explorer=False,
        output='config.yaml',
        pca_axes_depth=2,
        pcaexplorer_distro_expr_extra="plot_type='density'",
        pcaexplorer_limmaquickpca2go_extra="organism = 'Hs'",
        pcaexplorer_pair_corr_extra='use_subset=TRUE, log=FALSE',
        pcaexplorer_pcacorrs_extra='pc=1',
        pcaexplorer_scree_extra="type='pev', pc_nr=10",
        quiet=False,
        singularity='docker://continuumio/miniconda3:4.4.10',
        threads=1,
        tximport_extra="type='salmon', ignoreTxVersion=TRUE, ignoreAfterBar=TRUE",
        workdir='.'
    )
    assert options == expected


def args_to_dict(args: argparse.ArgumentParser) -> Dict[str, Any]:
    """
    Build config dictionnary from parsed command line arguments
    """
    models = {}
    for model in args.models:
        factor, numerator, denominator, formula = model.split(",")
        models[f"{factor}_compairing_{numerator}_vs_{denominator}"] = {
            "factor": factor,
            "numerator": numerator,
            "denominator": denominator,
            "formula": formula
        }
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
        "pipeline": {
            "deseq2": True,
            "pca_explorer": not args.no_pca_explorer,
            "gseaapp": not args.no_gseaapp_files,
            "additional_figures": not args.no_additional_figures,
            "multiqc": not args.no_multiqc
        },
        "params": {
            "copy_extra": args.copy_extra,
            "tximport_extra": args.tximport_extra,
            "DESeq2_extra": args.deseq2_extra,
            "limmaquickpca2go_extra": args.pcaexplorer_limmaquickpca2go_extra,
            "pcaexplorer_distro_expr": args.pcaexplorer_distro_expr_extra,
            "pcaexplorer_scree": args.pcaexplorer_scree_extra,
            "pcaexplorer_pair_corr": args.pcaexplorer_pair_corr_extra,
            "pcaexplorer_pcacorrs": args.pcaexplorer_pcacorrs_extra,
            "pca_axes_depth": args.pca_axes_depth
        },
        "models": models,
        "columns": args.columns
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
            "DESeq2_extra": "quiet=FALSE",
            "limmaquickpca2go_extra": "organism = 'Hs'",
            "pcaexplorer_distro_expr": "plot_type='density'",
            "pcaexplorer_scree": "type='pev', pc_nr=10",
            "pcaexplorer_pair_corr": "use_subset=TRUE, log=FALSE",
            "pcaexplorer_pcacorrs": "pc=1",
            "pca_axes_depth": 2
        },
        "pipeline": {
            "deseq2": True,
            "pca_explorer": True,
            "gseaapp": True,
            "additional_figures": True,
            "multiqc": True
        },
        "models": {
            "Condition_compairing_B_vs_A": {
                "factor": "Condition",
                "numerator": "B",
                "denominator": "A",
                "formula": "~Condition"
            }
        },
        "columns": None
    }
    tested = args_to_dict(parse(shlex.split("/path/to/file.gtf --debug ")))
    assert tested == expected


def main(args: argparse.ArgumentParser) -> None:
    """
    Main function of the script
    """
    config_dict = args_to_dict(args)
    common.write_yaml(
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
