#!/usr/bin/python3.7
# -*- coding: utf-8 -*-


"""
This script contains functions that are to be called by any other scripts in
this pipeline.
"""


import argparse        # Argument parsing
import itertools       # Handle iterators and comprehensions
import pandas          # Handle large datasets
import os              # OS related operations
import yaml            # Handle Yaml IO

from pathlib import Path                             # Easily handle paths
from typing import Any, Dict, Generator, List, Set   # Type hints


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
    return dict(zip(design["Sample_id"], design[factor]))


def get_intgroups(design: pandas.DataFrame,
                  columns_to_drop: Set[str],
                  nest: int = 2) -> Generator[str, None, None]:
    """
    Return the list of intgroups
    """
    cols = set(design.columns) - columns_to_drop
    return itertools.chain(
        ":".join(map(str, j))
        for i in range(1, nest + 1, 1)
        for j in itertools.permutations(cols, i)
    )


def get_axes(max_axes: int = 10) -> Generator[List[int], None, None]:
    """
    Return axes for PCA plotting
    """
    return [
        (a, b)
        for a, b in itertools.combinations(range(1, max_axes + 1, 1), 2)
        if a + 1 == b
    ]
