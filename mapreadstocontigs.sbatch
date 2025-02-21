#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=oneweek
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J readmappingandbinning
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# a pipeline to create sam and bam files from metagenome assembled-contigs fastas and bin using maxbin, concoct, and metabat
# a bash and conda-dependent pipeline

# usage: sbatch --array=1-3 scripts/mapreadstocontigs.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
readsdir="${wd}/gallo_decontam/${sample_id}/corrected"
outdir="${wd}/assembly/treatment_groups/"
megahitoutdir="${outdir}/megahit/"
reads1="${readsdir}/${sample_id}_R1.fastq.gz"
reads2="${readsdir}/${sample_id}_R2.fastq.gz"
bamfile="${wd}/gallo_decontam/${sample_id}/${sample_id}.unmapped.sorted.bam"
megahitcontig="${megahitoutdir}/${sample_id}/${sample_id}_final.contigs.fa"
samfile="${megahitoutdir}/${sample_id}/${sample_id}.sam"
sortedbamfile="${megahitoutdir}/${sample_id}/${sample_id}_sorted.bam"
maxbinoutdir="${outdir}/maxbin/${sample_id}/"
concoctoutdir="${outdir}/concoct/${sample_id}/"
metabatoutdir="${outdir}/metabat/${sample_id}/"

# load conda environment 

module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
module load jdk/17.0.5

# map trimmed reads against assembled megahit metagenome using bwa 

conda activate bwa

# index metagenome assembly fasta for bwa

echo "Running bwa index"

cd ${megahitoutdir}/${sample_id}/ || exit
bwa index -a bwtsw $megahitcontig

# align error-corrected reads to indexed-metagenome fasta using bwa mem

echo "Running bwa mem on files associated with ${reads1} and ${reads2}"

bwacmd="bwa mem -t $SLURM_CPUS_PER_TASK $megahitcontig $reads1 $reads2"

echo "$bwacmd" 

$bwacmd > "${megahitoutdir}/${sample_id}/${sample_id}.sam"

conda deactivate

# create sorted bam file from sam file for concoct

echo "Creating sorted bam file from ${sam} file."

conda activate samtools

cat ${samfile} | samtools view -bSh | samtools sort -o ${megahitoutdir}/${sample_id}/${sample_id}_sorted.bam

# index sorted bam file

echo "Indexing ${sortedbamfile} with samtools."

samtools index ${sortedbamfile}

conda deactivate

# estimate relative abundances by contig with pileup.sh using bbmap

echo "Estimating relative abundances by contig with pileup.sh using bbmap."

/project/noujdine_61/jchancel/software/bbmap/pileup.sh in=${samfile} out=${megahitoutdir}/${sample_id}/${sample_id}_cov.txt

# bin contigs using maxbin2

echo "Binning contigs with MaxBin."

conda activate maxbin

mkdir ${maxbinoutdir}/fasta_bins

run_MaxBin.pl -thread 12 \
-contig ${megahitcontig} \
-out ${maxbinoutdir}/fasta_bins/${sample_id} \
-abund ${megahitoutdir}/${sample_id}/${sample_id}_cov.txt

conda deactivate

# bin contigs with concoct

echo "Binning contigs with CONCOCT."

conda activate concoct

cd ${wd} || exit

# cut contigs into smaller parts

cut_up_fasta.py ${megahitcontig} -c 10000 -o 0 --merge_last -b ${concoctoutdir}/${sample_id}_contigs_10K.bed > ${concoctoutdir}/${sample_id}_contigs_10K.fa

# generate table with coverage depth information per sample and subcontig

concoct_coverage_table.py ${concoctoutdir}/${sample_id}_contigs_10K.bed ${sortedbamfile} > ${concoctoutdir}/${sample_id}_contigs_10K.bed_coverage_table.tsv

# run concoct

concoct -t 12 \
 --composition_file ${concoctoutdir}/${sample_id}_contigs_10K.fa \
 --coverage_file ${concoctoutdir}/${sample_id}_contigs_10K.bed_coverage_table.tsv \
 -b ${concoctoutdir}

# merge subcontig clustering into original contig clustering

merge_cutup_clustering.py ${concoctoutdir}/clustering_gt1000.csv > ${concoctoutdir}/clustering_merged.csv

# extract bins as individual FASTA

mkdir ${concoctoutdir}/fasta_bins
extract_fasta_bins.py ${megahitcontig} ${concoctoutdir}/clustering_merged.csv --output_path ${concoctoutdir}/fasta_bins/

conda deactivate

# bin contigs with MetaBat

echo "Binning contigs with MetaBat."

conda activate metabat

cd ${metabatoutdir} || exit

mkdir fasta_bins

jgi_summarize_bam_contig_depths --outputDepth ${metabatoutdir}/${sample_id}_depth.txt ${sortedbamfile}

metabat2 -t 12 -i ${megahitcontig} -a ${metabatoutdir}/${sample_id}_depth.txt -o ${metabatoutdir}/fasta_bins/${sample_id} -v > ${metabatoutdir}/${sample_id}_metabat_log.txt

conda deactivate

echo "Disco!"