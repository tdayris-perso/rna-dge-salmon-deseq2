#!/usr/bin/R

# This script takes a deseq2 dataset object and estimates
# size factors for further normalization

base::library("DESeq2");     # Differential Gene expression

# Cast input path as character
dds_path <- base::as.character(snakemake@input[["dds"]]);
dds <- base::readRDS(dds_path);

# Cast locfunc as function name
locfunc <- base::as.name(snakemake@params[["locfunc"]]);

# Create object
dds <- DESeq2::estimateSizeFactors(dds, locfunc=eval(locfunc));

# Save as RDS
output_path <- base::as.character(snakemake@output[["esf"]]);
base::saveRDS(
  obj = dds,
  file = output_path
);
