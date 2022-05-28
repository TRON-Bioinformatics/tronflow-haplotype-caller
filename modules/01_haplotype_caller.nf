params.memory__haplotype_caller = "16g"
params.cpus__haplotype_caller = 2
params.dbsnp = false
params.reference = false
params.intervals = false
params.ploidy = 2
params.memory_haplotype_caller = "16g"
params.cpus_haplotype_caller = 2


process HAPLOTYPE_CALLER {
    cpus params.cpus_haplotype_caller
    memory params.memory_haplotype_caller
    tag "${name}"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.6.1" : null)

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
    --sample-ploidy ${params.ploidy} \
    ${intervals_option} \
    ${dbsnp_option} \
    ${inputs} \
    --output ${name}.hc.unfiltered.vcf
    """
}
