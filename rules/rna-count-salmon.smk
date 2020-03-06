"""
This rule calls quantification process from a subworkflow
More information about the subworkflow at:
https://github.com/tdayris-perso/rna-count-salmon
"""
subworkflow rnacountsalmon:
    workdir:
        config["rna_count_directory"]
    snakefile:
        "rna-count-salmon/Snakefile"
    configfile:
        os.sep.join([config["rna_count_directory"], "config.yaml"])
