#!/bin/bash


source bin/assert.sh
output=output/test4

nextflow main.nf -profile test,conda --output $output --input_bam `pwd`/test_data/TESTX_S1_L001.bam --input_name sample_name --skip_vqsr

test -s $output/sample_name/sample_name.hard_filters.vcf || { echo "Missing output VCF file!"; exit 1; }