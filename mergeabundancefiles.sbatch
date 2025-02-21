#!/bin/bash
#SBATCH --mem=50GB
#SBATCH --time=01:00:00
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J mergeabundacetables
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch scripts/mergeabundancefiles.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
# samples_file="${wd}/samples_file.txt"
# sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
abundance_dir="${wd}/abundance/coverm/"
# taxonomy_file="${wd}/taxonomy/ALL_filt_MAGs/gtdb/gtdbtk.bac120.summary.tsv"
output_file="${wd}/abundance/coverm/MG22_MAG_relative_abundance.txt"

# sum counts for all contigs in abundace .tsv files to MAG level and combine with gtdbtk MAG taxonomy assignment


# # Function to extract MAG ID and aggregate contig abundances to MAG level
# aggregate_abundance() {
#     local sample=$1
#     local abundance_file=$2
#     awk -F'\t' -v sample="$sample" '{
#         # Extract the MAG ID from the sample name
#         split(sample, parts, "_mapped_"); 
#         mag_id = parts[2];
        
#         sum_mean[mag_id] += $2; 
#         sum_trimmed_mean[mag_id] += $3; 
#         sum_read_count[mag_id] += $4; 
#         sum_reads_per_base[mag_id] += $5; 
#         sum_rpkm[mag_id] += $6; 
#         sum_tpm[mag_id] += $7
#     } END {
#         for (mag in sum_mean) 
#             print mag, sum_mean[mag], sum_trimmed_mean[mag], sum_read_count[mag], sum_reads_per_base[mag], sum_rpkm[mag], sum_tpm[mag]
#     }' OFS='\t' $abundance_file > ${temp_dir}/${sample}_aggregated.tsv
# }

# # Loop through each abundance file and aggregate contig abundances to MAG level
# for abundance_file in ${abundance_dir}/*_abundance.tsv; do
#     # Extract sample name from the file name
#     sample=$(basename "$abundance_file" _abundance.tsv)
    
#     # Aggregate the abundance file
#     aggregate_abundance "$sample" "$abundance_file"
# done


# Get the list of .txt files in the directory
files=("$abundance_dir"/*.txt)

# Extract the first column (genome) from the first file and initialize the output file
awk '{print $1}' "${files[0]}" > "$output_file"

# Loop over each file and paste the second column into the output file
for file in "${files[@]}"; do
    paste "$output_file" <(awk '{print $2}' "$file") > temp && mv temp "$output_file"
done

echo "Matrix file created at $output_file"
