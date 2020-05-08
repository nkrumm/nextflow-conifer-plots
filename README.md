# Nextflow CoNIFER plots

A Nextflow pipeline for creating CoNIFER-adjusted CNV plots

### Running locally
To run on a local NGS server:
`nextflow run main.nf -profile singularity --assay OPXv6 --input test_data/205R06_F01_OPXv6_NB0199.CNV_bins.txt`

Currently supported assays:
*  OPXv6

### Porting to other environments
`singularity.munge_v4.5` is a singularity build file for creating a container with all necessary dependencies.

Supply a `--conifer_baselines_directory` parameter pointed to a directory containing CoNIFER baseline files.