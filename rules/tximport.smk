"""
This rule reads all the quantifications files given as input and return
a RDS file with all required information to perform further R analyses.
See more information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/tximport
"""
rule tximport:
    input:
        quant = rnacountsalmon(quant_file_list),
        tx_to_gene = "deseq2/tx2gene.tsv"
    output:
        txi = "tximport/txi.RDS"
    message:
        "Importing quantification results within R"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 30, 120)
        )
    params:
        extra = config["params"].get(
            "tximport",
            "type = 'salmon', txOut = TRUE"
        )
    wrapper:
        f"{git}/master/bio/tximport"


"""
This rule produces a transcript to gene table formatted as required by tximport
"""
rule tx2gene:
    input:
        gtf = rnacountsalmon("aggregated_salmon_counts/tr2gene.tsv")
    output:
        tsv = "deseq2/tx2gene.tsv"
    message:
        "Building transcript to gene table for Tximport"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 512, 1024)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 20)
        )
    log:
        "logs/tx2gene.log"
    shell:
        "awk 'BEGIN{{FS=\"\t\"}} "
        "{{print $1 FS $2}}' "
        "{input.gtf} "
        "> {output.tsv} "
        "2> {log}"
