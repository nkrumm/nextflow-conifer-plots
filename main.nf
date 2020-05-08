#!/usr/bin/env nextflow

/*
 * ----------------------------------------------------------------------------
 *  Nextflow CoNIFER Plots
 * ----------------------------------------------------------------------------
 * A pipeline to create CNV plots that include CoNIFER output
 */

// read in input files
inputs_ch = Channel.fromPath(params.input).map { file -> tuple(file.baseName.split("\\.")[0], file) }

// assay-specific parameters
filtered_refgene = file(params.assays[params.assay].ref_gene, checkIfExists: true)
conifer_baseline = file(params.assays[params.assay].cnv_callers[params.cnv_caller].conifer_baseline, checkIfExists: true)
components_removed = params.assays[params.assay].cnv_callers[params.cnv_caller].conifer_components
cnv_caller = params.cnv_caller
cnv_median_window = params.assays[params.assay].cnv_window
cnv_log_threshold = params.assays[params.assay].cnv_min_log

process make_cnv_plottable {
    input:
        tuple sample_id, file(cnv_file) from inputs_ch
        path conifer_baseline
        path filtered_refgene 

    output:
        tuple sample_id, file("${sample_id}.${cnv_caller}.conifer.CNV_plottable.tsv") into cnv_plottables_ch

    label 'munge'
    tag "${sample_id}"
    cpus 1
    memory "4GB"

    script:
    """
    python /munge/munge make_cnv_plottable \
        ${cnv_file} \
        ${cnv_caller} \
        ${filtered_refgene} \
        -b ${conifer_baseline} \
        -n ${components_removed} \
        -o ${sample_id}.${cnv_caller}.conifer.CNV_plottable.tsv 
    """
}

process plot_cnv {
    input:
        tuple sample_id, file(plottable_file) from cnv_plottables_ch
        path filtered_refgene

    output:
        file("${sample_id}.CNV.pdf")
        
    label 'munge'
    tag "${sample_id}"
    cpus 1
    memory "4GB"
    publishDir "${params.outdir}", overwrite: true, mode: params.publish_mode

    script:
    """
    python /munge/munge plot_cnv \
        ${plottable_file} \
        -r ${filtered_refgene} \
        -w ${cnv_median_window} \
        -t ${cnv_log_threshold} \
        --title ${sample_id} \
        -o ${sample_id}.CNV.pdf
    """
}