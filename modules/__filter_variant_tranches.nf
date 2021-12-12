params.memory_filter = "16g"
params.cpus_filter = 2
params.output = 'output'
params.dbsnp = false


process FILTER_VARIANT_TRANCHES {
    cpus params.cpus_filter
    memory params.memory_filter
    tag "${name}"
    publishDir "${params.output}/${name}", mode: "copy"

    conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0" : null)

    input:
    tuple val(name), val(vcf)

    output:
    tuple val("${name}"), file("${name}.hc.vcf"), emit: final_vcfs

    """
    gatk --java-options '-Xmx${params.memory_filter}' FilterVariantTranches \
  --resource ${params.dbsnp} \
  --variant ${vcf} \
  --output ${name}.hc.vcf
    """
}