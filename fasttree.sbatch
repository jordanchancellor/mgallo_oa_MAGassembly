#!/bin/bash
#SBATCH --mem=50G
#SBATCH --time=1-0
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J FASTtree
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch scripts/fasttree.sbatch

# define global variables
wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
fasta="${wd}/taxonomy/gtdb/align/gtdbtk.bac120.user_msa.fasta"

module purge
module load gcc/11.3.0
module load fasttree/2.1.10

# unzip fasta files

gunzip ${fasta}.gz

# run FastTree

FastTreeMP ${fasta} > ALL_align_gametobacMAGs.tree

echo "Disco!"