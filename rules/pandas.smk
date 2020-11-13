"""
This rule cleans the coldata file to build nicer reports
"""
rule clean_coldata:
    input:
        design = config["design"]
    output:
        tsv = report(
            "deseq2/filtered_design.tsv",
            category="1. Experimental design",
            caption="../report/exp_design.rst"
        )
    message:
        "Filtering design to produce human readable reports"
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
        filter_column = [
            "Sample_id",
            "Salmon_quant",
            "Upstream_file",
            "Downstream_file",
            "Salmon"
        ]
    log:
        "logs/design_filter/design_filter.log"
    wrapper:
        f"{git}/bio/pandas/filter_design"


"""
Plot clustered heatmap of samples among each others based on normalized counts
"""
rule seaborn_clustermap:
    input:
        counts = "deseq2/{design}/normalized_counts.tsv"
    output:
        png = report(
            "figures/{design}/sample_clustered_heatmap_{design}.png",
            caption="../report/clustermap_sample.rst",
            category="3. Sample relationships",
            subcategory="{design}"
        )
    message:
        "Building sample clustered heatmap on {wildcards.design}"
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
        conditions = lambda wildcards: dict(zip(design.Sample_id, design[wildcards.factor])),
        factor = lambda wildcards: wildcards.factor,
        ylabel_rotation = 0,
        xlabel_rotation = 90
    log:
        "logs/seaborn/clustermap/{design}.log"
    wrapper:
        f"{git}/bio/seaborn/clustermap"
