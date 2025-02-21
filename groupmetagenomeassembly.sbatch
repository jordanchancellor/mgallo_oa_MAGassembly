#!/bin/bash
#SBATCH --mem=150G
#SBATCH --time=1-0
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J metagenomes
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# a pipeline to assemble metagenomes from SPADES error-corrected reads using metaspades and megahit and run quast on each assembly
# a bash and conda-dependent pipeline

# usage: sbatch --array=1-3 scripts/groupmetagenomeassembly.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/microbiome_gallo_oa/"
samples_file="${wd}/treatment_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
readsdir="${wd}/corrected_reads/${sample_id}/"
outdir="${wd}/assembly/treatment_groups/"
metaspadesoutdir="${outdir}/metaspades/"
megahitoutdir="${outdir}/megahit/"
reads1="${readsdir}/${sample_id}_R1.fastq.gz"
reads2="${readsdir}/${sample_id}_R2.fastq.gz"
metaspadescontigs="${metaspadesoutdir}/${sample_id}/contigs.fasta"
megahitcontigs="${megahitoutdir}/${sample_id}/final.contigs.fa"

# load conda environment 

module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
conda activate spades

# run metaSPAdes

echo "Running metaSPAdes to assemble metagenomes with ${reads1} and ${reads2}."

metaspades.py --only-assembler -t 12 -1 ${reads1} -2 ${reads2} -o ${metaspadesoutdir}/${sample_id}/

conda deactivate

# run MegaHit

conda activate megahit

echo "Running MegaHit to assemble metagenomes with ${reads1} and ${reads2}."

megahit -t 12 --min-contig-len 1000 -1 ${reads1} -2 ${reads2} -o ${megahitoutdir}/${sample_id}/

conda deactivate

# run quast on both assemblies

conda activate quast

quast ${metaspadescontigs} -o ${metaspadesoutdir}/${sample_id}/ # metaspades assembly

quast ${megahitcontigs} -o ${megahitoutdir}/${sample_id}/ # megahit assembly

conda deactivate

echo "Done!"
