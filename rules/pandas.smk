"""
This rule cleans the coldata file to build nicer reports
"""
rule clean_coldata:
    input:
        design = config["design"]
    output:
        tsv = "deseq2/filtered_design.tsv"
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
        counts = ((
            "deseq2/{design}/rlog.tsv"
            if config["params"].get("use_rlog", True) is True
            else "deseq2/{design}/VST.tsv"
        ))
    output:
        png = report(
            "figures/{design}/sample_clustered_heatmap/sample_clustered_heatmap_{factor}.png",
            caption="../report/clustermap_sample.rst",
            category="Quality Control"
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
        "logs/seaborn/clustermap/{design}_{factor}.log"
    wrapper:
        f"{git}/bio/seaborn/clustermap"
