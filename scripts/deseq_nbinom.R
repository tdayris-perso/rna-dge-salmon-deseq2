#!/usr/bin/R

# This script takes a deseq2 dataset object and performs
# a negative binomial wald test on it

base::library("DESeq2");     # Differential Gene expression

# Cast input path as character
dds_path <- base::as.character(
  x = snakemake@input[["dds"]]
);
dds <- base::readRDS(dds_path);

# Create object
wald <- DESeq2::nbinomWaldTest(
  object = dds
);

# Save results
output_rds <- base::as.character(
  x = snakemake@output[["rds"]]
);
base::saveRDS(
  obj = wald,
  file = output_rds
);


names <- DESeq2::resultsNames(
  object = wald
);

output_tsv <- base::as.character(
  x = snakemake@output[["tsv"]]
);

for (resultname in names) {
  results <- DESeq2::results(
    object = dds,
    contrast = resultname,
    independentFiltering = TRUE,
    alpha = snakemake@params[["alpha_threshold"]],
    lfcThreshold = snakemake@params[["fc_threshold"]],
    pAdjustMethod = "BH",
    cooksCutoff = TRUE
  );

  results_path <- base::file.path(
    output_tsv,
    base::paste0("Deseq2_", resultname)
  );

  utils::write.table(
    x = results,
    file = results_path,
    quote = FALSE,
    sep = "\t",
    row.names = FALSE
  );
}
