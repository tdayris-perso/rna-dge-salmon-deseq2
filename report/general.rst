Material and Methods:
#####################

Quality control were made on raw `FastQ <https://en.wikipedia.org/wiki/FASTQ_format>`_ files with FastQC. Quality reports were gathered with MultiQC. Abundance estimation was performed with Salmon. Optional parameters (if any) are listed below. Aggregation was performed with an in-house python script available in the `scripts` directory.

Quantification results were aggregated wuth `tximport <https://bioconductor.org/packages/release/bioc/html/tximport.html>`_ , and differential gene analysis was performed with `DESeq2 <https://bioconductor.org/packages/release/bioc/html/DESeq2.html>`_ , according to `this paper <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4712774/>`_ .

The following optional parameters were used in:

* tximport was run with the following arguments: `{{ snakemake.config.params.tximport }}`
* DESeq2 size factor estimation was run with the following arguments: `{{snakemake.config.params.DESeq2_estimateSizeFactors_extra}}`
* DESeq2 dispersion estimation used the following arguments: `{{snakemake.config.params.DESeq2_estimateDispersions_extra}}`
* DESeq2 wald test was performed with the following arguments: `{{snakemake.config.params.DESeq2_nbinomWaldTest_extra}}`
* pcaExplorer expression distribution was plotted with the following arguments: `{{snakemake.config.params.pcaexplorer_distro_expr}}`
* pcaExplorer pairwise scatterplot was built with the following arguments: `{{snakemake.config.params.pcaexplorer_pair_corr}}`
* pcaExplorer axes correlations was plotted with the following arguments: `{{snakemake.config.params.pcaexplorer_pcacorrs}}`
* pcaExplorer axes loadings were plotted with the following arguments: `{{snakemake.config.params.pcaexplorer_scree}}`

In-house scripts were used to chomp, filter and sort results content. Their details are available below.

The whole pipeline was powered by both `Snakemake <https://snakemake.readthedocs.io>`_ , and `SnakemakeWrappers <https://snakemake-wrappers.readthedocs.io/>`_ .

If you need any other information, please read the `Frequently Asked questions <https://github.com/tdayris-perso/rna-count-salmon#frequently-asked-questions-by-my-fellow-biologists-on-this-pipeline>`_ , then contact your bioinformatician if you're still in trouble.

Citations:
##########

Whole pipeline:
  Love, Michael I., Charlotte Soneson, and Rob Patro. "Swimming downstream: statistical analysis of differential transcript usage following Salmon quantification." F1000Research 7 (2018).

  https://www.bioconductor.org/packages/devel/workflows/vignettes/rnaseqDTU/inst/doc/rnaseqDTU.html

MultiQC
  EWELS, Philip, MAGNUSSON, Måns, LUNDIN, Sverker, et al. MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 2016, vol. 32, no 19, p. 3047-3048.

  https://multiqc.info/


EnhancedVolcano
  Blighe, K. "Enhancedvolcano: Publication-ready volcano plots with enhanced colouring and labeling." (2018).

  https://github.com/kevinblighe

FastQC
  ANDREWS, Simon, et al. FastQC: a quality control tool for high throughput sequence data. 2010.

  https://www.bioinformatics.babraham.ac.uk/projects/fastqc/

Salmon
  Patro, Rob, et al. “Salmon provides fast and bias-aware quantification of transcript expression.” Nature Methods (2017). Advanced Online Publication. doi: 10.1038/nmeth.4197.

  https://salmon.readthedocs.io/

tximport
  Love, Michael I., Charlotte Soneson, and Mark D. Robinson. "Importing transcript abundance datasets with tximport." dim (txi. inf. rep $ infReps $ sample1) 1.178136 (2017): 5.

  https://bioconductor.org/packages/release/bioc/html/tximport.html

DESeq2
  Love, M.I., Huber, W., Anders, S. (2014) Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. Genome Biology, 15:550. 10.1186/s13059-014-0550-8

  https://bioconductor.org/packages/release/bioc/html/DESeq2.html

Snakemake
  Köster, Johannes and Rahmann, Sven. “Snakemake - A scalable bioinformatics workflow engine”. Bioinformatics 2012.

  https://snakemake.readthedocs.io/
  https://snakemake-wrappers.readthedocs.io/
