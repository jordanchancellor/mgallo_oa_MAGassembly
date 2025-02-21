#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J gtdbtk
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch scripts/gtdbtk.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
fasta_dir="${wd}/ALL_filt_MAGs/"
gtdbtk_outdir="${wd}/taxonomy/gtdb/"

module purge
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh

conda activate gtdbtk-2.1.1


gtdbtk classify_wf \
--genome_dir ${fasta_dir} \
--out_dir ${gtdbtk_outdir} \
-x fa --cpus 64
conda deactivate

echo "Disco!"
