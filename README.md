# TronFlow HaplotypeCaller

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/release/tron-bioinformatics/tronflow-haplotype-caller?sort=semver)
[![Run tests](https://github.com/TRON-Bioinformatics/tronflow-haplotype-caller/actions/workflows/automated_tests.yml/badge.svg?branch=master)](https://github.com/TRON-Bioinformatics/tronflow-haplotype-caller/actions/workflows/automated_tests.yml)
[![License](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)
[![Powered by Nextflow](https://img.shields.io/badge/powered%20by-Nextflow-orange.svg?style=flat&colorA=E1523D&colorB=007D8A)](https://www.nextflow.io/)

The TronFlow HaplotypeCaller pipeline is part of a collection of computational workflows for tumor-normal pair
somatic variant calling and now also germline variant calling.

Find the documentation here [![Documentation Status](https://readthedocs.org/projects/tronflow-docs/badge/?version=latest)](https://tronflow-docs.readthedocs.io/en/latest/?badge=latest)


This workflow implements the HaplotypeCaller best practices for a single sample as described here 
https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-. 
We do not use the experimental approach for filtering variants based on CNN, but instead the traditional approach.


## How to run it

Run it from GitHub as follows:
```
nextflow run tron-bioinformatics/tronflow-haplotype-caller -r v0.1.0 -profile conda --input_files $input \
--reference $reference \
--dbsnp $dbsnp \
--thousand_genomes 1000g.vcf \
--hapmap hapmap.vcf
```

Otherwise download the project and run as follows:
```
nextflow main.nf -profile conda --input_files $input --reference $reference \
--reference $reference \
--dbsnp $dbsnp \
--thousand_genomes 1000g.vcf \
--hapmap hapmap.vcf
```

Find the help as follows:
```
$ nextflow run tron-bioinformatics/tronflow-haplotype-caller --help
Usage:
    nextflow run tron-bioinformatics/tronflow-haplotype-caller -profile conda --input_files input_files \
    --reference reference.fasta \
    --dbsnp dbsnp.vcf \
    --thousand_genomes 1000g.vcf \
    --hapmap hapmap.vcf

Input:
    * input_files: the path to a tab-separated values file containing in each row the sample name, tumor bam and normal bam
    The input file does not have header!
    Example input file:
    name1	bam_file
    name2	bam_file_2
    * reference: path to the FASTA genome reference (indexes expected *.fai, *.dict)
    * dbsnp: path to the dbSNP resource (not required if --skip_vqsr)
    * thousand_genomes: path to the 1000 genomes + Omni resource as provided in the GATK bundle (not required if --skip_vqsr)
    * hapmap: path to the HapMap resource as provided in the GATK bundle (not required if --skip_vqsr)

Optional input:
    * ploidy: use this parameter to provide the ploidy of the sample (default: 2)
    * skip_vqsr: skips the Variant Quality Score Recalibration. The variant calls have higher quality but it requires resources not available for all organisms
    * intervals: path to a BED file containing the regions to analyse
    * output: the folder where to publish output
    * memory_haplotype_caller: the ammount of memory used by HaplotypeCaller (default: 16g)
    * cpus_haplotype_caller: the number of CPUs used by HaplotypeCaller (default: 2)
    * memory_filter: the ammount of memory used by the filter pipeline (default: 16g)
    * cpus_filter: the number of CPUs used by the filter pipeline (default: 2)

Output:
    * Output VCF
    * Other intermediate files
```

### Input tables

The table with BAM files expects two tab-separated columns without a header.
Multiple normal BAMs can be provided separated by commas.

| Sample name          |  Normal BAMs                  |
|----------------------|---------------------------------|
| sample_1             | /path/to/sample_1_normal.bam   |
| sample_2             | /path/to/sample_2_normal.bam,/path/to/sample_2_normal_2.bam   |
