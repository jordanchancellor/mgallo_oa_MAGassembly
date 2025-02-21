#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J coverm
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch --array=1-3 scripts/coverm.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
readsdir="${wd}/gallo_decontam/${sample_id}/corrected"
fasta_dir="${wd}/ALL_filt_MAGs/"
abundance_dir="${wd}/abundance/coverm/"

module purge
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
module load jdk/17.0.5

# conda activate samtools

# convert SAM to BAM files, sort and index

# echo "Coverting sam to bam files with samtools."

# for sam in ${fasta_dir}/*.sam; do
#     samtools view -Sb $sam > ${fasta_dir}/$(basename $sam .sam).bam
# done

# echo "Sorting bam files with samtools."

# for bam in ${fasta_dir}/*.bam; do
#     samtools sort $bam -o ${fasta_dir}/$(basename $bam .bam)_sorted.bam
# done

# echo "Indexing bam files with samtools."

# for bam in ${fasta_dir}/*_sorted.bam; do
#     samtools index $bam
# done

# echo "Creating mapping rate files with samtools for all bam files."

# for bam in ${fasta_dir}/*_sorted.bam; do
#     samtools flagstat $bam > ${abundance_dir}/$(basename $bam .bam)_flagstat.txt
# done

# conda deactivate

# quantify mapped reads with coverm

echo "Quantifying mapped reads with Coverm for reads associated with ${sample_id}"

conda activate coverm

# for bin in ${fasta_dir}/*.fa; do
#     bin_base=$(basename $bin .fa)
    
#     # Loop through each BAM file corresponding to the bin
#     for bam in ${fasta_dir}/*mapped_${bin_base}_sorted.bam; do
#         sample=$(basename $bam _sorted.bam)
        
#         # Define output abundance file
#         abundance_output="${abundance_dir}/${sample}_abund_${bin_base}_abundance.tsv"
        
#         # Run CoverM to quantify read abundance using mean coverage and RPKM
#         coverm contig --methods mean trimmed_mean count reads_per_base rpkm tpm --bam-files $bam --genome-file $bin --min-read-aligned-percent 75 --min-read-percent-identity 95 -t 12 > $abundance_output
#     done
# done

# coverm contig

# for bin in ${fasta_dir}/*.fa; do
#     bin_base=$(basename $bin .fa)
#     #  Define output abundance file
#     abundance_output="${abundance_dir}/${sample_id}_mapped_${bin_base}_abundance.tsv"
#     coverm contig --methods mean trimmed_mean count reads_per_base rpkm tpm --coupled ${readsdir}/${sample_id}_R1.fq.00.0_0.cor.fastq.gz ${readsdir}/${sample_id}_R2.fq.00.0_0.cor.fastq.gz --reference $bin -p bwa-mem --min-read-aligned-percent 75 --min-read-percent-identity 95 -t 12 --output-file $abundance_output
# done

# coverm genome calculation

coverm genome --methods relative_abundance mean trimmed_mean rpkm --coupled ${readsdir}/${sample_id}_R1.fq.00.0_0.cor.fastq.gz ${readsdir}/${sample_id}_R2.fq.00.0_0.cor.fastq.gz --genome-fasta-directory ${fasta_dir} --genome-fasta-extension fa -p bwa-mem --min-read-aligned-percent 75 --min-read-percent-identity 95 --threads 12 --output-file ${abundance_dir}/${sample_id}_abundances.txt

coverm genome --methods count rpkm --coupled ${readsdir}/${sample_id}_R1.fq.00.0_0.cor.fastq.gz ${readsdir}/${sample_id}_R2.fq.00.0_0.cor.fastq.gz --genome-fasta-directory ${fasta_dir} --genome-fasta-extension fa -p bwa-mem --threads 12 --output-file ${abundance_dir}/${sample_id}_counts.txt

conda deactivate

echo "Disco!"