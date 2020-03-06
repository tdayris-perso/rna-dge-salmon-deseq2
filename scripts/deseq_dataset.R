#!/usr/bin/R

# This script takes a tximport object and builds a deseq2 dataset
# for each formula given to snakemake.

base::library("tximport");   # Perform actual count importation in R
base::library("readr");      # Read faster!
base::library("jsonlite");   # Importing inferential replicates
base::library("DESeq2");     # Differential Gene expression

# Cast input path as character
txi_rds_path <- base::as.character(snakemake@input[["tximport"]]);
txi <- base::readRDS(txi_rds_path);

# Load experimental design
design_path <- base::as.character(snakemake@input[["design"]]);
design <- utils::read.table(
  design_path,
  sep = "\t",
  header = TRUE
);

# Cast formula as formula instead of string
formula <- stats::as.formula(snakemake@params[["formula"]]);

# Create object
dds <- DESeq2::DESeqDataSetFromTximport(txi, design, formula);

# Save as RDS
output_path <- base::as.character(snakemake@output[["dds"]]);
base::saveRDS(
  obj = dds,
  file = output_path
);
