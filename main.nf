#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { HAPLOTYPE_CALLER } from './modules/01_haplotype_caller'
include { VARIANT_ANNOTATOR; VARIANT_RECALIBRATOR; VQSR } from './modules/02_vqsr'

params.help= false
params.input_files = false
params.reference = false
params.dbsnp = false
params.hapmap = false
params.thousand_genomes = false
params.intervals = false
params.output = 'output'
params.memory_haplotype_caller = "16g"
params.cpus_haplotype_caller = 2
params.memory_cnn_score_variants = "16g"
params.cpus_cnn_score_variants = 2
params.memory_filter_variant_tranches = "16g"
params.cpus_filter_variant_tranches = 2


def helpMessage() {
    log.info params.help_message
}

if (params.help) {
    helpMessage()
    exit 0
}
if (!params.reference) {
    log.error "--reference is required"
    exit 1
}
if (!params.dbsnp) {
    log.error "--dbsnp is required"
    exit 1
}

// checks required inputs
if (params.input_files) {
  Channel
    .fromPath(params.input_files)
    .splitCsv(header: ['name', 'bam'], sep: "\t")
    .map{ row-> tuple(row.name, row.bam) }
    .set { input_files }
} else {
  exit 1, "Input file not specified!"
}

workflow {
    HAPLOTYPE_CALLER(input_files)
    VARIANT_ANNOTATOR(HAPLOTYPE_CALLER.out.unfiltered_vcfs)
    VARIANT_RECALIBRATOR(VARIANT_ANNOTATOR.out.annotated_vcfs)
    VQSR(VARIANT_RECALIBRATOR.out.recalibration)

    //CNN_WRITE_TENSORS(HAPLOTYPE_CALLER.out.unfiltered_vcfs)
    //CNN_VARIANT_TRAIN(CNN_WRITE_TENSORS.out.cnn_tensor_folder)
    //CNN_SCORE_VARIANTS(HAPLOTYPE_CALLER.out.unfiltered_vcfs)
    //FILTER_VARIANT_TRANCHES(CNN_SCORE_VARIANTS.out.cnn_annotated_vcfs)

    VQSR.out.final_vcfs.map {it.join("\t")}.collectFile(name: "${params.output}/hc_output_files.txt", newLine: true)
}
