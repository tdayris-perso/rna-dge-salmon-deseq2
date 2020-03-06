"""
This rule computes each missing object required by pcaExplorer to run
a fully functionnal Shiny server.

Then, use the provided Rscript to launch the shiny server.
"""
rule prepare_pca_explorer:
    input:
        dds = "deseq2/disp_estimate/{model}.RDS",
        dst = "deseq2/vsd/{model}.RDS",
        tr2gene = rnacountsalmon("aggregated_salmon_counts/tr2gene.tsv")
    output:
        annotation = "pcaexplorer/{model}/annotation_{model}.RDS",
        limmago = "pcaexplorer/{model}/limmago_{model}.RDS"
    message:
        "Building annotations and pca to GO for {wildcards.model}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 20480)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 80)
        )
    conda:
        "../envs/Renv.yaml"
    log:
        "logs/pcaExplorer/prepare/{model}.log"
    wildcard_constraints:
        model = "|".join([i for i in config["params"]["models"].keys()])
    script:
        "../scripts/pcaExplorer.R"
