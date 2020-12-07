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
            "type='salmon', ignoreTxVersion=TRUE, ignoreAfterBar=TRUE"
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
        tx2gene_small = temp("tximport/tx_tab_gene.tsv"),
        tx2gene = temp("tximport/tx_gid_gn.tsv"),
        tx2gene_large = temp("tximport/tx2gene_with_position.tsv"),
        gene2gene_large = temp("tximport/gene2gene.tsv")
    message:
        "Building transcript to gene table for Tximport"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 4096)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 20)
        )
    group:
        "tx2gene"
    cache: True
    params:
        gencode = True,
        header = True,
        positions = True
    log:
        "logs/tx2gene/transcript_to_gene_id_to_gene_name.log"
    wrapper:
        f"{git}/bio/gtf/tx2gene"
