//
// Call ORFs with MetaEuk, then reformat its GFF for downstream featureCounts
//

include { METAEUK_DOWNLOAD    } from '../../../modules/local/metaeuk/download/main'
include { METAEUK_EASYPREDICT } from '../../../modules/nf-core/metaeuk/easypredict/main'
include { FORMAT_METAEUKFAA   } from '../../../modules/local/format/metaeukfaa/main'
include { FORMAT_METAEUK_GFF  } from '../../../modules/local/format/metaeuk/main'

workflow METAEUK {

    take:
    fasta       // channel: [ val(meta), path(fasta) ]
    db_path     // value: path to a pre-built database (file or directory), or falsy to auto-download
    db_name     // value: database name `metaeuk databases` understands, used only when db_path is falsy

    main:

    // A pre-built database is used as-is; otherwise METAEUK_DOWNLOAD builds one under
    // params.metaeuk_db_dir. db_name is a plain value rather than a channel, so METAEUK_DOWNLOAD
    // runs exactly once and Nextflow reuses its single output for every fasta this subworkflow
    // receives, same as any process whose inputs are plain values rather than queue channels.
    if ( db_path ) {
        ch_database = file(db_path, checkIfExists: true)
    } else {
        METAEUK_DOWNLOAD( db_name )
        ch_database = METAEUK_DOWNLOAD.out.database
    }

    METAEUK_EASYPREDICT ( fasta, ch_database )

    // Both outputs get reformatted so the protein fasta's sequence ids and the gff's ID= attributes
    // are the same string -- MetaEuk's own two outputs disagree, see FORMAT_METAEUKFAA.
    FORMAT_METAEUKFAA ( METAEUK_EASYPREDICT.out.faa )
    FORMAT_METAEUK_GFF ( METAEUK_EASYPREDICT.out.gff )

    emit:
    faa = FORMAT_METAEUKFAA.out.format_faa // channel: [ val(meta), path(faa) ]
    gff = FORMAT_METAEUK_GFF.out.format_gff // channel: [ val(meta), path(gff) ]
}
