#!/usr/bin/R

# This script takes a deseq2 dataset object and performs
# a regularized-logarithmic transformation on it

base::library(package = "DESeq2");        # Differential Gene expression
base::library(package = "pcaExplorer");   # Handles PCA
base::library(package = "DelayedArray");  # Handle in-memory array-like datasets

# Load specified input files
dds_path <- base::as.character(
  x = snakemake@input[["dds"]]
);
dds <- base::readRDS(file = dds_path);

dst_path <- base::as.character(
  x = snakemake@input[["dst"]]
);
dst <- base::readRDS(file = dst_path);

tx2gene_path <- base::as.character(
  x = snakemake@input[["tr2gene"]]
);
tx2gene <- utils::read.table(
  file = tx2gene_path,
  sep = "\t",
  header = FALSE,
  stringsAsFactors = FALSE
);


# Building dedicated annotation for pcaExplorer
tx2gene <- tx2gene[, c("V1", "V3")];
IRanges::colnames(tx2gene) <- c("gene_id", "gene_name");
tx2gene <- DelayedArray::unique(tx2gene);
base::row.names(tx2gene) <- tx2gene$gene_id;

gene_names <- tx2gene[base::row.names(x = dds), ];
gene_names$gene_id <- NULL;
annotation <- base::data.frame(
  gene_name = gene_names,
  row.name = IRanges::rownames(x = dds),
  stringsAsFactors = FALSE
);

annot_output <- base::as.character(
  x = snakemake@output[["annotation"]]
);
base::saveRDS(
  object = annotation,
  file = annot_output
);


# Building limmago
bg_ids <- IRanges::rownames(x = dds)[
  DelayedArray::rowSums(x = DESeq2::counts(dds)) > 0
];

limmago <- pcaExplorer::limmaquickpca2go(
  se = dst,
  organism = snakemake@params[["organism"]],
  background_genes = bg_ids,
  inputType = "ENSEMBL"
);
limmago_output <- base::as.character(
  x = snakemake@output[["limmago"]]
);
base::saveRDS(
  object = limmago,
  file = limmago_output
);
