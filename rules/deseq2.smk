"""
This rule builds a DESeq2 dataset from a tximport object
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/deseq2_dataset/bio/deseq2/DESeqDataSetFromTximport
"""
rule DESeqDatasetFromTximport:
    input:
        tximport = "tximport/txi.RDS",
        coldata = "deseq2/filtered_design.tsv"
    output:
        dds = temp("deseq2/{design}/dds_{design}.RDS")
    message:
        "Building DESeq2 dataset from tximport on {wildcards.design}. "
        "Factor: {params.factor}, Tested: {params.numerator} "
        "Reference: {params.denominator}, Formula: {params.formula}"
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
            lambda wildcards: config["models"][wildcards.design]["formula"]
        ),
        levels = lambda wildcards: [
            config["models"][wildcards.design]["denominator"],
            config["models"][wildcards.design]["numerator"]
        ],
        count_filter = min(len(design.Sample_id.tolist()), 10)
    log:
        "logs/deseq2/DESeqDatasetFromTximport/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/DESeqDataSetFromTximport"



"""
This rule performs default DESeq2 analysis on a dataset.
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/deseq2-waldtest/bio/deseq2/deseq
"""
rule deseq:
    input:
        dds = "deseq2/{design}/dds_{design}.RDS"
    output:
        rds = "deseq2/{design}/Wald_{design}.RDS",
        deseq2_tsv = "deseq2/{design}/DESeq2_{design}.tsv",
        normalized_counts = "deseq2/{design}/normalized_counts.tsv",
        dst = "deseq2/{design}/dst_{design}.RDS"
    message:
        "Performing DESeq2 analysis over {wildcards.design}"
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
        extra = config["params"].get("DESeq2_DESeq_extra", ""),
        factor = lambda w: config["models"][w.design]["factor"],
        numerator = lambda w: config["models"][w.design]["numerator"],
        denominator = lambda w: config["models"][w.design]["denominator"],
    log:
        "logs/deseq2/deseq/{design}.log"
    wrapper:
        f"{git}/bio/deseq2/DESeq"
