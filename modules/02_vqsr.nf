params.memory_filter = "16g"
params.cpus_filter = 2
params.output = 'output'
params.dbsnp = false
params.hapmap = false
params._1000g = false


process VARIANT_ANNOTATOR {
    cpus params.cpus_filter
    memory params.memory_filter
    tag "${name}"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0" : null)

    input:
    tuple val(name), file(vcf), val(bam)

    output:
    tuple val("${name}"), file("${name}.annotated.vcf"), emit: annotated_vcfs

    """
    gatk --java-options '-Xmx${params.memory_filter}' VariantAnnotator \
   --reference ${params.reference} \
   --input ${bam} \
   --variant ${vcf} \
   --annotation QualByDepth \
   --annotation MappingQuality \
   --annotation MappingQualityRankSumTest \
   --annotation ReadPosRankSumTest \
   --annotation FisherStrand \
   --annotation StrandOddsRatio \
   --output ${name}.annotated.vcf
    """
}

process VARIANT_RECALIBRATOR {
    cpus params.cpus_filter
    memory params.memory_filter
    tag "${name}"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0" : null)

    input:
    tuple val(name), file(vcf)

    output:
    tuple val("${name}"), file(vcf), file("output.tranches"), file("${name}.recalibrated.vcf"), emit: recalibration

    """
    gatk --java-options '-Xmx${params.memory_filter}' VariantRecalibrator \
    --reference ${params.reference} \
    --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${params.dbsnp} \
    --resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${params.hapmap} \
    --resource:1000G,known=false,training=true,truth=false,prior=10.0 ${params._1000g} \
    --variant ${vcf} \
    -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
    --mode BOTH \
    --output ${name}.recalibrated.vcf \
    --tranches-file output.tranches
    """
}

process VQSR {
    cpus params.cpus_filter
    memory params.memory_filter
    tag "${name}"
    publishDir "${params.output}/${name}", mode: "copy"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0" : null)

    input:
    tuple val(name), file(vcf), file(tranches_file), file(recalibration_file)

    output:
    tuple val("${name}"), file("${name}.hc.vcf"), emit: final_vcfs

    """
    gatk --java-options '-Xmx${params.memory_filter}' ApplyVQSR \
   --reference ${params.reference} \
   --variant ${vcf} \
   --output ${name}.hc.vcf \
   --ts_filter_level 99.0 \
   --tranches-file ${tranches_file} \
   --recal-file ${recalibration_file} \
   --mode BOTH
    """
}
