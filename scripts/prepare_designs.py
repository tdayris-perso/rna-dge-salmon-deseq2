#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script aims to prepare the list of files to be processed
by the rna-dge-salmon-deseq2 pipeline.

It iterates over a given directory, lists all fastq files. As a pair of
fastq files usually have names that follows each other in the alphabetical
order, this script sorts the fastq files names and, by default, creates
pairs of fastq files that way.

Finally, it writes these pairs, using the longest common substring as
identifier. The written file is a TSV file.

You can test this script with:
pytest -v ./prepare_design.py

Usage example:
# Single ended reads example:
python3.7 ./prepare_designs.py tests/reads --single

# Paired-end libary example:
python3.7 ./prepare_designs.py tests/reads

# Search in sub-directories:
python3.7 ./prepare_designs.py tests --recursive
"""

import argparse           # Parse command line
import logging            # Traces and loggings
import logging.handlers   # Logging behaviour
import os                 # OS related activities
import pandas as pd       # Parse TSV files
import pytest             # Unit testing
import shlex              # Lexical analysis
import sys                # System related methods

from pathlib import Path                        # Paths related methods
from snakemake.utils import makedirs            # Easily build directories
from typing import Dict, Generator, List, Any   # Type hints

self_dir_path = Path(__file__).parent.resolve()
rnacount_scripts = self_dir_path / ".." / "rna-count-salmon" / "scripts"
sys.path.append(str(rnacount_scripts))

try:
    from prepare_design import *
    from common import *
except ImportError:
    print("Could not find scripts from the pipeline: rna-count-salmon")
    raise


# Running programm if not imported
if __name__ == '__main__':
    # Parsing command line
    args = parse_args()

    makedirs("logs/prepare")

    # Build logging object and behaviour
    logging.basicConfig(
        filename="logs/prepare/design.log",
        filemode="w",
        level=logging.DEBUG
    )

    try:
        logging.debug("Preparing design")
        main(args)
    except Exception as e:
        logging.exception("%s", e)
        sys.exit(1)
    sys.exit(0)
