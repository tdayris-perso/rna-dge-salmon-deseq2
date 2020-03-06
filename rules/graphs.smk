"""
This rule performs MAplot from DEseq2 final results
"""
rule maplot:
    input:
        tsv = "deseq2/wald_test/{model}.tsv"
    output:
        yaml = "qc/multiqc_config/maplot/maplot_{model}.yaml"
    message:
        "Building a MAplot for {wildcards.model}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 30, 120)
        )
    script:
        "../scripts/maplot.py"
