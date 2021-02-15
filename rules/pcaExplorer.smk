"""
This rule prepares an annotation designed to pcaExplorer.
More information: https://github.com/tdayris/snakemake-wrappers/blob/Unofficial/bio/pcaExplorer/annotation
"""
rule pcaexplorer_annot:
    input:
        dds = "deseq2/{design}/dds_{design}.RDS",
        tr2gene = "tximport/tx_gid_gn.tsv"
    output:
        annotation = "pcaExplorer/{design}/annotation_{design}.RDS"
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
    wildcard_constraints:
        design = "|".join(config["models"].keys())
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
        dds = "deseq2/{design}/dds_{design}.RDS",
        dst = "deseq2/{design}/Wald_{design}.RDS"
    output:
        limmago = "pcaExplorer/{design}/limmago_{design}.RDS"
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
    wildcard_constraints:
        design = "|".join(config["models"].keys())
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
        dst = "deseq2/{design}/Wald_{design}.RDS"
    output:
        png = report(
            "figures/{design}/distro_expr_{design}.png",
            caption="../report/distro_expr.rst",
            category="2. Distribution of Expressions",
            subcategory="{design}"
        )
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
    wildcard_constraints:
        design = "|".join(config["models"].keys())
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
        dst = "deseq2/{design}/Wald_{design}.RDS"
    output:
        png = report(
            "figures/{design}/pca_scree_{design}.png",
            caption="../report/pca_scree.rst",
            category="4. PCA",
            subcategory="{design}"
        )
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
    wildcard_constraints:
        design = "|".join(config["models"].keys())
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
        dst = "deseq2/{design}/Wald_{design}.RDS",
        dds = "deseq2/{design}/dds_{design}.RDS"
    output:
        png = report(
            "figures/{design}/pcacorrs_{design}.png",
            caption="../report/pca_corr.rst",
            category="4. PCA",
            subcategory="{design}"
        )
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
    wildcard_constraints:
        design = "|".join(config["models"].keys()),
	factor = lambda wildcards: config["models"][wildcards.design]["factor"]
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
        dst = "deseq2/{design}/Wald_{design}.RDS"
    output:
        png = report(
            "figures/{design}/pca/pca_{intgroup}_ax_{a}_ax_{b}_{elipse}.png",
            caption="../report/pca.rst",
            category="4. PCA",
            subcategory="{design}"
        )
    message:
        "Plotting PCA for {wildcards.design} ({wildcards.intgroup}:"
        "{wildcards.a}/{wildcards.b}:{wildcards.elipse})"
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
            lambda wildcards: f"intgroup = c('{wildcards.intgroup}'), ntop = 100, pcX = {wildcards.a}, pcY = {wildcards.b}, ellipse = {'TRUE' if wildcards.elipse == 'with_elipse' else 'FALSE'}"
        )
    log:
        "logs/pcaexplorer/PCA/design_{design}_ingroup_{intgroup}_ax_{a}_{b}_{elipse}.log"
    wrapper:
        f"{git}/bio/pcaExplorer/PCA"


"""
This rule produces a pairwise scatterplot between samples
"""
rule pcaexplorer_pair_corr:
    input:
        dst = "deseq2/{design}/Wald_{design}.RDS"
    output:
        png = report(
            "figures/{design}/pairwise_scatterplot_{design}.png",
            caption="../report/pcaexplorer_pair_corr.rst",
            category="3. Sample relationships",
            subcategory="{design}"
        )
    message:
        "Plotting pairwise scatterplot on {wildcards.design}"
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
        extra = config["params"].get("pcaexplorer_pair_corr", "pc=1")
    log:
        "logs/pcaexplorer/pairwise_scatterplot/{design}.log"
    wrapper:
        f"{git}/bio/pcaExplorer/pair_corr"


rule pcaExplorer_write_script:
    input:
        dds = "deseq2/{design}/dds_{design}.RDS",
        dst = "deseq2/{design}/Wald_{design}.RDS",
        annotation = "pcaExplorer/{design}/annotation_{design}.RDS",
        pca2go = "pcaExplorer/{design}/limmago_{design}.RDS",
        coldata = "deseq2/filtered_design.tsv"
    output:
        script = "pcaExplorer/{design}/pcaExplorer_launcher_{design}.R"
    message:
        "Building pcaExplorer launch script for {wildcards.design}"
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
        "logs/pcaExplorer/write_script/{design}.log"
    wrapper:
        f"{git}/bio/pcaExplorer/writeLaunchScript"
