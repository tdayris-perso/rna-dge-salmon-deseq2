"""
On most clusters, cold and hot storage coexist. Non-expert users might
try to run IO intensive processes on data through cold storage and break
either the pipeline or the mounting points on a cluster. This rule
copies the fastq files.
More information at:
https://github.com/tdayris/yawn/tree/master/SnakemakeWrappers/cp/8.25
"""
rule copy_extra:
    input:
        config["ref"]["gtf"]
    output:
        get_gtf_path(config)
    message:
        "Copying reference genome annotaion"
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 128, 512)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 1440, 2832)
        )
    log:
        "logs/copy/copy_gtf.log"
    threads: 1
    params:
        extra = config["params"].get("copy_extra", ""),
        cold_storage = config.get("cold_storage", "NONE")
    wrapper:
        f"{git}/cp/bio/cp"
