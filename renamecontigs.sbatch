#!/bin/bash
#SBATCH --mem=50GB
#SBATCH --time=01:00:00
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH -J renamecontigs

# rename contig files to have the same prefix as their sample IDs

# usage: sbatch --array=1-3 scripts/renamecontigs.sbatch

# samples_file="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA/samples_file.txt"

# # Iterate over each sample ID in samples_file.txt
# while IFS= read -r sample_id; do
#     # Construct the directory path containing .fa files for the current sample
#     directory="assembly/megahit/${sample_id}"

#     # Iterate over each .fa file in the directory
#     for file in "$directory"/*.fa; do
#         if [ -f "$file" ]; then
#             new_name="${directory}/${sample_id}_${file##*/}"
#             mv "$file" "$new_name"
#             echo "Renamed '$file' to '$new_name'"
#         fi
#     done
# done < "$samples_file"

# rename files to have sample id
samples_file="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA/samples_file.txt"

while IFS= read -r sample_id; do
    for file in assembly/megahit/${sample_id}/*.fa; do
        new_name="${sample_id}_final.contigs.fa"
        mv "$file" "assembly/megahit/${sample_id}/$new_name"
    done
done < "$samples_file"

# rename the contig reads to have the same prefix as the sample IDs

samples_file="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA/samples_file.txt"

while IFS= read -r sample_id; do
    # Construct the directory path containing .fa files for the current sample
    directory="assembly/megahit/${sample_id}"

    # Iterate over each .fa file in the directory
    for file in "$directory"/*.fa; do
        if [ -f "$file" ]; then
            # Add sample_id prefix to lines starting with "<"
            sed -i "s/^>/>${sample_id}\_/" "$file"
            echo "Added sample_id prefix to lines starting with '<' in '$file'"
        fi
    done
done < "$samples_file"