"""
This rule prepares an annotation designed to pcaExplorer.
More information: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/bio/pcaExplorer/annotation
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
        "logs/pcaexplorer/{design}_annot.log"
    wrapper:
        f"{git}/bio/pcaExplorer/annotation"


"""
This rule performs a gene onthology enrichment analysis on pca axes with limma
More information: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/bio/pcaExplorer/limmago/
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
        extra = config["params"].get(
            "limmaquickpca2go_extra",
            "organism = 'Hs'"
        )
    log:
        "logs/limma_pca_to_go/{design}.log"
    wrapper:
        f"{git}/bio/pcaExplorer/limmago"


"""
This rule plots the distribution of the expression values.
More information at: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/pcaExplorer/distro_expr
"""
rule distro_expr:
    input:
        dst = "deseq2/{design}/rlog.RDS"
    output:
        png = "figures/{design}/distro_expr.png"
    message:
        "Building expression distribution plot for {wildcards.design}"
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
        extra = config["params"].get("pcaexplorer_distro_expr", "")
    log:
        "logs/pcaexplorer/{design}_distro_expr.log"

    wrapper:
        f"{git}/bio/pcaExplorer/distro_expr"

"""
This rule plots the PCA loadings.
More information at: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/pcaExplorer/CPAScree
"""
rule pca_scree:
    input:
        dst = "deseq2/{design}/rlog.RDS"
    output:
        png = "figures/{design}/pca_scree.png"
    message:
        "Building PCA scree for {wildcards.design}"
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
        extra = config["params"].get("pcaexplorer_scree", "")
    log:
        "logs/pcaexplorer/{design}_scree.log"
    wrapper:
        f"{git}/bio/pcaExplorer/PCAScree"

"""
This rule plots the correlations between design and pca axes.
More information at: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/pcaExplorer/plotCorrs
"""
rule pcaexplorer_pcacorrs:
    input:
        dst = "deseq2/{design}/rlog.RDS",
        dds = "deseq2/{design}/dds.RDS"
    output:
        png = "figures/{design}/pcacorrs.png"
    message:
        "Building PCA correlations for {wildcards.design}"
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
        extra = config["params"].get("pcaexplorer_pcacorrs", "")
    log:
        "logs/pcaexplorer/{design}_pcacorrs.log"
    wrapper:
        f"{git}/bio/pcaExplorer/plotCorrs"


"""
This rule plots the PCA
More information at: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/pcaExplorer/PCA
"""
rule pcaexplorer_pca:
    input:
        dst = "deseq2/{design}/rlog.RDS"
    output:
        png = "figures/{design}/pca.png"
    message:
        "Plotting PCA for {wildcards.design}"
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
        extra = (
            lambda wildcards: f"intgroup = c('{wildcards.design}'), ntop = 100, pcX = 1, pcY = 2, ellipse = TRUE")
    log:
        "logs/pcaexplorer/{design}_pca.log"
    wrapper:
        f"{git}/bio/pcaExplorer/PCA"
