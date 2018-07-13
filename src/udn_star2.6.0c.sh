#!/bin/bash
# udn_star2.6.0c 0.0.1

main() {
    echo "Value of read1_fastq: '$read1_fastq'"
    echo "Value of read2_fastq: '$read2_fastq'"
    echo "Value of star_index_75bp: '$star_index'"
    echo "Value of sample: '$sample'"

    if [ -n "$library" ]
	then echo "Value of library: '$library'"
	else library=$sample && echo "Value of library automatically set to sample: '$sample'" 
    fi
    slots=`grep -c "^processor" /proc/cpuinfo` && echo "Number of threads is set to: '$slots'"

## change later to case statements

    if [ "$read_length"=="75" ]
        then
            echo "Value of read_length: '$read_length'"
	else echo "FATAL ERROR: STAR indexes are only available for reads of length: 75" && exit 1
    fi

    echo "Downloading '$read1_fastq'" && dx download "$read1_fastq" -o read1.fastq.gz && echo "DONE!"
    echo "Downloading '$read2_fastq'" && dx download "$read2_fastq" -o read2.fastq.gz && echo "DONE!"
    echo "Downloading '$star_index_75bp'" && dx download "$star_index_75bp" -o star_index.tar && echo "DONE!"

    mkdir -p $HOME/star_index && tar -xvf star_index.tar -C $HOME/star_index/

## fix outputs
    mkdir -p $HOME/star_output
    mkdir -p $HOME/out
    mkdir -p $HOME/out/aligned_bam
    mkdir -p $HOME/out/transcriptome_bam
    mkdir -p $HOME/out/sjout_tab
    mkdir -p $HOME/out/final_log

    prefix="$HOME/star_output/${sample}."

## run STAR
    STAR --runMode alignReads \
    --runThreadN ${slots}\
    --genomeDir $HOME/star_index \
    --twopassMode Basic \
    --sjdbOverhang 74 \
    --outFilterMultimapNmax 20 \
    --alignSJoverhangMin 8 \
    --alignSJDBoverhangMin 1 \
    --outFilterMismatchNmax 999 \
    --outFilterMismatchNoverLmax 0.1 \
    --alignIntronMin 20 \
    --alignIntronMax 1000000 \
    --alignMatesGapMax 1000000 \
    --outFilterType BySJout \
    --outFilterScoreMinOverLread 0.33 \
    --outFilterMatchNminOverLread 0.33 \
    --limitSjdbInsertNsj 1200000 \
    --readFilesIn read1.fastq.gz read2.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix ${prefix} \
    --outSAMstrandField intronMotif \
    --outFilterIntronMotifs None \
    --alignSoftClipAtReferenceEnds Yes \
    --quantMode TranscriptomeSAM GeneCounts \
    --quantTranscriptomeBAMcompression -1 \
    --outSAMtype BAM Unsorted \
    --outBAMcompression -1 \
    --outSAMunmapped Within \
    --genomeLoad NoSharedMemory \
    --chimSegmentMin 15 \
    --chimJunctionOverhangMin 15 \
    --chimOutType Junctions WithinBAM SoftClip \
    --chimMainSegmentMultNmax 1 \
    --outSAMattributes NH HI AS nM NM ch \
    --outSAMattrRGline ID:rg1 SM:${sample} LB:${library}
    
    cd $HOME/star_output
    gzip $sample.SJ.out.tab 

    mv ${sample}.Aligned.out.bam $HOME/out/aligned_bam
    mv ${sample}.Aligned.toTranscriptome.out.bam $HOME/out/transcriptome_bam
    mv ${sample}.SJ.out.tab.gz $HOME/out/sjout_tab
    mv ${sample}.Log.final.out $HOME/out/final_log
 
    dx-upload-all-outputs --parallel
}
