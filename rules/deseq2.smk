"""
This rule creates a DESeq2 dataset from a tximport RDS object
"""
rule deseq2_dataset_from_tximport:
    input:
        tximport = "tximport/txi.RDS",
        coldata = config["design"]
    output:
        dds = temp("deseq2/datasets/{model}.RDS")
    message:
        "Building DESeq2 dataset from tximport for {wildcards.model} "
        "({params.design})"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(10 + (attempt * 20), 50)
        )
    params:
        design = (
            lambda wildcards: get_fodmula_w(wildcards)
        )
    conda:
        "../envs/Renv.yaml"
    log:
        "logs/deseq2/datasets/{model}.log"
    wildcard_constraints:
        model = "|".join([i for i in config["params"]["models"].keys()])
    wrapper:
        f"{git}/deseq2_dataset/bio/deseq2/DESeqDataSetFromTximport"


"""
This rules computes size factors from a DESeq2 dataset
"""
rule deseq2_size_factors:
    input:
        dds = "deseq2/datasets/{model}.RDS"
    output:
        dds = temp("deseq2/size_factors/{model}.RDS")
    message:
        "Estimating size factors for {wildcards.model}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 3072, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(20 + (attempt * 10), 50)
        )
    conda:
        "../envs/Renv.yaml"
    params:
        extra = config["params"].get(
            "locfunc",
            "locfunc=base::eval(base::as.name('median'))"
        )
    log:
        "logs/deseq2/size_factors/{model}.log"
    wildcard_constraints:
        model = "|".join([i for i in config["params"]["models"].keys()])
    wrapper:
        f"{git}/deseq2-estimateSizeFactors/bio/deseq2/estimateSizeFactors"


"""
This rule estimates dispersion among samples based on ad DESeq2 dataset
"""
rule deseq2_estimate_dispersion:
    input:
        dds = "deseq2/size_factors/{model}.RDS"
    output:
        disp = temp("deseq2/disp_estimate/{model}.RDS")
    message:
        "Estimating dispersions for {wildcards.model}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 3072, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(20 + (attempt * 10), 50)
        )
    conda:
        "../envs/Renv.yaml"
    params:
        extra = config["params"].get("fittype", "fitType='mean'")
    log:
        "logs/deseq2/dispersions/{model}.log"
    wildcard_constraints:
        model = "|".join([i for i in config["params"]["models"].keys()])
    wrapper:
        f"{git}/deseq2-disp.R/bio/deseq2/estimateDispersions"

"""
This rule performs the negative binomial tests to find differentially
expressed genes
"""
rule deseq2_wald_test:
    input:
        dds = "deseq2/disp_estimate/{model}.RDS"
    output:
        rds = "deseq2/wald_test/{model}.RDS",
        tsv = directory("deseq2/wald_test/{model}_TSV/")
    message:
        "Testing differentially expressed genes according to {wildcards.model}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(30 + (attempt * 10), 80)
        )
    conda:
        "../envs/Renv.yaml"
    log:
        "logs/deseq2/wald_test/{model}.log"
    wildcard_constraints:
        model = "|".join([i for i in config["params"]["models"].keys()])
    wrapper:
        f"{git}/deseq2-waldtest/bio/deseq2/nbinomWaldTest"


"""
This rule computes variant stabilized transformation on counts, based on
previous estimations
"""
rule deseq2_vst:
    input:
        dds = "deseq2/disp_estimate/{model}.RDS"
    output:
        rds = "deseq2/vsd/{model}.RDS",
        tsv = "deseq2/vsd/{model}.tsv"
    message:
        "Building variant stabilized data on {wildcards.model}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(30 + (attempt * 10), 80)
        )
    conda:
        "../envs/Renv.yaml"
    log:
        "logs/deseq2/vst/{model}.log"
    wildcard_constraints:
        model = "|".join([i for i in config["params"]["models"].keys()])
    wrapper:
        f"{git}/deseq2-vst/bio/deseq2/vst"
