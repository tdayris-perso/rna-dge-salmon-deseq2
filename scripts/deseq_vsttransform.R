#!/usr/bin/R

# This script takes a deseq2 dataset object and performs
# a variance stabilizing transformations transformation on it

base::library("DESeq2");                 # Differential Gene expression
base::library("SummarizedExperiment");   # Export results

# Cast input path as character
dds_path <- base::as.character(snakemake@input[["dds"]]);
dds <- base::readRDS(dds_path);

# Create object
vst <- DESeq2::vst(dds);

# Save results
output_rds <- base::as.character(snakemake@output[["rds"]]);
base::saveRDS(
  obj = vst,
  file = output_rds
);


output_table <- base::as.character(snakemake@output[["tsv"]]);
tsv <- SummarizedExperiment::assay(vst);
utils::write.csv(
  x = tsv,
  file = output_table,
  sep = "\t",
  quote = FALSE
);
