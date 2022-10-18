
process HAPLOTYPE_CALLER {
    cpus params.cpus_haplotype_caller
    memory params.memory_haplotype_caller
    tag "${name}"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.6.1" : null)

    input:
    tuple val(name), val(bam)
    val(reference)
    val(ploidy)
    val(dbsnp)
    val(intervals)
    val(min_quality)

    output:
    tuple val("${name}"), file("${name}.hc.unfiltered.vcf"), val(bam), emit: unfiltered_vcfs

    script:
    inputs = bam.split(",").collect({v -> "--input $v"}).join(" ")
    intervals_option = intervals ? "--intervals ${intervals}" : ""
    dbsnp_option = dbsnp ? "--dbsnp ${dbsnp}" : ""
    min_quality_option = min_quality ? "--standard-min-confidence-threshold-for-calling ${min_quality}" : ""
    """
    gatk --java-options '-Xmx${params.memory_haplotype_caller}' HaplotypeCaller \
    --reference ${reference} \
    --sample-ploidy ${ploidy} \
    ${intervals_option} ${min_quality_option} ${dbsnp_option} ${inputs} \
    --output ${name}.hc.unfiltered.vcf
    """
}
