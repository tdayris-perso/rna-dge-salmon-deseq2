"""
This rule merges the salmon counts and annotates them.
More information at: https://github.com/tdayris-perso/snakemake-wrappers/blob/pandas-merge/bio/pandas/salmon
"""
rule aggregate:
    input:
        quant = expand("pseudo_mapping/{sample}/quant.genes.sf"),
        tx2gene = "tximport/tr2gene.tsv"
    output:
        tsv = "aggrgated_counts/TPM.tsv"
    message:
        "Aggregating salmon counts"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1536, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 200)
        )
    params:
        gencode = True,
        drop_na = True,
        drop_null = True
    log:
        "logs/aggregate.log"
    wrapper:
        f"{git}/pandas-merge/bio/pandas/salmon"


"""
This rule builds a box-plot of non-null TPM counts, their mean and extremums.
More information: https://github.com/tdayris-perso/snakemake-wrappers/tree/pandas-merge/bio/seaborn/box-counts
"""
rule box_counts:
    input:
        counts = "aggrgated_counts/TPM.tsv"
    output:
        png = "figures/Box_plot_non_null_counts.png"
    message:
        "Plotting box plots of non-null TPM counts"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 200)
        )
    group:
        "seaborn-counts"
    params:
        drop_null = True
    log:
        "logs/box_counts.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/box-counts"


"""
This rule performs a pairwise scatterplot of non-null TPM counts
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/pandas-merge/bio/seaborn/pairwise-scatterplot
"""
rule pairwise_scatterplot:
    input:
        counts = "aggrgated_counts/TPM.tsv"
    output:
        png = "figures/pairwise_scatterplot.png"
    message:
        "Plotting pairwise-scatterplot on non-null TPM counts"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 15, 200)
        )
    group:
        "seaborn-counts"
    log:
        "logs/pairwise_scatterplot.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/pairwise-scatterplot"


"""
This rule performs a PCA plot of TPM counts
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/pandas-merge/bio/seaborn/pca
"""
rule pandas_pca:
    input:
        counts = "aggrgated_counts/TPM.tsv"
    output:
        png = "figure/PCA/PCA_{factor}.png"
    message:
        "Plotting PCA"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 200)
        )
    group:
        "seaborn-diff"
    params:
        conditions = get_condition_dict_w(wildcards)
    log:
        "logs/pandas_pca/{factor}.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/pca"


"""
This rule performs a clustered heatmap based on TPM counts
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/pandas-merge/bio/seaborn/clustermap
"""
rule clustermap:
    input:
        counts = "aggrgated_counts/TPM.tsv"
    output:
        png = "figure/Clustermap/Clustered_heatmap_{design}.png"
    message:
        "Building a clustered heatmap on TPM counts"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 200)
        )
    group:
        "seaborn-diff"
    params:
        conditions = get_condition_dict_w(wildcards)
    log:
        "logs/clustermap/{design}.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/clustermap"
