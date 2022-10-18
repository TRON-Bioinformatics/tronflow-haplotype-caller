params.memory_filter = "16g"
params.cpus_filter = 2
params.output = 'output'
params.dbsnp = false
params.hapmap = false
params.thousand_genomes = false
params.memory_cnn_score_variants = "16g"
params.cpus_cnn_score_variants = 2
params.memory_filter_variant_tranches = "16g"
params.cpus_filter_variant_tranches = 2

params.indels_hard_filters = """--cluster-window-size 35 \
        --cluster-size 3 \
        -filter "QD < 2.0" -filter-name "QD2" \
        -filter "FS > 30.0" -filter-name "FS30" \
        -filter "ReadPosRankSum < -20.0" -filter-name "ReadPosRankSum-20" """
params.snvs_hard_filters = """--cluster-window-size 35 \
        --cluster-size 3 \
        -filter "QD < 2.0" -filter-name "QD2" \
        -filter "FS > 30.0" -filter-name "FS30" \
        -filter "SOR > 3.0" -filter-name "SOR3" \
        -filter "MQ < 40.0" -filter-name "MQ40" \
        -filter "MQRankSum < -12.5" -filter-name "MQRankSum-12.5" \
        -filter "ReadPosRankSum < -8.0" -filter-name "ReadPosRankSum-8" """



process VARIANT_ANNOTATOR {
    cpus params.cpus_filter
    memory params.memory_filter
    tag "${name}"
    publishDir params.skip_vqsr? "${params.output}/${name}" : "", mode: "copy"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.6.1" : null)

    input:
    tuple val(name), file(vcf), val(bam)

    output:
    tuple val("${name}"), file("${name}.annotated.vcf"), emit: annotated_vcfs

    script:
    inputs = bam.split(",").collect({v -> "--input $v"}).join(" ")
    """
    gatk --java-options '-Xmx${params.memory_filter}' VariantAnnotator \
   --reference ${params.reference} \
   ${inputs} \
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

    conda (params.enable_conda ? "bioconda::gatk4=4.2.6.1" : null)

    input:
    tuple val(name), file(vcf)

    output:
    tuple val("${name}"), file(vcf), file("output.tranches"), file("${name}.recalibrated.vcf"),
        file("${name}.recalibrated.vcf.idx"), emit: recalibration

    """
    gatk --java-options '-Xmx${params.memory_filter}' VariantRecalibrator \
    --reference ${params.reference} \
    --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${params.dbsnp} \
    --resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${params.hapmap} \
    --resource:1000G,known=false,training=true,truth=false,prior=10.0 ${params.thousand_genomes} \
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
    tuple val(name), file(vcf), file(tranches_file), file(recalibration_file), file(index)

    output:
    tuple val("${name}"), file("${name}.hc.vcf"), emit: final_vcfs

    """
    gatk --java-options '-Xmx${params.memory_filter}' ApplyVQSR \
   --reference ${params.reference} \
   --variant ${vcf} \
   --output ${name}.hc.vcf \
   --truth-sensitivity-filter-level 99.0 \
   --tranches-file ${tranches_file} \
   --recal-file ${recalibration_file} \
   --mode BOTH
    """
}

process VARIANT_FILTERING {
    cpus params.cpus_filter
    memory params.memory_filter
    tag "${name}"
    publishDir "${params.output}/${name}", mode: "copy"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0" : null)

    input:
    tuple val(name), file(vcf)
    val(reference)

    output:
    tuple val("${name}"), file("${name}.hard_filters.vcf"), emit: final_vcfs

    """
    gatk SelectVariants \
        -V ${vcf} \
        -select-type SNP \
        -O ${name}.snvs.vcf

    gatk SelectVariants \
        -V ${vcf} \
        -select-type INDEL \
        -O ${name}.indels.vcf

    gatk VariantFiltration \
        -V ${name}.indels.vcf \
        ${params.indels_hard_filters} \
        -O ${name}.filtered.indels.vcf

    gatk VariantFiltration \
        -V ${name}.snvs.vcf \
        ${params.snvs_hard_filters} \
        -O ${name}.filtered.snvs.vcf

    gatk MergeVcfs \
        -I ${name}.filtered.snvs.vcf \
        -I ${name}.filtered.indels.vcf \
        -O ${name}.hard_filters.vcf
    """
}
