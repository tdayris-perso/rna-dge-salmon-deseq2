This table contains the results of the differential gene expression analysis called `{{snakemake.wildcards.design}}`, considering `{{snakemake.wildcards.factor}}`.

It contains all the DESeq2 results with the following columns:

+----------------+------------------------------------------------------------------------+
| Column name    | Content                                                                |
+================+========================================================================+
| log2FoldChange | The log2 of the Fold Change                                            |
+----------------+------------------------------------------------------------------------+
| GeneIdentifier | The name of the gene                                                   |
+----------------+------------------------------------------------------------------------+
| Cluster_FC     | Weather the gene has a positive or a negative Fold Change              |
+----------------+------------------------------------------------------------------------+
| Cluster_Sig    | Weather the gene is differentially expressed under the alpha threshold |
+----------------+------------------------------------------------------------------------+
| padj           | The Adjusted P-Value                                                   |
+----------------+------------------------------------------------------------------------+

Do not use this file in GSEAapp on ShinyGR. It won't help.

This is a TSV file, you can open it with you favorite tabular editor (excel, LibreOffice, ...). First open your tabular editor, the click-and-drag your file into it.
