#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script contains functions used in multiple scripts of this pipeline
"""

# Maths
import pandas  # Handle large datasets
import numpy   # Handle vectors and maths

# Tests
from pandas.testing import assert_frame_equal  # Dedicated assertion
from pathlib import Path              # Easily handle paths
from snakemake.utils import makedirs  # Make directories recursively

# System and loggings
import sys
import logging


self_dir_path = Path(__file__).parent.resolve()
rnacount_scripts = self_dir_path / ".." / "rna-count-salmon" / "scripts"
print(rnacount_scripts)
sys.path.append(str(rnacount_scripts))

try:
    from common import CustomFormatter
except ImportError:
    logging.exception(
        "Could not find scripts from the pipeline: rna-count-salmon. "
        "Please clone the git repository recursively."
    )
    raise


def read_deseq2_results(tsv: Path) -> pandas.DataFrame:
    """
    Read deseq2 results
    """
    return pandas.read_csv(
        tsv,
        sep="\t",
        header=0,
        index_col=0,
        dtype={
            "baseMean": numpy.float,
            "log2FoldChange": numpy.float,
            "lfcSE": numpy.float,
            "stat": numpy.float,
            "pvalue": numpy.float,
            "padj": numpy.float
        }
    )


def test_read_deseq2_results() -> None:
    """
    This function tests the deseq2 result reader function.
    """
    test_dataset_path = Path("")
    expected = pandas.DataFrame(
        {}
    )
    assert_frame_equal(read_deseq2_results(test_dataset_path), expected)
