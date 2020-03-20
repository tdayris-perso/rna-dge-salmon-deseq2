#!/usr/bin/python3.7
# -*- coding: utf-8 -*-


"""
This script contains functions that are to be called by any other scripts in
this pipeline.
"""


import argparse        # Argument parsing
import logging         # Logging behaviour
import os              # OS related operations
import pandas          # Handle large datasets
import pytest
import yaml            # Handle Yaml IO

import os.path as op    # Path and file system manipulation
import pandas           # Deal with TSV files (design)

from itertools import chain                # Chain iterators
from pathlib import Path                   # Easily handle paths
from typing import Any, Dict, List, Optional, Union # Type hints


# Building custom class for help formatter
class CustomFormatter(argparse.RawDescriptionHelpFormatter,
                      argparse.ArgumentDefaultsHelpFormatter):
    """
    This class is used only to allow line breaks in the documentation,
    without breaking the classic argument formatting.
    """


def write_yaml(output_yaml: Path, data: Dict[str, Any]) -> None:
    """
    Save given dictionnary as Yaml-formatted text file
    """
    with output_yaml.open("w") as outyaml:
        yaml.dump(data, outyaml, default_flow_style=False)


def get_gtf_path(config: Dict[str, Any]) -> Dict[str, str]:
    """
    Return a list of paths to soft linked genome annotaion
    """
    return f"genomes/{os.path.basename(config['ref']['gtf'])}"


def get_condition_dict_w(factor: Any, design) -> Dict[str, str]:
    """
    Return a dictionnary with:
    sample_id : condition
    """

    return {k: v for k, v in zip(design["Sample_id"], design[factor])}
