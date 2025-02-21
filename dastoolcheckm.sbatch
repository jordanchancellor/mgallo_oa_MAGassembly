#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J dastool_checkm
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# a script to choose best binned contains with dastool and run checkm on dastool bins
# a bash and conda-dependent pipeline

# usage: sbatch --array=1-3 scripts/dastoolcheckm.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
outdir="${wd}/assembly"
megahitoutdir="${outdir}/megahit/"
megahitcontig="${megahitoutdir}/${sample_id}/${sample_id}_final.contigs.fa"
maxbinoutdir="${outdir}/maxbin/${sample_id}/"
concoctoutdir="${outdir}/concoct/${sample_id}/"
metabatoutdir="${outdir}/metabat/${sample_id}/"
dastooloutdir="${outdir}/dastool/"
checkmoutdir="${outdir}/checkm/${sample_id}/"

# load conda environment 

module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
module load jdk/17.0.5

# check bins with dastool

conda activate dastool

# convert genome bins in fasta format to contigs-to-bin table 

echo "Converting genome bins in fasta format to contigs-to-bin table:"

# maxbin

echo "maxbin"
Fasta_to_Contig2Bin.sh -i ${maxbinoutdir}/fasta_bins -e fasta > ${dastooloutdir}/${sample_id}_maxbin.contigs2bin.tsv

# concoct

echo "concoct"
Fasta_to_Contig2Bin.sh -i ${concoctoutdir}/fasta_bins -e fa > ${dastooloutdir}/${sample_id}_concoct.contigs2bin.tsv
# perl -pe "s/,/\tconcoct./g;" ${concoctoutdir}/clustering_merged.csv > ${dastooloutdir}/${sample_id}_concoct.contigs2bin.tsv

# metabat

echo "metabat"
Fasta_to_Contig2Bin.sh -i ${metabatoutdir}/fasta_bins -e fa > ${dastooloutdir}/${sample_id}_metabat.contigs2bin.tsv

# run dastool

echo "Running dastool."

DAS_Tool \
-i ${dastooloutdir}/${sample_id}_maxbin.contigs2bin.tsv,${dastooloutdir}/${sample_id}_concoct.contigs2bin.tsv,${dastooloutdir}/${sample_id}_metabat.contigs2bin.tsv \
-l maxbin,concoct,metabat \
-c ${megahitcontig} \
-o ${dastooloutdir}/${sample_id} \
-t 12 --write_bin_evals --write_bins

conda deactivate

# run checkm on dastool bins

conda activate checkm2

echo "Running checkm on dastool output bins for sample ${sample_id}."

checkm2 predict --threads 12 -x fa --input ${dastooloutdir}/${sample_id}_DASTool_bins/ --output-directory ${checkmoutdir}

echo "Disco!"
