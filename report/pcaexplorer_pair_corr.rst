Sample pairwise correlation is a common way to study sample divergence across the whole experiment. Here, this pairwise correlation has been built on normalization for `{{snakemake.wildcards.design}}`.

The correlation coefficient used vary from 0 to 1:

- 1 = Identical
- 1 > 0.95 = Almost identical (cell lines, technical replicates)
- 0.95 > 0.90 = Large similarities (Mice with same origins)
- 0.90 > 0.75 = Large variations (Human inter-individual variation)
- > 0.75 = Very important variations

We expect samples from the same condition to be similar to each others (i.e. high correlation coefficient), while being different from other samples (relatively lower correlation coefficient).

This is a png image, open it with your favorite image viewer.
