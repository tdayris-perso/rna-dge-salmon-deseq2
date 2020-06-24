"""
This rule prepares DESeq2 output for further use with IGR GSEA shiny portal
"""
rule deseq2_to_gseaapp:
    input:
        tsv = "deseq2/{design}/TSV/Deseq2_{factor}.tsv",
        gene2gene = "tximport/gene_id_to_gene_name.tsv"
    output:
        complete = report(
            "GSEA/{design}/{factor}.complete.tsv",
            caption="../report/gseapp_complete.rst",
            category="DGE Results"
        ),
        fc_fc = report(
            "GSEA/{design}/{factor}.fc_fc.tsv",
            caption="../report/gseapp_fc_fc.rst",
            category="GSEAapp Shiny"
        ),
        padj_fc = report(
            "GSEA/{design}/{factor}.padj_fc.tsv",
            category="GSEAapp Shiny",
            caption="../report/gseapp_padj_fc.rst"
        )
    message:
        "Subsetting DESeq2 results for {wildcards.factor} ({wildcards.factor})"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    log:
        "logs/deseq2_to_gseaapp/{design}/{factor}.log"
    wrapper:
        f"{git}/bio/pandas/deseq2_to_gseaapp"


rule zip_gsea:
    input:
        htmls = lambda wildcards: gsea_tsv(wildcards)
    output:
        "GSEA/gsea.{design}.tar.bz2"
    message:
        "Tar bzipping all GSEAapp tables for {wildcards.design}"
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
        "logs/figures_archive/gsea_{design}.log"
    shell:
        "tar -cvjf {output} {input.htmls} > {log} 2>&1"
