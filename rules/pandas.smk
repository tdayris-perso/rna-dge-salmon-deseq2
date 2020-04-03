"""
This rule merges the salmon counts and annotates them.
More information at: https://github.com/tdayris-perso/snakemake-wrappers/blob/pandas-merge/bio/pandas/salmon
"""
rule aggregate:
    input:
        quant = expand(
            "{dir}/quant.genes.sf",
            dir=design.Salmon_quant.tolist()
        ),
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
        drop_null = True,
        genes = True
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
        png = expand(
            "figures/PCA/PCA_{factor}_{axes}.png",
            axes=[
                f"PC{i}_PC{j}"
                for i, j in itertools.permutations(range(1, 4, 1), 2)
            ],
            allow_missing=True
        )
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
        conditions = (
            lambda wildcards: get_condition_dict_w(wildcards.factor, design)
        ),
        prefix = (
            lambda wildcards: f"figures/PCA/PCA_{wildcards.factor}"
        ),
        samples_names = True
    log:
        "logs/pandas_pca/{factor}.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/pca"


"""
This rule performs a clustered heatmap based on TPM counts
More information: https://github.com/tdayris-perso/snakemake-wrappers/blob/pandas-merge/bio/seaborn/clustermap
"""
rule clustermap_samples:
    input:
        counts = "aggrgated_counts/TPM.tsv"
    output:
        png = "figures/Clustermap/Clustered_heatmap_{factor}.png"
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
        conditions = (
            lambda wildcards: get_condition_dict_w(wildcards.factor, design)
        ),
        factor = (
            lambda wildcards: wildcards.factor
        )
    log:
        "logs/clustermap/{factor}.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/clustermap"


"""
This rule creates a png image of the pvalue repartition across 0.1-discetized
histogramm
More information at: https://github.com/tdayris-perso/snakemake-wrappers/tree/pandas-merge/bio/seaborn/pval-histogram
"""
rule pval_histogram:
    input:
        deseq2 = "deseq2/{design}/TSV/Deseq2_{name}.tsv"
    output:
        png = "figures/pval_histogram/{design}/{name}_pval_histogram.png"
    message:
        "Building Adjusted P-Value histogram for {wildcards.design}"
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
        "logs/pval_histogram/{design}_{name}.log"
    wrapper:
        f"{git}/pandas-merge/bio/seaborn/pval-histogram"


"""
This rule archies all images into a single tarball
"""
rule figures_archive:
    input:
        pval_histograms = lambda wildcards: deseq2_png(wildcards)
    output:
        "figures.{design}.tar.bz2"
    message:
        "Tar bzipping all images for {wildcards.design}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    conda:
        "../envs/bash.yaml"
    log:
        "logs/figures_archive/{design}.log"
    shell:
        "tar -cvjf {output} {input.pval_histograms} > {log} 2>&1"
