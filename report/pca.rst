PCA (Principal Component Analysis) is a common way to visualize sample diversity across the experiment.

This PCA has been built on axes `{snakemake.wildcards.a}` / `{snakemake.wildcards.b}`, on data normalized for `{snakemake.wildcards.design}` (`{snakemake.wildcards.intgroup}`). You may ask to add or remove ellipses on this graph, as well as sample names.

A PCA measures the variance between samples and plots them:

- Two point apart from each others are samples that are different from each others.
- Two point close to each others are sample that are similar to each others.

We expect sample from same conditions to be grouped together. In the best cases, a straight line could be drawn between studied conditions.
