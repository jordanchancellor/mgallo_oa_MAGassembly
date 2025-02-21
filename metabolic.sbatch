#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J metabolicg
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch --array=1-3 scripts/metabolic.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
# prodigal_dir="${wd}/functional_analysis/prodigal/"
prodigal_dir="${wd}/functional_analysis/prodigal/${sample_id}/"
# outdir="${wd}/functional_analysis/metabolicg"
outdir="${wd}/functional_analysis/metabolicg/${sample_id}"

# activate  conda environment and run metabolicg
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
conda activate METABOLIC_v4.0

# run metabolic-g

echo "Running metabolic-g."

perl /project/noujdine_61/common_resources/METABOLIC_running_folder/METABOLIC/METABOLIC-G.pl -in ${prodigal_dir} -o ${outdir}

conda deactivate

echo "Disco!"