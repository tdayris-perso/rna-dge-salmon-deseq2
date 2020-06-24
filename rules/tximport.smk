"""
This rule import salmon counts and possible inferential replicates
with R for further DESeq2 analysis
See: https://github.com/tdayris/snakemake-wrappers/tree/Unofficial/bio/tximport
"""
rule tximport:
    input:
        tx_to_gene = "tximport/tx_tab_gene.tsv",
        quant = expand("{dir}/quant.sf", dir = design.Salmon)
    output:
        txi = temp("tximport/txi.RDS")
    message:
        "Importing Salmon counts in R"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: attempt * 4096
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
        f"{git}/bio/tximport"


"""
This rule builds a super-set ot the tx2gene table required by tximport, from
a GTF file.
See: https://github.com/tdayris/snakemake-wrappers/tree/Unofficial/bio/tx_to_gene/gtf
"""
rule tx2gene:
    input:
        gtf = get_gtf_path(config)
    output:
        tsv = "tximport/transcript_to_gene_id_to_gene_name.tsv"
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
    params:
        gencode = True,
        header = True,
        positions = True
    log:
        "logs/tx2gene/transcript_to_gene_id_to_gene_name.log"
    wrapper:
        f"{git}/bio/gtf/tx2gene"



"""
This rule extracts gene coordinates from a GTF file
"""
rule gene2gene:
    input:
        gtf = get_gtf_path(config)
    output:
        tsv = "tximport/gene_id_to_gene_name.tsv"
    message:
        "Building gene ID to gene name correpsondacy table"
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
        gencode = True,
        header = True,
        positions = True
    log:
        "logs/gene2gene.log"
    wrapper:
        f"{git}/bio/gtf/gene2gene"


"""
This rule subsets the previous output in order to fit tximport's requirements
"""
rule tx2gene_subset:
    input:
        "tximport/transcript_to_gene_id_to_gene_name.tsv"
    output:
        temp("tximport/tx_tab_gene.tsv")
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
    conda:
        "../envs/bash.yaml"
    log:
        "logs/tx2gene/tx_tab_gene.log"
    shell:
        "awk 'BEGIN{{FS=\"\\t\"}} NR != 1 {{print $2 FS $1}}' "
        "{input} "
        "| sort "
        "| uniq "
        "> {output} "
        "2> {log}"
