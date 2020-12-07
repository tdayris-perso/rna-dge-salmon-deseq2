rule prepare_multiqc:
    input:
        pairwise_scatterplot = "figures/{design}/pairwise_scatterplot_{design}.png",
        volcanoplot = "figures/{design}/Volcano_{design}.png",
        distro_expr = "figures/{design}/distro_expr_{design}.png",
        pca_axes_correlation = "figures/{design}/pcacorrs_{design}.png"
    output:
        multiqc_config = "multiqc/{design}/multiqc_config.yaml",
        plots = [
            temp("multiqc/{design}/pairwise_scatterplot_mqc.png"),
            temp("multiqc/{design}/volcanoplot_mqc.png"),
            temp("multiqc/{design}/distro_expr_mqc.png"),
            temp("multiqc/{design}/pca_axes_correlation_mqc.png")
        ]
    message:
        "Building MultiQC configuration for {wildcards.design}"
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
        title = "Quality controls for Differential Gene Expression (DGE)",
        subtitle = "Result tables shall be found apart from this file",
        show_analysis_paths = False,
        show_analysis_time = True,
        custom_logo = 'images/IGR_Logo.jpeg',
        custom_logo_url = 'https://gitlab.com/bioinfo_gustaveroussy/bigr',
        custom_logo_title = 'BiGR, Gustave Roussy Intitute',
        report_header_info = [
            {"Data Type": "RNA-seq"},
            {"Analysis Type": "Differential Gene Expression"}
        ]
    log:
        "logs/multiqc/config_{design}.log"
    wrapper:
        f"{git}/bio/BiGR/multiqc_rnaseq_report"


rule multiqc:
    input:
        multiqc_config = "multiqc/{design}/multiqc_config.yaml",
        plots = [
            "multiqc/{design}/pairwise_scatterplot_mqc.png",
            "multiqc/{design}/volcanoplot_mqc.png",
            "multiqc/{design}/distro_expr_mqc.png",
            "multiqc/{design}/ma_plot_mqc.png",
            "multiqc/{design}/pca_axes_correlation_mqc.png"
        ],
        salmon = design.Salmon.tolist()
    output:
        report(
            "multiqc/{design}/report.html",
            caption="../report/multiqc.rst",
            category="7. DGE Reports",
            subcategory="{design}"
        )
    message:
        "Building quality report for {wildcards.design}"
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
        lambda w: f" --config multiqc/{w.design}/multiqc_config.yaml "
    log:
        "logs/multiqc/report/{design}.log"
    wrapper:
        f"{git}/bio/multiqc"
