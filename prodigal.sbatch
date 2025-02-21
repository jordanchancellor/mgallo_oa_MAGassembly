#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J prodigal
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch --array=1-3 scripts/prodigal.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
# fasta="${wd}/ALL_filt_MAGs/ALL_MAGs_combined.fna"
# outdir="${wd}/functional_analysis/prodigal"
dir="${wd}/ALL_filt_MAGs/${sample_id}"
outdir="${wd}/functional_analysis/prodigal/${sample_id}"

# activate  conda environment and run Prodigal
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
conda activate prodigal

# echo "Running prodigal on all combined, filtered MAGs in ${fasta}."

# prodigal -i ${fasta} -o ${outdir}/ALL_MAGs_gene.coords.gbk -a ${outdir}/ALL_MAGs_protein.translations.faa -p meta

echo "Running prodigal on filtered MAGs for sample ${sample_id}."

for i in ${dir}/*.fa; do
  prodigal -i "${i}" -o "${outdir}/$(basename "${i}" .fa)_gene.coords.gbk" \
           -a "${outdir}/$(basename "${i}" .fa)_protein.translations.faa" \
           -p meta
done

echo "Disco!"