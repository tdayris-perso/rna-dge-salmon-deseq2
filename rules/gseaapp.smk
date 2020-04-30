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


"""
Subsets the tr2gene table in order to enhance the gseapp table
"""
rule subset_tr2gene:
    input:
        "tximport/tr2gene.tsv"
    output:
        "tximport/gene2gene.tsv"
    message:
        "Building Gene to Gene conversion table"
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
        "logs/gseaapp_filter/gene2gene.log"
    shell:
        "awk '{{print $1\"\\t\"$3}}' {input} > {output} 2> {log}"


"""
This rule clarifies the results of deseq2 in order to include gene names and
identifiers
"""
rule gseapp_clarify:
    input:
        tsv = "GSEA/{design}/{factor}.complete.tsv",
        tx2gene = "tximport/gene2gene.tsv"
    output:
        tsv = "GSEA/{design}/{factor}.enhanced.tsv"
    message:
        "Making GSEAapp human readable ({wildcards.design}/{wildcards.factor})"
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
        header = None,
        genes = True
    log:
        "logs/gseaapp_filter/{design}/{factor}.log"
    wrapper:
        f"{local}/bio/pandas/add_genes"
