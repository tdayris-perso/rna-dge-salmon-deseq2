#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script aims to prepare the configuration file used
by the whole pipeline and its sub-workflows: both quantification
and differential gene expression.

It goes through the arguments passed in command line and
builds yaml-formatted text files used as a configuration
files for the snakemake whole pipeline.

You can test this script with:
pytest -v ./prepare_configs.py

Usage example:
# Whole pipeline
python3.7 ./prepare_configs.py /path/to/fasta_file.fa

# No quality controls, only quantification and differential gene expression
python3.7 ./prepare_configs.py /path/to/fasta_file.fa
    --no-fastqc
    --no-multiqc
    --no-qc-graphs

# Whole pipeline, verbose mode activated
python3.7 ./prepare_configs.py /path/to/fasta_file.fa -v
"""

import argparse             # Parse command line
import logging              # Traces and loggings
import operator             # Get more advenced operators
import os                   # OS related activities
import pytest               # Unit testing
import shlex                # Lexical analysis
import sys                  # System related methods
import yaml                 # Parse Yaml files

from pathlib import Path              # Paths related methods
from snakemake.utils import makedirs  # Easily build directories
from typing import Dict, Any, Union         # Typing hints


import deseq_common

self_dir_path = Path(__file__).parent.resolve()
rnacount_scripts = self_dir_path / ".." / "rna-count-salmon" / "scripts"
sys.path.append(str(rnacount_scripts))

try:
    import prepare_config
    import common
except ImportError:
    logging.exception(
        "Could not find scripts from the pipeline: rna-count-salmon. "
        "Please clone the git repository recursively."
    )
    raise


class SortingHelpFormatter(common.CustomFormatter,
                           argparse.HelpFormatter):
    """
    This class is used to allow both line breaks and argument sorting
    in help formatter.
    """
    def add_arguments(self, actions):
        actions = sorted(actions, key=operator.attrgetter('option_strings'))
        super(SortingHelpFormatter, self).add_arguments(actions)


rna_count_directory = "rna-count-salmon-results"


def parser() -> argparse.ArgumentParser:
    """
    Create the argument parser

    Example:
    >>> parser()
    """
    main_parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__,
        formatter_class=SortingHelpFormatter,
        parents=[prepare_config.parser()],
        epilog="This script does not make any magic. Please check the prepared"
               " configuration file!",
        add_help=False
    )

    main_parser.add_argument(
        "--formulas",
        help="Every R formulas that are to be used in DESeq2 "
             "(space separated, use simple quotes to avoid bash "
             "interpretation of '~')",
        type=str,
        nargs="+",
        default=' ~1 '
    )

    main_parser.add_argument(
        "--model-names",
        help="Corresponding names of every single models described by "
             "formulas. Number of formulas and number of names should match. "
             "(space separated)",
        type=str,
        nargs="+",
        default="Intercept"
    )

    main_parser.add_argument(
        "--rlog",
        help="Use rlog instead of vst to transform counts",
        default=False,
        action="store_true"
    )

    main_parser.add_argument(
        "--no-qc-graphs",
        help="Do not perform optional quality control graphs",
        default=False,
        action="store_true"
    )
    return main_parser


# Argument parsing functions
def parse_args(args: Any = sys.argv[1:]) -> argparse.ArgumentParser:
    """
    This function parses command line arguments. It directly inherits from
    the argument parser of rna-count-salmon.

    Parameters
        args     Any             All command line arguments

    Return
                ArgumentParser   A object designed to parse the command line
    """
    return parser().parse_args(args)


def test_parse_args() -> None:
    """
    This function tests the command line parser creation

    Example:
    >>> pytest -v prepare_configs.py -k test_parser
    """
    options = parse_args(shlex.split("test.fa"))

    expected = argparse.Namespace(
        aggregate=False,
        cold_storage=[' '],
        debug=False,
        design='design.tsv',
        fasta='test.fa',
        formulas=' ~1 ',
        model_names="Intercept",
        gtf=None, libType='A',
        no_fastqc=False,
        no_multiqc=False,
        no_qc_graphs=False,
        quiet=False,
        rlog=False,
        salmon_index_extra='--keepDuplicates --gencode --perfectHash',
        salmon_quant_extra='--numBootstraps 100 --validateMappings '
                           '--gcBias --seqBias',
        singularity='docker://continuumio/miniconda3:4.4.10',
        threads=1,
        workdir='.'
    )

    assert options == expected


def args_to_dict(args: argparse.ArgumentParser) -> Dict[str, Any]:
    """
    Parse command line arguments and return a dictionnary ready to be
    dumped into yaml

    Parameters:
        args        ArgumentParser      Parsed arguments from command line

    Return:
                    Dict[str, Any]      A dictionnary containing the parameters
                                        for the pipeline

    Examples:
    >>> example_options = parse_args("/path/to/fasta")
    >>> args_to_dict(example_options)
    """
    diff_dict = prepare_config.args_to_dict(args)
    diff_dict["rna_count_directory"] = rna_count_directory
    diff_dict["workflow"]["no_qc_graphs"] = args.no_qc_graphs

    if all(isinstance(i, list) for i in [args.formulas, args.model_names]):
        diff_dict["params"]["models"] = {
            k: v for k, v in zip(args.model_names, args.formulas)
        }
    else:
        diff_dict["params"]["models"] = {args.model_names: args.formulas}

    return diff_dict


def test_args_to_dict() -> None:
    """
    This function tests the creation of the dictionnaries from parsed
    arguments.

    Example:
    >>> pytest -v prepare_configs.py -k test_args_to_dict
    """
    test = argparse.Namespace(
        aggregate=False,
        cold_storage=[' '],
        debug=False,
        design='design.tsv',
        fasta='test.fa',
        formulas=' ~1 ',
        model_names="Intercept",
        gtf=None,
        libType='A',
        no_fastqc=False,
        no_multiqc=False,
        no_qc_graphs=False,
        quiet=False,
        rlog=False,
        salmon_index_extra='--keepDuplicates --gencode --perfectHash',
        salmon_quant_extra='--numBootstraps 100 --validateMappings '
                           '--gcBias --seqBias',
        singularity='docker://continuumio/miniconda3:4.4.10',
        threads=1,
        workdir='.'
    )
    expected = {
        'design': 'design.tsv',
        'workdir': '.',
        'threads': 1,
        'singularity_docker_image': 'docker://continuumio/miniconda3:4.4.10',
        'cold_storage': [' '],
        'ref': {
            'fasta': 'test.fa',
            'gtf': None
        },
        'workflow': {
            'fastqc': True,
            'multiqc': True,
            'aggregate': False,
            'no_qc_graphs': False
        },
        'params': {
            'salmon_index_extra': '--keepDuplicates --gencode --perfectHash',
            'salmon_quant_extra': '--numBootstraps 100 --validateMappings'
                                  ' --gcBias --seqBias',
            'libType': 'A',
            'models': {"Intercept": ' ~1 '}
        },
        'rna_count_directory': 'rna-count-salmon-results'
    }

    assert expected == args_to_dict(test)


def get_config_path(base: Union[str, Path]) -> Path:
    """
    Return the path to the configuration file from a base path
    """
    return Path(base) / "config.yaml"


def test_get_config_path() -> None:
    """
    Test the function that generates the configuration path
    """
    test = get_config_path("test")
    expected = Path("test/config.yaml")
    assert expected == test


# Core of this script
def main(args: argparse.ArgumentParser) -> None:
    """
    This function performs the whole configuration sequence

    Parameters:
        args    ArgumentParser      The parsed command line

    Example:
    >>> main(parse_args(shlex.split("/path/to/fasta")))
    """
    # Building pipeline arguments
    logging.debug("Building configuration file:")
    diff = args_to_dict(args)
    diff_config_path = get_config_path(args.workdir)

    # Saving as yaml
    makedirs(rna_count_directory)
    makedirs(str(diff_config_path.parent))
    with diff_config_path.open("w") as diff_config_yaml:
        logging.debug(f"Saving complete results to {str(diff_config_path)}")
        diff_config_yaml.write(prepare_config.dict_to_yaml(diff))


# Running programm if not imported
if __name__ == '__main__':
    # Parsing command line
    args = parse_args()
    makedirs("logs/prepare")

    # Build logging object and behaviour
    logging.basicConfig(
        filename="logs/prepare/config.log",
        filemode="w",
        level=logging.DEBUG
    )

    try:
        logging.debug("Preparing configuration")
        main(args)
    except Exception as e:
        logging.exception("%s", e)
        sys.exit(1)
    sys.exit(0)
