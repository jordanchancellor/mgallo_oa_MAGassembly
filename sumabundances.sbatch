#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J sumabundacetables
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch scripts/sumabundances.sbatch

wd="/project/noujdine_61/jchancel/microbiome_gallo_oa/"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
abundance_dir="${wd}/abundance/coverm/ALL_MAGs/"
output_dir="${wd}/abundance/coverm/ALL_MAGs/counts/"


# Process each .tsv file in the input directory
for file in "${abundance_dir}"/*.tsv; do
  # Extract the filename
  filename=$(basename "$file")
  
  # Extract the MAG name from the filename
  mag_name=$(echo "$filename" | grep -oP '(?<=mapped_).*(?=_abundance)')
  
  # Initialize an array to store the sum of each column
  sums=(0 0 0 0 0 0)
  
  # Read the file line by line
  header_skipped=false
  while IFS=$'\t' read -r -a line; do
    if ! $header_skipped; then
      header_skipped=true
      continue
    fi

    # Ensure we are reading only lines with at least 7 columns
    if [ ${#line[@]} -ge 7 ]; then
      for i in {1..6}; do
        # Check if the value is a number before adding
        if [[ ${line[$i]} =~ ^[0-9]+([.][0-9]+)?$ ]]; then
          sums[$((i-1))]=$(echo "${sums[$((i-1))]} + ${line[$i]}" | bc)
        fi
      done
    fi
  done < "$file"
  
  # Write the MAG name and the summed values to the output file
  echo -e "$mag_name\t${sums[@]}" > "${output_dir}/${filename}"
done
