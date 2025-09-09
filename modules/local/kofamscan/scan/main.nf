process KOFAMSCAN_SCAN {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/6d/6dfcf585769170a1385b3420fe4e8eaa89f3e06e122abce4e89898a30f42a8e5/data' :
        'community.wave.seqera.io/library/kofamscan_parallel:66d19ec31c821a4e' }"

    input:
    tuple val(meta), path(fasta)
    path(ko_list)
    path(koprofiles)

    output:
    tuple val(meta), path("kofamscan_output.tsv.gz"), emit: kout
    tuple val(meta), path("kofamscan.tsv.gz")       , emit: kofamtsv
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    input    = fasta =~ /\.gz$/ ? fasta.name.take(fasta.name.lastIndexOf('.')) : fasta
    gunzip   = fasta =~ /\.gz$/ ? "gunzip -c ${fasta} > ${input}" : ""

    """
    $gunzip

    exec_annotation \\
        --profile $koprofiles \\
        --ko-list $ko_list \\
        --format detail-tsv \\
        --cpu $task.cpus \\
        $input \\
        -o kofamscan_output.tsv

    # Create a cleaned up version for summary_tables
    echo "orf	ko	thrshld	score	evalue	ko_definition" | gzip -c > kofamscan.tsv.gz
    grep -v '#' kofamscan_output.tsv | cut -f 2-7|sed 's/\t"/\t/' | sed 's/"\$//' | gzip -c >> kofamscan.tsv.gz

    # Gzip the original file
    gzip kofamscan_output.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kofamscan: \$(echo \$(exec_annotation --version 2>&1) | sed 's/^.*exec_annotation//' )
    END_VERSIONS
    """
}
