"""
This rule prepares DESeq2 output for further use with IGR GSEA shiny portal
"""
rule deseq2_to_gseaapp:
    input:
        tsv = "deseq2/{design}/TSV/Deseq2_{factor}.tsv"
    output:
        complete = "GSEA/{design}/{factor}.complete.tsv"
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
