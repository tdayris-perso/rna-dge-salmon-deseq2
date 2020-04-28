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
            lambda wildcards, attempt: attempt * 8192
        ),
        time_min = (
            lambda wildcards, attempt: attempt * 20
        )
    params:
        design = (
            lambda wildcards: config["models"][wildcards.design]
        )
    log:
        "logs/deseq2/DESeqDatasetFromTximport/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/DESeqDataSetFromTximport"


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
            lambda wildcards, attempt: attempt * 8192
        ),
        time_min = (
            lambda wildcards, attempt: attempt * 20
        )
    group:
        "deseq2-estimations"
    params:
        extra = config["params"].get("DESeq2_estimateSizeFactors_extra", "")
    log:
        "logs/deseq2/estimateSizeFactors/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/estimateSizeFactors"


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
            lambda wildcards, attempt: attempt * 8192
        ),
        time_min = (
            lambda wildcards, attempt: attempt * 20
        )
    group:
        "deseq2-estimations"
    params:
        extra = config["params"].get("DESeq2_estimateDispersions_extra", "")
    log:
        "logs/deseq2/estimateDispersions/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/estimateDispersions"


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
            lambda wildcards, attempt: attempt * 8192
        ),
        time_min = (
            lambda wildcards, attempt: attempt * 20
        )
    params:
        extra = "blind = TRUE, nsub = 10, fitType = 'local'"
    group:
        "deseq2-estimations"
    log:
        "logs/deseq2/vst/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/vst"


"""
This rule computes rlog Transformation on a DESeq2 dataset
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/deseq2-rlog/bio/deseq2/rlog
"""
rule rlog:
    input:
        dds = "deseq2/{design}/estimatedDispersions.RDS"
    output:
        rds = "deseq2/{design}/rlog.RDS",
        tsv = temp("deseq2/{design}/rlog.tsv")
    message:
        "Building rlog transformation over {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: attempt * 8192
        ),
        time_min = (
            lambda wildcards, attempt: attempt * 20
        )
    params:
        extra = config["params"].get("DESeq2_rlog_extra", "")
    group:
        "deseq2-estimations"
    log:
        "logs/deseq2/rlog/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/rlog"


"""
This rule performs a wald test on a DESeq2 dataset.
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/deseq2-waldtest/bio/deseq2/nbinomWaldTest
"""
checkpoint nbinomWaldTest:
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
            lambda wildcards, attempt: attempt * 8192
        ),
        time_min = (
            lambda wildcards, attempt: attempt * 20
        )
    params:
        alpha_threshold = config["thresholds"].get("alpha_threshold", 0.05),
        fc_threshold = config["thresholds"].get("fc_threshold", 1),
        extra = config["params"].get("DESeq2_nbinomWaldTest_extra", "")
    log:
        "logs/deseq2/nbinomWaldTest/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/nbinomWaldTest"


"""
This rule reports the results as a HTML page
More information at: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/bio/deseq2/report
"""
rule DESeq2_report:
    input:
        gseapp_tsv = "GSEA/{design}/{name}.complete.tsv",
        volcano = "figures/Volcano_plot/{design}/Volcano_{name}.png",
        pval_hist = "figures/pval_histogram/{design}/{name}_pval_histogram.png",
        maplot = "figures/{design}/plotMA/plotMA_{name}.png",
        coldata = config["design"],
        pca = "figures/{design}/pca.png",
        pca_scree = "figures/{design}/pca_scree.png",
        pca_corrs = "figures/{design}/pcacorrs.png",
        distro_expr = "figures/{design}/distro_expr.png"
    output:
        html = "Reports/{design}/Report_{name}.html"
    message:
        "Building report based on {wildcards.design} and {wildcards.name}"
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
        alpha_threshold = config["thresholds"].get("alpha_threshold", 0.05),
        fc_threshold = config["thresholds"].get("fc_threshold", 1),
        results_name = (
            lambda wildcards: f"{wildcards.design} : {wildcards.name}"
        )
    log:
        "logs/DESeq2_report/Report_{design}_{name}.log"
    wrapper:
        f"{git}/bio/deseq2/IGR_report"


rule plotMA:
    input:
        res = "deseq2/{design}/TSV/Deseq2_{name}.tsv"
    output:
        png = "figures/{design}/plotMA/plotMA_{name}.png"
    message:
        "Building MAplot for {wildcards.design}, considering {wildcards.name}"
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
        alpha_threshold = config["thresholds"].get("alpha_threshold", 0.05)
    log:
        "logs/plotMA/plotma_{design}_{name}.log"
    wrapper:
        f"{git}/bio/deseq2/plotMA"

rule zip_reports:
    input:
        htmls = lambda wildcards: deseq2_reports(wildcards)
    output:
        "reports.{design}.tar.bz2"
    message:
        "Tar bzipping all images for {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    conda:
        "../envs/bash.yaml"
    log:
        "logs/figures_archive/{design}.log"
    shell:
        "tar -cvjf {output} {input.htmls} > {log} 2>&1"
