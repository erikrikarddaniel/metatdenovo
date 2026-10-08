process TIDYVERSE_STRIPCDSPREFIX {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4b/4b997e8d619c30e5ea23a08d9fb7e4b0c9b441f3187b64d65ff1c0df5e12bba0/data' :
        'community.wave.seqera.io/library/r-base_r-r.utils_r-dplyr_r-readr_pruned:b59bb1a4cfb1196e' }"

    input:
    tuple val(meta), path(counts)

    output:
    tuple val(meta), path("${prefix}.counts.tsv.gz"), emit: counts
    path "versions.yml"                             , emit: versions, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Streams, so memory stays constant. orf is the first column. Output name equals the
    # staged input symlink: write elsewhere and rename, or the upstream task cache is overwritten.
    gzip -dc ${counts} | sed 's/^cds\\.//' | gzip -c > stripped.counts.tsv.gz
    mv -f stripped.counts.tsv.gz ${prefix}.counts.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(gzip --version 2>&1 | head -1 | sed 's/^gzip //')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.counts.tsv
    gzip ${prefix}.counts.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: 4.1.0
        readr: 2.0.0
        dplyr: 1.0.7
        stringr: 1.5.0
    END_VERSIONS
    """
}
