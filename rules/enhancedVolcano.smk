"""
This rule plots a Volano plot from a DESeq2 result file
See: https://github.com/tdayris/snakemake-wrappers/tree/Unofficial/bio/enhancedVolcano/volcano-deseq2
"""
rule volcanoplot:
    input:
        deseq2_tsv = "deseq2/{design}/TSV/Deseq2_{name}.tsv",
        wald = "deseq2/Condition_model/Wald.RDS"
    output:
        png = "figures/{design}/Volcano_{name}.png"
    message:
        "Building volcano plot ({wildcards.design}, {wildcards.name})"
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
        fc_threshold = config["thresholds"].get("fc_threshold", 1)
    log:
        "logs/volcanoplot/volcano_{design}_{name}.log"
    wrapper:
        f"{git}/bio/enhancedVolcano/volcano-deseq2"


rule zip_volcano:
    input:
        png = lambda wildcards: volcano_png(wildcards)
    output:
        "figures/{design}/Volcano.tar.bz2"
    message:
        "Tar bzipping all Volcano plots for {wildcards.design}"
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
        "logs/figures_archive/volcano_{design}.log"
    shell:
        "tar -cvjf {output} {input.png} > {log} 2>&1"
