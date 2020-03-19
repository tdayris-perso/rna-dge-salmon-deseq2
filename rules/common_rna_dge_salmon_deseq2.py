#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script contains functions used by Snakemake. They heva bee taken aside
of the common.smk in order to be tested
"""

import os
import sys

script_path = os.sep.join([
    os.path.dirname(os.path.abspath(__file__)), "..", "scripts"
])
sys.path.append(script_path)

try:
    from common_script_rna_dge_salmon_deseq2 import *
except ImportError:
    print(f"Could not find common_script_rna_count_salmon as {script_path}")
    raise
