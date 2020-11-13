#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script contains functions used by Snakemake. They heva bee taken aside
of the common.smk in order to be tested
"""

import itertools       # Handle iterators and comprehensions
import os              # OS related operations
import pandas          # Handle large datasets
import pytest          # Unit testing

from pathlib import Path                             # Easily handle paths
from typing import Any, Dict, Generator, List, Optional, Set   # Type hints


def get_gtf_path(config: Dict[str, Any]) -> Dict[str, str]:
    """
    Return a list of paths to soft linked genome annotaion
    """
    return f"genomes/{os.path.basename(config['ref']['gtf'])}"


def test_get_gtf_path() -> None:
    """
    This function tests the get_gtf_path function above
    """
    expected = "genomes/test.gtf"
    tested = get_gtf_path({'ref': {'gtf': 'test.gtf'}})
    assert expected == tested


def get_condition_dict_w(factor: Any, design: pandas.DataFrame) -> Dict[str, str]:
    """
    Return a dictionnary with:
    sample_id : condition
    """
    return dict(zip(design["Sample_id"], design[factor]))


def test_get_condition_dict_w() -> None:
    """
    Test the function get_condition_dict_w above
    """
    expected = {"name1": "factor1", "name2": "factor1", "name3": "factor2"}
    tested_data = pandas.DataFrame(
        {"my_factor": ["factor1", "factor1", "factor2"],
         "Sample_id": ["name1", "name2", "name3"],
         "other": ["other1", "other1", "other2"]}
    )
    tested = get_condition_dict_w("my_factor", tested_data)
    assert expected == tested


def get_groups(design: pandas.DataFrame,
                  columns_to_drop: Set[str],
                  nest: int = 2) -> Generator[str, None, None]:
    """
    Return the list of groups of interest
    """
    cols = set(design.columns) - columns_to_drop
    return itertools.chain(
        ":".join(map(str, j))
        for i in range(1, nest + 1, 1)
        for j in itertools.permutations(cols, i)
    )


def test_get_groups() -> None:
    """
    Test the above function get_groups
    """
    tested_data = pandas.DataFrame({
        "my_factor": {"name1": "factor1", "name2": "factor1"},
        "other_factor": "ok"
    })
    tested = sorted(list(get_groups(tested_data, set("None"), 2)))
    expected = sorted(['my_factor',
        'other_factor',
        'my_factor:other_factor',
        'other_factor:my_factor'
    ])
    assert expected == tested



def get_axes(max_axes: int = 10) -> Generator[List[int], None, None]:
    """
    Return axes for PCA plotting
    """
    return [
        (a, b)
        for a, b in itertools.combinations(range(1, max_axes + 1, 1), 2)
        if a + 1 == b
    ]


def test_get_axes() -> None:
    """
    Test the function get_axes above
    """
    expected = [(1, 2), (2, 3), (3, 4)]
    tested = get_axes(4)
    assert expected == tested


def add_target(config: Dict[str, Any],
               part: str,
               required: bool = False) -> bool:
    """
    Return wether a target should be included or not
    """
    pipeline = config.get("pipeline")
    if pipeline is None:
        return False

    pipeline_section = pipeline.get(part, False)
    if pipeline_section is False:
        return False

    return required


@pytest.mark.parametrize(
    "config, part, required, tested", [
        ({"pipeline": {"my_section": True}}, "my_section", True, True),
        ({}, "my_section", True, False),
        ({"pipeline": {"my_section": True}}, "my_section", False, False),
        ({"pipeline": {"my_section": False}}, "my_section", True, False)
    ]
)
def test_add_target(config: Dict[str, Any],
                    part: str,
                    required: bool,
                    tested: Any) -> None:
    """
    Test the above add_taget function with multiple inputs
    """
    assert add_target(config, part, required) == tested
