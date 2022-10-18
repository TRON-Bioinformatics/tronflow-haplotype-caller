#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { HAPLOTYPE_CALLER } from './modules/01_haplotype_caller'
include { VARIANT_ANNOTATOR; VARIANT_RECALIBRATOR; VQSR; VARIANT_FILTERING } from './modules/02_vqsr'

params.help= false
params.input_files = false
params.input_bam = false
params.input_name = false
params.reference = false
params.dbsnp = false
params.hapmap = false
params.thousand_genomes = false
params.intervals = false
params.output = 'output'
params.skip_vqsr = false


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
if (!params.skip_vqsr) {
    if (!params.dbsnp) {
        log.error "--dbsnp is required"
        exit 1
    }
    if (!params.hapmap) {
        log.error "--hapmap is required"
        exit 1
    }
    if (!params.thousand_genomes) {
        log.error "--thousand_genomes is required"
        exit 1
    }
}

// checks required inputs
if (params.input_files) {
  Channel
    .fromPath(params.input_files)
    .splitCsv(header: ['name', 'bam'], sep: "\t")
    .map{ row-> tuple(row.name, row.bam) }
    .set { input_files }
} else if (params.input_bam && params.input_name) {
  Channel
    .fromList([tuple(params.input_name, params.input_bam)])
    .set { input_files }
} else {
  exit 1, "Input file not specified!"
}

workflow {

    HAPLOTYPE_CALLER(
        input_files, 
        params.reference, 
        params.ploidy,
        params.dbsnp,
        params.intervals)

    VARIANT_ANNOTATOR(
        HAPLOTYPE_CALLER.out.unfiltered_vcfs)

    if (! params.skip_vqsr) {
        // applies Variant Quality Score Recalibration
        VARIANT_RECALIBRATOR(VARIANT_ANNOTATOR.out.annotated_vcfs)
        VQSR(VARIANT_RECALIBRATOR.out.recalibration)
        final_vcfs = VQSR.out.final_vcfs
    }
    else {
        // applies hard filters on variant calling results
        VARIANT_FILTERING(
            VARIANT_ANNOTATOR.out.annotated_vcfs, 
            params.reference)
        final_vcfs = VARIANT_FILTERING.out.final_vcfs
    }

    final_vcfs.map {it.join("\t")}.collectFile(name: "${params.output}/hc_output_files.txt", newLine: true)
}
