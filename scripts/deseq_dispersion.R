#!/usr/bin/R

# This script takes a deseq2 dataset and estimates dispersion
# among samples for further normalization

base::library("DESeq2");     # Differential Gene expression

# Cast input path as character
dds_path <- base::as.character(snakemake@input[["esf"]]);
dds <- base::readRDS(dds_path);

# Cast locfunc as function name
fittype <- base::as.character(snakemake@params[["fittype"]]);

# Create object
dds <- DESeq2::estimateDispersions(dds, fitType=fittype);

# Save as RDS
output_path <- base::as.character(snakemake@output[["disp"]]);
base::saveRDS(
  obj = dds,
  file = output_path
);
