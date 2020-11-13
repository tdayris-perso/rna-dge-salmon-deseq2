"""
This rule prepares DESeq2 output for further use with IGR GSEA shiny portal
"""
rule deseq2_to_gseaapp:
    input:
        tsv = "deseq2/{design}/DESeq2_{design}.tsv",
        gene2gene = "tximport/gene2gene.tsv"
    output:
        complete = report(
            "GSEAapp/{design}/{design}_complete.tsv",
            caption="../report/gseapp_complete.rst",
            category="6. DGE Tables",
            subcategory="{design}"
        ),
        fc_fc = report(
            "GSEAapp/{design}/{design}_fc_fc.tsv",
            caption="../report/gseapp_fc_fc.rst",
            category="8. GSEAapp Shiny",
            subcategory="{design}"
        ),
        padj_fc = report(
            "GSEAapp/{design}/{design}_padj_fc.tsv",
            category="8. GSEAapp Shiny",
            caption="../report/gseapp_padj_fc.rst",
            subcategory="{design}"
        )
    message:
        "Subsetting DESeq2 results for {wildcards.design}"
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
        "logs/deseq2_to_gseaapp/{design}.log"
    wrapper:
        f"{git}/bio/pandas/deseq2_to_gseaapp"
