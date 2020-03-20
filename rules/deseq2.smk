"""
This rule builds a DESeq2 dataset from a tximport object
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/deseq2_dataset/bio/deseq2/DESeqDataSetFromTximport
"""
rule DESeqDatasetFromTximport:
    input:
        tximport = "tximport/txi.RDS",
        coldata = config["design"]
    output:
        dds = temp("deseq2/{design}/dds.RDS")
    message:
        "Building DESeq2 dataset from tximport on {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    params:
        design = (
            lambda wildcards: config["models"][wildcards.design]
        )
    log:
        "logs/deseq2/DESeqDatasetFromTximport/{design}.log"
    wrapper:
        f"{git}/deseq2_dataset/bio/deseq2/DESeqDataSetFromTximport/"


"""
This rule estimates size factors from a DESeq2 dataset
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/deseq2-estimateSizeFactors/bio/deseq2/estimateSizeFactors
"""
rule estimateSizeFactors:
    input:
        dds = "deseq2/{design}/dds.RDS"
    output:
        dds = temp("deseq2/{design}/estimatedSizeFactors.RDS")
    message:
        "Estimating size factors on {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    group:
        "deseq2-estimations"
    log:
        "logs/deseq2/estimateSizeFactors/{design}.log"
    wrapper:
        f"{git}/deseq2-estimateSizeFactors/bio/deseq2/estimateSizeFactors"


"""
This rule estimates sample dispersion from a deseq2 dataset
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/deseq2-disp.R/bio/deseq2/estimateDispersions
"""
rule estimateDispersions:
    input:
        dds = "deseq2/{design}/estimatedSizeFactors.RDS"
    output:
        disp = temp("deseq2/{design}/estimatedDispersions.RDS")
    message:
        "Estimating dispersions in {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    group:
        "deseq2-estimations"
    log:
        "logs/deseq2/estimateDispersions/{design}.log"
    wrapper:
        f"{git}/deseq2-disp.R/bio/deseq2/estimateDispersions"


"""
This rule computes Variance Stabilized Transformation on a DESeq2 dataset
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/deseq2-vst/bio/deseq2/vst
"""
rule vst:
    input:
        dds = "deseq2/{design}/estimatedDispersions.RDS"
    output:
        rds = "deseq2/{design}/VST.RDS",
        tsv = temp("deseq2/{design}/VST.tsv")
    message:
        "Building variance stabilized transformation over {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    params:
        extra = "nsub = 10, fitType = 'local'"
    group:
        "deseq2-estimations"
    log:
        "logs/deseq2/vst/{design}.log"
    wrapper:
        f"{git}/deseq2-vst/bio/deseq2/vst"


"""
This rule performs a wald test on a DESeq2 dataset.
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/deseq2-waldtest/bio/deseq2/nbinomWaldTest
"""
rule nbinomWaldTest:
    input:
        dds = "deseq2/{design}/estimatedDispersions.RDS"
    output:
        rds = "deseq2/{design}/Wald.RDS",
        tsv = directory("deseq2/{design}/TSV/")
    message:
        "Performing Wald tests over {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 3072, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    log:
        "logs/deseq2/nbinomWaldTest/{design}.log"
    wrapper:
        f"{git}/deseq2-waldtest/bio/deseq2/nbinomWaldTest"
