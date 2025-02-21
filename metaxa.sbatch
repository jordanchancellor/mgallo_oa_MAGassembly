#!/bin/bash
#SBATCH --mem=100G
#SBATCH --time=1-0
#SBATCH --partition=largemem
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J metaxa
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage sbatch --array=1-3 scripts/metaxa.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
readsdir="${wd}/gallo_decontam/${sample_id}/corrected"
reads1="${readsdir}/${sample_id}_R1.fq.00.0_0.cor.fastq.gz"
reads2="${readsdir}/${sample_id}_R2.fq.00.0_0.cor.fastq.gz"
outdir="${wd}/metaxa/${sample_id}/"

#load required modules and conda environments

module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
conda activate metaxa

# run metaxa on fastq reads

echo "Running metaxa2 on fastq reads in ${readsdir} for sample ${sample_id}"

metaxa2 -1 ${reads1} -2 ${reads2} -f p -o ${outdir}/${sample_id} --cpu 12

# run metaxa transversal tool to get bacterial abundances at the taxonomic level

echo "Running metaxa2 taxonomic transversal tool on taxonomy file for ${sample_id}."

metaxa2_ttt -i ${outdir}/${sample_id}.taxonomy.txt -o ${outdir}/${sample_id} -t b 

echo "Done!"