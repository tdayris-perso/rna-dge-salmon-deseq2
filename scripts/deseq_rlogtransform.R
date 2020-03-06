#!/usr/bin/R

# This script takes a deseq2 dataset object and performs
# a regularized-logarithmic transformation on it

base::library("DESeq2");     # Differential Gene expression

# Cast input path as character
dds_path <- base::as.character(snakemake@input[["dds"]]);
dds <- base::readRDS(dds_path);

# Create object
rld <- DESeq2::rlog(dds);

# Save results
output_rds <- base::as.character(snakemake@output[["rds"]]);
base::saveRDS(
  obj = rld,
  file = output_rds
);


output_table <- base::as.character(snakemake@output[["tsv"]]);
tsv <- DESeq2::assay(rld);
base::write.table(
  obj = tsv,
  file = output_table,
  sep="\t"
);
