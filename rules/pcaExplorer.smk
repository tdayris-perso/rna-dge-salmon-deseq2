"""
This rule prepares an annotation designed to pcaExplorer.
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/pcaExplorer/bio/pcaExplorer/annotation
"""
rule pcaexplorer_annot:
    input:
        dds = "deseq2/{design}/dds.RDS",
        tr2gene = "tximport/tr2gene.tsv"
    output:
        annotation = "pcaExplorer/{design}/annotation.RDS"
    message:
        "Building annotation for pcaExplorer"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    log:
        "logs/pcaexplorer_annot/{design}.log"
    wrapper:
        f"{git}/pcaExplorer/bio/pcaExplorer/annotation"


"""
This rule performs a gene onthology enrichment analysis on pca axes with limma
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/pcaExplorer/bio/pcaExplorer/limmago/
"""
rule limma_pca_to_go:
    input:
        dds = "deseq2/{design}/dds.RDS",
        dst = "deseq2/{design}/rlog.RDS"
    output:
        limmago = "pcaExplorer/{design}/limmago.RDS"
    message:
        "Building GO-term enrichment based on PCA terms"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 35, 200)
        )
    params:
        organism = config.get("organism", "Hs").capitalize()
    log:
        "logs/limma_pca_to_go/{design}.log"
    wrapper:
        f"{git}/pcaExplorer/bio/pcaExplorer/limmago"
