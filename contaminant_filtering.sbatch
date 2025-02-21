#!/bin/bash
#SBATCH --mem=800gb
#SBATCH --time=3-0
#SBATCH --partition=largemem
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J decontam
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# a pipeline to filter contaimants from WGS reads for M. galloprovinciales, human, and phix using bbmap software
# a bash and conda-dependent pipeline

# usage: sbatch --array=1-9 scripts/contaminant_filtering.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/microbiome_gallo_oa/"
outdir="${wd}/gallo_decontam/"
bbdir="/project/noujdine_61/jchancel/software/bbmap/"
trimmedreads="${wd}/gallo_trimmed/"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
reads1="${trimmedreads}/${sample_id}/${sample_id}_R1.fq.gz"
reads2="${trimmedreads}/${sample_id}/${sample_id}_R2.fq.gz"
contaminants="${wd}/all_contaminants.fa"

# Create output directory if it doesn't exist
mkdir -p "$outdir"

# load modules

module load jdk/17.0.5

# run bbduk.sh

echo "Running bbduk on ${reads1} and ${reads2} files for contaminant filtering."

${bbdir}/bbduk.sh -Xmx500g threads=12 \
rskip=6 prealloc=t ordered=t \
in1=${reads1} in2=${reads2} \
out1=${outdir}/${sample_id}_R1_cleaned.fq out2=${outdir}/${sample_id}_R2_cleaned.fq \
ref=${contaminants} \
outm=${outdir}/${sample_id}_R1_bad.fq outm2=${outdir}/${sample_id}_R2_bad.fq \
k=31 hdist=1 stats=bbduk_stats.txt \

echo "Done."
