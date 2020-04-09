"""
This rule prepares DESeq2 output for further use with IGR GSEA shiny portal
"""
rule deseq2_to_gseaapp:
    input:
        tsv = "deseq2/{design}/TSV/Deseq2_{name}.tsv"
    output:
        complete = "GSEA/{design}/{name}.complete.tsv"
    message:
        "Subsetting DESeq2 results for {wildcards.factor} ({wildcards.name})"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        complete_table_only = True
    log:
        "logs/deseq2_to_gseaapp/{design}/{name}.log"
    wrapper:
        f"{git}/pandas-merge/bio/padnas/deseq2_to_gseaapp"
