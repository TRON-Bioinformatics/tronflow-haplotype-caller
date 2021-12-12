params.memory__haplotype_caller = "16g"
params.cpus__haplotype_caller = 2
params.dbsnp = false
params.reference = false
params.intervals = false


process HAPLOTYPE_CALLER {
    cpus params.cpus_haplotype_caller
    memory params.memory_haplotype_caller
    tag "${name}"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0" : null)

    input:
    tuple val(name), val(bam)

    output:
    tuple val("${name}"), file("${name}.hc.unfiltered.vcf"), val(bam), emit: unfiltered_vcfs

    script:
    inputs = bam.split(",").collect({v -> "--input $v"}).join(" ")
    intervals_option = params.intervals ? "--intervals ${params.intervals}" : ""
    dbsnp_option = params.dbsnp ? "--dbsnp ${params.dbsnp}" : ""
    """
    gatk --java-options '-Xmx${params.memory__haplotype_caller}' HaplotypeCaller \
    --reference ${params.reference} \
    ${intervals_option} \
    ${dbsnp_option} \
    ${inputs} \
    --output ${name}.hc.unfiltered.vcf
    """
}
