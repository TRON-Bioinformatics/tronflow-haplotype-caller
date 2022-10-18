# TronFlow HaplotypeCaller

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/release/tron-bioinformatics/tronflow-haplotype-caller?sort=semver)
[![Run tests](https://github.com/TRON-Bioinformatics/tronflow-haplotype-caller/actions/workflows/automated_tests.yml/badge.svg?branch=master)](https://github.com/TRON-Bioinformatics/tronflow-haplotype-caller/actions/workflows/automated_tests.yml)
[![DOI](https://zenodo.org/badge/437462852.svg)](https://zenodo.org/badge/latestdoi/437462852)
[![License](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)
[![Powered by Nextflow](https://img.shields.io/badge/powered%20by-Nextflow-orange.svg?style=flat&colorA=E1523D&colorB=007D8A)](https://www.nextflow.io/)

The TronFlow HaplotypeCaller pipeline is part of a collection of computational workflows for tumor-normal pair
somatic variant calling and now also germline variant calling.

Find the documentation here [![Documentation Status](https://readthedocs.org/projects/tronflow-docs/badge/?version=latest)](https://tronflow-docs.readthedocs.io/en/latest/?badge=latest)


This workflow implements the HaplotypeCaller best practices for a single sample as described here 
https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-. 
The only exception is that by default we exclude soft clipped bases, this behaviour can be reverted using `--use_soft_clipped_bases`.

There are two steps:
- Variant calling with the HaplotypeCaller
- Variant filtering

For the variant filtering there are two different approaches in place.

When the resources for dbSNP, the 1000 Genomes Project results and HapMap are provided the we perform the traditional Variant Quality Score Recalibration approach. 

Alternatively, if `--skip_vqsr` is passed then a set of hard filters are applied. 
The default values for these filters are tuned for variant calling on RNA as described in (Brouard & Bissonnette, 2022).
The default values can be changed with `--indels_hard_filters` and `--snvs_hard_filters`.



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

For variant calling on RNA use the following parameters:
```
nextflow run tron-bioinformatics/tronflow-haplotype-caller -r v0.1.0 -profile conda --input_files $input \
--reference $reference \
--skip_vqsr \
--min_quality 20
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
    * input_bam: the one or more comma separated BAM files (alternative input to --input_files)
    * input_name: the sample name (alternative input to --input_files)
    * ploidy: use this parameter to provide the ploidy of the sample (default: 2)
    * skip_vqsr: skips the Variant Quality Score Recalibration. The variant calls have higher quality but it requires resources not available for all organisms
    * intervals: path to a BED file containing the regions to analyse
    * output: the folder where to publish output
    * memory_haplotype_caller: the ammount of memory used by HaplotypeCaller (default: 16g)
    * cpus_haplotype_caller: the number of CPUs used by HaplotypeCaller (default: 2)
    * memory_filter: the ammount of memory used by the filter pipeline (default: 16g)
    * cpus_filter: the number of CPUs used by the filter pipeline (default: 2)
    * min_quality: minimum HaplotypeCaller Phred confidence to emit a call (default: no filter)
    * use_soft_clipped_bases: enable the use of soft clipped bases
    * indels_hard_filters: when --skip_vqsr these hard filters are applied over indel calls (default: --cluster-window-size 35 --cluster-size 3 -filter "QD < 2.0" -filter-name "QD2" -filter "FS > 30.0" -filter-name "FS30" -filter "ReadPosRankSum < -20.0" -filter-name "ReadPosRankSum-20" )
    * snvs_hard_filters: when --skip_vqsr these hard filters are applied over SNV calls (default: --cluster-window-size 35 --cluster-size 3 -filter "QD < 2.0" -filter-name "QD2" -filter "FS > 30.0" -filter-name "FS30" -filter "SOR > 3.0" -filter-name "SOR3" -filter "MQ < 40.0" -filter-name "MQ40" -filter "MQRankSum < -12.5" -filter-name "MQRankSum-12.5" -filter "ReadPosRankSum < -8.0" -filter-name "ReadPosRankSum-8" )

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


## References

- Brouard, JS., Bissonnette, N. (2022). Variant Calling from RNA-seq Data Using the GATK Joint Genotyping Workflow. In: Ng, C., Piscuoglio, S. (eds) Variant Calling. Methods in Molecular Biology, vol 2493. Humana, New York, NY. https://doi.org/10.1007/978-1-0716-2293-3_13
- RNAseq short variant discovery (SNPs + Indels). https://gatk.broadinstitute.org/hc/en-us/articles/360035531192-RNAseq-short-variant-discovery-SNPs-Indels-