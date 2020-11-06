#!/usr/bin/python3.8
# -*- coding: utf-8 -*-

"""
This script aims to prepare the design file used by rna-dge-salmon-deseq2 pipeline.

It goes through a rna-count-salmon directory an searches for
quant files.

Have a look at the parameter --import-design, which takes a design file as input. This design file should contain factors,
associated with sample names.

You can test this scropt with:
pytest -vv prepare_design.py

Usage example:
python3.8 prepare_design.py /path/to/salmon_counts
"""

import argparse  # Parse command line arguments
import logging  # Logging behavior
import pandas  # Handle large tables
import shlex  # Handle teext like command line input
import sys  # System related operations

from pathlib import Path  # Handle paths and file system
from snakemake.utils import makedirs  # Easily build recursive directories
from typing import Any, Dict, Union  # Typi hinting

from common_script_rna_dge_salmon_deseq2 import *


def parser() -> argparse.ArgumentParser:
    """
    Build the argument parser object
    """
    main_parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__,
        formatter_class=CustomFormatter,
        epilog="This script does not make any magic. Please check the prepared"
        " configuration file!",
    )

    # Positional arguments
    main_parser.add_argument(
        "salmon_directory",
        help="Path to directory containing multiple salmon quantifications",
        type=str,
    )

    # Optional arguments
    main_parser.add_argument(
        "-i",
        "--import-design",
        help="Path to a TSV-formatted text file containing "
        "both samples and factors",
        default=None,
        type=str,
    )

    main_parser.add_argument(
        "-o",
        "--output",
        help="Path to output file",
        default="design.tsv",
        type=str,
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
    Test the above function
    """
    expected = argparse.Namespace(
        debug=False,
        import_design=None,
        output="design.tsv",
        quiet=False,
        salmon_directory=".",
    )
    tested = parse(shlex.split("."))
    assert tested == expected


def design_importer(
    design_path: str, index_col: Union[str, int] = 0
) -> pandas.DataFrame:
    """
    Load the design file as a pandas dataframe
    """
    logging.info(f"Loading {design_path}")
    data = pandas.read_csv(
        design_path,
        header=0,
        sep="\t",
        index_col=(index_col if isinstance(index_col, int) else None),
    )

    if isinstance(index_col, str):
        data.set_index(index_col, inplace=True)

    logging.debug(data.head())
    return data


def find_quantification(salmon_path: str) -> Dict[str, str]:
    """
    Iterates through a directory and searches for salmon files
    """
    logging.info(f"Looking for salmon quantification in {salmon_path}")
    salmon_path = Path(salmon_path)
    quant_dir_dict = {}
    for quant_dir in salmon_path.iterdir():
        if not quant_dir.is_dir():
            continue

        if "quant.sf" in list(i.name for i in quant_dir.iterdir()):
            logging.debug(f"Adding {str(quant_dir)}")
            quant_dir_dict[quant_dir.name] = str(quant_dir)

    data = pandas.DataFrame(quant_dir_dict.items())
    logging.debug(data.head())

    data.columns = ["Sample_id", "Salmon"]
    data.set_index("Sample_id", inplace=True)
    logging.debug(data.head())
    return data


def test_find_quantification() -> None:
    """
    Test the above function
    """
    path = "test/pseudo_mapping"
    expected = pandas.DataFrame(
        [
            {
                "Sample_id": f"{name}.chr21.1",
                "Salmon": f"test/pseudo_mapping/{name}.chr21.1",
            }
            for name in ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
        ]
    ).set_index("Sample_id")
    tested = find_quantification(path).sort_index()
    assert tested.equals(expected)


def merge_designs(
    quant_dir: pandas.DataFrame, imported_design: pandas.DataFrame
) -> pandas.DataFrame:
    """
    Merge two design frames
    """
    logging.info("Adding salmon results to previous design file")
    data = pandas.merge(
        quant_dir,
        imported_design,
        left_index=True,
        right_index=True,
        how="outer",
        validate="1:1",
        suffixes=["_quant", ""],
    )
    logging.debug(data.head())
    return data


def main(args: argparse.ArgumentParser) -> None:
    """
    Main function of the programm: performs all call and writes all results
    """
    design = find_quantification(args.salmon_directory)

    if (
        args.import_design is not None
        and Path(args.import_design).exists() is True
    ):
        old = design_importer(args.import_design)
        design = merge_designs(design.copy(), old)

    logging.info(f"Saving results to {str(args.output)}")
    design.to_csv(args.output, sep="\t", na_rep="NA")


if __name__ == "__main__":
    args = parse(sys.argv[1:])
    makedirs("logs/prepare")
    logging.basicConfig(
        filename="logs/prepare/design.log", filemode="w", level=10
    )

    try:
        main(args)
    except Exception as e:
        logging.exception("%s", e)
        raise
    sys.exit(0)
    logging.info("Process over")
