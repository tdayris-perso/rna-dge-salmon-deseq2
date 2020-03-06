#!/usr/bin/R

base::library(package = "DESeq2");       # Read and load DESeq2 results
base::library(package = "pcaExplorer");  # Load pcaExplorer
base::library(package = "argparse");     # Handle command line parsing
base::message("Libraries loaded");


check_path <- function(path) {
  # A dumy function that checks paths before
  # loading anything.
  if (!base::file.exists(path)) {
    base::message(
      base::paste("Could not find", path, sep = " ")
    );
    base::quit(save = "no", status = 1);
  }
}


# Define command line parsing object
parser <- argparse::ArgumentParser(
  description = base::paste(
    "Launch pcaExplorer from a model name"
  )
);

parser$add_argument(
  "model",
  metavar = "MODEL",
  help = "Name of the model to display",
  type = "character"
);

parser$add_argument(
  "-d", "--design",
  metavar = "PATH",
  help = "Path to design file",
  default = "design.tsv"
);

opt <- parser$parse_args();
base::message("Argument parsed");

# Define input paths and check them
dds_path <- base::file.path(
  "deseq2",
  "disp_estimate",
  base::paste0(opt$model, ".RDS")
);
check_path(dds_path);

annotation_path <- base::file.path(
  "pcaexplorer",
  opt$model,
  base::paste0("annotation_", opt$model, ".RDS")
);
check_path(annotation_path);

limmago_path <- base::file.path(
  "pcaexplorer",
  opt$model,
  base::paste0("limmago_", opt$model, ".RDS")
);
check_path(limmago_path);

transform_path <- base::file.path(
  "deseq2",
  "vsd",
  base::paste0(opt$model, ".RDS")
);
if (!base::file.exists(transform_path)) {
  transform_path <- base::file.path(
    "deseq2",
    "rlog",
    base::paste0(opt$model, ".RDS")
  );
}
check_path(transform_path);

design_path <- base::as.character(
  x = opt$design
);
check_path(design);


# Load data
dds <- base::readRDS(dds_path);
base::message("DDS object loaded");
dst <- base::readRDS(transform_path);
base::message("Transformed counts object loaded");
annot <- base::readRDS(annotation_path);
base::message("Gene annotation object loaded");
limmago <- base::readRDS(limmago_path);
base::message("Limma PCA to GO object loaded");
design <- utils::read.table(
  design_path,
  sep = "\t",
  header = TRUE
);
base::message("Design loaded");

# Run pcaExplorer!
pcaExplorer::pcaExplorer(
  dds = dds,
  dst = dst,
  coldata = design,
  annotation = annot,
  runLocal = TRUE,
  pca2go = limmago
)
