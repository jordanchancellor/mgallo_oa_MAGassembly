#!/bin/bash
#SBATCH --mem=50G
#SBATCH --time=01:00:00
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J metaxa_dc
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage sbatch scripts/combine_taxa_tables.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
samples=($(cat $samples_file))
outdir="${wd}/metaxa/"

# load required modules and conda environments

module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
conda activate metaxa

# run metaxa data collector tool to merge outputs from metaxa_ttt into an abundance matrix

echo "Running metaxa2 data collector tool output files from metaxa2_ttt for each sample at each taxonomic level"

levels=(1 2 3 4 5 6 7)

mkdir -p ${outdir}/combined_output

# Loop through each level

for level in "${levels[@]}"; do
    # Prepare an array to store the files to be combined for the current level
    files_to_combine=()

    # Loop through each sample
    for sample in "${samples[@]}"; do
        # Add the current level file for the current sample to the array
        files_to_combine+=("${outdir}/${sample}/${sample}.level_${level}.txt")
    done

    # Combine the files for the current level using metaxa2_dc
    metaxa2_dc -o ${outdir}/combined_output/combined_level_${level}.txt "${files_to_combine[@]}"
done

echo "Combination of taxonomic output files completed."