#!/bin/bash


source bin/assert.sh
output=output/test2

echo -e "sample_name_with_replicates\t"`pwd`"/test_data/TESTX_S1_L001.bam,"`pwd`"/test_data/TESTX_S1_L001.bam" > test_data/test_input_with_replicates.txt
nextflow main.nf -profile test,conda --input_files test_data/test_input_with_replicates.txt --output $output --skip_vqsr

test -s $output/sample_name_with_replicates/sample_name_with_replicates.annotated.vcf || { echo "Missing output VCF file!"; exit 1; }