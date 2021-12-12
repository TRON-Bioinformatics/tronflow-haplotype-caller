#!/bin/bash


source bin/assert.sh
output=output/test1

echo -e "sample_name\t"`pwd`"/test_data/TESTX_S1_L001.bam" > test_data/test_input.txt
nextflow main.nf -profile test,conda --output $output --input_files test_data/test_input.txt

test -s $output/sample_name/sample_name.hc.vcf || { echo "Missing output VCF file!"; exit 1; }