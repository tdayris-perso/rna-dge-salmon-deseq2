"""
This rule import salmon counts and possible inferential replicates
with R for further DESeq2 analysis
"""
rule tximport:
    input:
        tx2gene = "tximport/tx2gene.tsv",
        quand = design.Salmon_quant
    output:
        txi = temp("tximport/txi.RDS")
    message:
        "Importing Salmon counts in R"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    params:
        extra = config["params"].get(
            "tximport_extra",
            "type = 'salmon', txOut = TRUE"
        )
    log:
        "logs/tximport.log"
    wrapper:
        f"{wrapper_version}/bio/tximport/"


"""
This rule builds a super-set ot the tx2gene table required by tximport, from
a GTF file.
"""
rule tx2gene:
    input:
        gtf = get_gtf_path(config)
    output:
        tsv = temp("tximport/tr2gene.tsv")
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
    group:
        "tx2gene"
    log:
        "logs/tx2gene/tx_to_gene.log"
    wrapper:
        f"{git}/tx_to_tgene/bio/tx_to_gene/gtf"


"""
This rule subsets the previous output in order to fit tximport's requirements
"""
rule tx2gene_subset:
    input:
        "tximport/tr2gene.tsv"
    output:
        temp("tximport/tx2gene.tsv")
    message:
        "Subsetting the tr2gene table"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 128, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 5, 200)
        )
    group:
        "tx2gene"
    log:
        "logs/tx2gene/subset.log"
    shell:
        "cut -f 1,3 {input} > {output} 2> {log}"
