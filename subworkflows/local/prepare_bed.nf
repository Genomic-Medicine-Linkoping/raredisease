//
// Prepare reference bed files
//

include { GATK4_BEDTOINTERVALLIST as GATK_BILT } from '../../modules/nf-core/modules/gatk4/bedtointervallist/main'
include { GATK4_INTERVALLISTTOOLS as GATK_ILT } from '../../modules/nf-core/modules/gatk4/intervallisttools/main'
include { TABIX_TABIX as TABIX_PT } from '../../modules/nf-core/modules/tabix/tabix/main'
include { TABIX_BGZIPTABIX as TABIX_PBT } from '../../modules/nf-core/modules/tabix/bgziptabix/main'

workflow CHECK_BED {
    take:
        bed                // file: bed file
        seq_dictionary     // path: sequence_dictionary

    main:
        tab_out = Channel.empty()
        if (bed) {
            bed_file = file(bed)
            id       = bed.split('/')[-1]
            ch_bed   = Channel.fromList([[['id':id], bed_file]])

            if ( bed.endsWith(".gz") && file(bed, checkIfExists:true) ) {
                tbi_out = TABIX_PT (ch_bed).tbi
                tab_out = ch_bed.join(tbi_out)
            } else if ( file(bed, checkIfExists:true) ) {
                tab_out = TABIX_PBT (ch_bed).gz_tbi
            }

            interval_list = GATK_BILT (ch_bed, seq_dictionary).interval_list
            GATK_ILT(interval_list)
        }

    emit:
        bed  =  tab_out
        target_intervals = interval_list.collect{it[1]}
        bait_intervals   = GATK_ILT.out.interval_list.collect{it[1]}
}
