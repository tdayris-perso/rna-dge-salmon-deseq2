rule :
    input:
        pairwise_scatterplot = "figures/{design}/pairwise_scatterplot_{design}.png",
        volcanoplot = "figures/{design}/Volcano_{intgroup}.png",
    output:
        multiqc_config = "multiqc/{design}_{intgroup}/multiqc_config.yaml",
        plots = [
            temp("multiqc/{design}_{intgroup}/pairwise_scatterplot_mqc.png"),
            temp("multiqc/{design}_{intgroup}/volcanoplot_mqc.png")
        ]
    message:
        "Building MultiQC configuration for {wildcards.design}"
        " ({wildcards.intgroup})"
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
        custom_logo = '../images/IGR_Logo.jpeg',
        custom_logo_url = 'https://gitlab.com/bioinfo_gustaveroussy/bigr',
        custom_logo_title = 'BiGR, Gustave Roussy Intitute',
        report_header_info = [
            {"Application Type": "RNA-seq DGE"}
        ]
    log:
        "logs/multiqc/config_{design}_{intgroup}.log"
    wrapper:
        f"{git}/bio/BiGR/multiqc_rnaseq_report"
        #"file:../../snakemake-wrappers/bio/BiGR/multiqc_rnaseq_report"


rule multiqc:
    input:
        multiqc_config = "multiqc/{design}_{intgroup}/multiqc_config.yaml",
        plots = [
            "multiqc/{design}_{intgroup}/pairwise_scatterplot_mqc.png",
            "multiqc/{design}_{intgroup}/volcanoplot_mqc.png"
        ]
    output:
        report(
            "multiqc/{design}_{intgroup}/report.html",
            caption="../report/multiqc.rst",
            category="Reports"
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
        lambda w: f"--config multiqc/{w.design}_{w.intgroup}/multiqc_config.yaml"
    log:
        "logs/multiqc/report/{design}_{intgroup}.log"
    wrapper:
        f"{git}/bio/multiqc"
