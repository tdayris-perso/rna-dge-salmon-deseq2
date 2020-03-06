#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script takes a directory containing result table(s), parses them all and
build a MA-plot for each result found.

The produced MA-plot will be available as:

- MultiQC compatible yam format

Soon:
- A png image
- A HTML widget
"""

# Maths
import pandas  # Handle large datasets
import numpy   # Handle vectors and maths

# Test IO
import logging  # Log activity
import yaml     # Handle Yaml IO
import sys      # System interactions

from pathlib import Path              # Easily handle paths
from snakemake.utils import makedirs  # Make directories recursively
from typing import Any, Dict, List    # Type hints
