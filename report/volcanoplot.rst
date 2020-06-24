The volcanoplot shows the repartition of genes across two dimensions: their log2(Fold Change) and the -log10(Adjusted PValue). This graph has been done for the comparison `{{snakemake.wildcards.design}}` (`{{snakemake.wildcards.intgroup}}`).

These log transformations are here for plotting convenience, otherise, the graph would be unreadable.

Each point is a gene. The higher the point, the greater is the confidence we have in the fact that it is differentially expressed according to our factor of interest. The more apart a point is from the center of the graph, the more differentially expressed it is.

You can ask your bioinformatician to highlight any gene of interest on this graph.

This is a png image, open it with your favorite image viewer.
