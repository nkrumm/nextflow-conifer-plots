#!/usr/bin/env nextflow

/*
 * ----------------------------------------------------------------------------
 *  Nextflow CoNIFER Plots
 * ----------------------------------------------------------------------------
 * A pipeline to create CNV plots that include CoNIFER output
 */

// helper functions
def maybe_local(fname){
    // Address the special case of using test files in this project
    // when running in batchman, or more generally, run-from-git.
    if(file(fname).exists() || fname.startsWith('s3://')){
        return file(fname)
    }else{
        file("$workflow.projectDir/" + fname)
    }
}


// assay-specific parameters
vars = params.assays[params.assay]
genome_fasta = file(vars.genome_fasta)
target_file = file(vars.target_file)
filtered_refgene = file(maybe_local(vars.ref_gene), checkIfExists: true)
conifer_baseline = file(vars.cnv_callers[params.cnv_caller].conifer_baseline, checkIfExists: true)
components_removed = vars.cnv_callers[params.cnv_caller].conifer_components
cnv_caller = params.cnv_caller
cnv_median_window = vars.cnv_window
cnv_log_threshold = vars.cnv_min_log


// read in input files
if (params.manifest){
    bam_ch = Channel.fromPath(params.manifest)
        .splitCsv(header: true)
        .map { [
            it.sample_id, 
            file(it.sample_bam),
            file(it.sample_bam + ".bai"),
            file(it.control_bam),
            file(it.control_bam + ".bai")
         ] }
        .view()
} else if (params.sample_bam && params.control_bam) {
    sample_bam = file(params.sample_bam)
    bam_ch = Channel.from([
        sample_bam.baseName,
        sample_bam,
        file(params.sample_bam + ".bai"),
        file(params.control_bam),
        file(params.control_bam + ".bai")
        ])
        .view()
} else {
    error "Error: Please specify either a manifest or sample_bam/control_bam in the parameters!"
}

process contra {
    label 'contra'
    echo true
    memory '12 GB'
    errorStrategy 'ignore'
    cpus 2
    input:
        set sample_id, file(sample_bam), file(sample_bai), file(control_bam), file(control_bai) from bam_ch
        file target from target_file
        file genome_fa from genome_fasta_file

    output:
        set sample_id, file("out/table/*bins.txt") into contra_out_ch

    script:
    """
    contra.py \
            --target=${target} \
            --test=${sample_bam} \
            --control=${control_bam} \
            --sampleName=${sample_id} \
            --fasta=${genome_fa} \
            --outFolder=out/ \
            --nomultimapped \
            --minExon=2000
    """
}

inputs_ch = Channel.fromPath(params.input).map { file -> tuple(file.baseName.split("\\.")[0], file) }

process make_cnv_plottable {
    input:
        tuple sample_id, file(cnv_file) from contra_out_ch
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