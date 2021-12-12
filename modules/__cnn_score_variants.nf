params.memory_cnn_score_variants = "16g"
params.cpus_cnn_score_variants = 2


process CNN_WRITE_TENSORS {
  cpus params.cpus_cnn_score_variants
  memory params.memory_cnn_score_variants
  tag "${name}"

  conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0 bioconda::gatktool=0.0.1 bioconda::vqsr_cnn=0.0.194" : null)

  input:
  tuple val(name), file(vcf), val(bam)

  output:
  tuple val(name), file("tensor-folder"), emit: cnn_tensor_folder

  script:
  bams = bam.split(",").collect({v -> "--bam-file $v"}).join(" ")
  """
  gatk --java-options '-Xmx${params.memory_cnn_score_variants}' CNNVariantWriteTensors \
   --reference ${params.reference} \
   --variant ${vcf} \
   --truth-vcf platinum-genomes.vcf \
   --truth-bed platinum-confident-region.bed \
   --tensor-type read_tensor \
   ${bams} \
   --output-tensor-dir tensor-folder
  """
}

process CNN_VARIANT_TRAIN {
  cpus params.cpus_cnn_score_variants
  memory params.memory_cnn_score_variants
  tag "${name}"

  conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0 bioconda::gatktool=0.0.1" : null)

  input:
  tuple val(name), file(tensor_folder)

  output:
  tuple val(name), file("tensor-folder"), emit: cnn_tensor_folder

  script:
  """
  gatk --java-options '-Xmx${params.memory_cnn_score_variants}' CNNVariantTrain \
   -input-tensor-dir ${tensor_folder} \
   -tensor-type read_tensor
  """
}

process CNN_SCORE_VARIANTS {
  cpus params.cpus_cnn_score_variants
  memory params.memory_cnn_score_variants
  tag "${name}"

  conda (params.enable_conda ? "bioconda::gatk4=4.2.0.0 bioconda::gatktool=0.0.1" : null)

  input:
  tuple val(name), file(vcf), val(bam)

  output:
  tuple val(name), file("${name}.cnn_scores.vcf"), emit: cnn_annotated_vcfs

  script:
  inputs = bam.split(",").collect({v -> "--input $v"}).join(" ")
  """
  gatk --java-options '-Xmx${params.memory_cnn_score_variants}' CNNScoreVariants \
  ${inputs} \
  --reference ${params.reference} \
  --variant ${vcf} \
  --output ${name}.cnn_scores.vcf \
  -tensor-type read_tensor
  """
}
