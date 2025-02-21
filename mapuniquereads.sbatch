#!/bin/bash
#SBATCH --mem=150GB
#SBATCH --time=2-0
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J mapuniquereads
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch --array=1-9 scripts/mapuniquereads.sbatch

wd="/project/noujdine_61/jchancel/microbiome_gallo_oa/"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
readsdir="${wd}/gallo_decontam/${sample_id}/corrected/"
fasta_dir="${wd}/taxonomy/final_fasta/"

module purge
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
module load jdk/17.0.5

conda activate bwa

# index treatment specific metagenome assemblies with bwa index prior to running bwa mem on read files

# align error-corrected reads to indexed-MAGs fasta using bwa mem

# map individual sample reads to filtered and dereplicated bins

echo "Mapping reads associated with ${sample_id} to bins in ${fasta_dir}."

for bin in ${fasta_dir}/*.fa; do
    bwa mem $bin ${readsdir}/${sample_id}_R1.fq.00.0_0.cor.fastq.gz ${readsdir}/${sample_id}_R2.fq.00.0_0.cor.fastq.gz > ${fasta_dir}/${sample_id}_mapped_$(basename $bin .fa).sam
done

conda deactivate

echo "Disco!"
