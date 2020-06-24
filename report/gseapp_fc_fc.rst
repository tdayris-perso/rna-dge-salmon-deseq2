This table contains the results of the differential gene expression analysis called `{{snakemake.wildcards.design}}`, considering `{{snakemake.wildcards.factor}}`.

It contains part of the DESeq2 results: it has been filtered over significative changes over the gene expression.

Use this file in GSEAapp in ShinyGR to answer questions like:

- Are genes in my pathway, differentially expressed?
- Is my pathway enriched in Up/Down regulated genes?
- Are Up/Down regulated genes from separated pathways?
- Is my pathway Up/Down regulated?

The file contains the following columns:

+----------------+---------------------------------------+
| Column         | Content                               |
+================+=======================================+
| stat_change    | The Fold Change                       |
+----------------+---------------------------------------+
| GeneIdentifier | The gene name                         |
+----------------+---------------------------------------+
| cluster        | Weather the gene is up/down regulated |
+----------------+---------------------------------------+

This is a TSV file, you can open it with you favorite tabular editor (excel, LibreOffice, ...). First open your tabular editor, the click-and-drag your file into it.
