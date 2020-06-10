"""
This rule creates en entry object for cluster profiler
"""
checkpoint gene_list:
    input:
        rds = "deseq2/{design}/Wald.RDS"
    output:
        gene_lists = directory("clusterProfiler/{design}")
    message:
        "Building clusterProfiler's object for {wildcards.design}"
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
        alpha_threshold = config["thresholds"].get("alpha_threshold", 0.05),
        fc_threshold = config["thresholds"].get("fc_threshold", 1)
    log:
        "logs/gene_list/{design}.log"
    wrapper:
        f"{git}/bio/clusterProfiler/DESeq2_to_geneList"


"""
This rule performs a gene set enrichment over gene ontology database
"""
rule gse_go:
    input:
        rds = "clusterProfiler/{design}/{name}.RDS"
    output:
        rds = "clusterProfiler/GSEA_GO/{design}/{name}.RDS",
        tsv = "clusterProfiler/GSEA_GO/{design}/{name}.tsv"
    message:
        "GSEA on GO database ({wildcards.design}, {wildcards.name})"
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
        gseGO_extra = config["params"].get("gseGO_extra", "")
    log:
        "logs/gsea_go/{design}/{name}.log"
    wrapper:
        f"{git}/bio/clusterProfiler/gseGO"


"""
This rule plots a broadinstitute's GSEA-like plot
"""
rule gsea_plot:
    input:
        rds = "clusterProfiler/GSEA_GO/{design}/{name}.RDS"
    output:
        png = "figures/{design}/clusterProfiler/GSEA_GO/{name}.png"
    message:
        "Plotting GSEA results for {wildcards.design}, {wildcards.name}"
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
        extra = config["params"].get("gseaplot_extra", "")
    log:
        "logs/gsea_plot/{design}/{name}.log"
    wrapper:
        f"{git}/bio/clusterProfiler/gseaplot"


"""
This rule produces a barplot containing the results of GSEA on GO
"""
rule barplot_go:
    input:
        rds = "clusterProfiler/GSEA_GO/{design}/{name}.RDS"
    output:
        png = "figures/{design}/clusterProfiler/barplot/{name}.png"
    message:
        "Plotting histogram for {wildcards.design}, {wildcards.name}"
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
        barplot_extra = config["params"].get("barplot_extra", "")
    log:
        "logs/barplot_go/{design}/{name}.log"
    wrapper:
        f"{git}/bio/clusterProfiler/barplot"


rule zip_clusterProfiler:
    input:
        htmls = lambda wildcards: clusterProfiler_figures(wildcards)
    output:
        "figures.clusterProfiler.{design}.tar.bz2"
    message:
        "Tar bzipping all clusterProfiler images for {wildcards.design}"
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
        "logs/figures_archive/clusterProfiler_{design}.log"
    shell:
        "tar -cvjf {output} {input.htmls} > {log} 2>&1"
