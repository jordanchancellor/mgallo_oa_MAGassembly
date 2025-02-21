#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=1-0
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J filterbins
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch scripts/filterbins.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"


# Check if the samples file exists
if [ ! -f "$samples_file" ]; then
    echo "Error: Samples file not found: $samples_file"
    exit 1
fi

# Function to check if a bin meets the filtering criteria
function meets_criteria() {
    local report_file="$1"
    local bin_id="$2"
    local min_completeness=80  # Edit this with your desired completeness threshold
    local max_contamination=10   # Edit this with your desired contamination threshold

    # Get the completeness and contamination values from the report file
    local completeness=$(awk -v bin="$bin_id" '$1 == bin {print $2}' "$report_file")
    local contamination=$(awk -v bin="$bin_id" '$1 == bin {print $3}' "$report_file")

    # Check if the bin meets the criteria
    if (( $(echo "$completeness >= $min_completeness" | bc -l) )) && (( $(echo "$contamination <= $max_contamination" | bc -l) )); then
        return 0  # Bin meets the criteria
    else
        return 1  # Bin does not meet the criteria
    fi
}

# Loop through each sample ID in the file and process it
while read -r sample_id; do
    fasta_dir="${wd}/assembly/dastool/${sample_id}_DASTool_bins"
    report_dir="${wd}/assembly/checkm/${sample_id}"

    # Check if the directory exists and contains FASTA files
    if [ -d "$fasta_dir" ] && [ "$(ls -A "$fasta_dir"/*.fa 2>/dev/null)" ]; then
        report_file="$report_dir/quality_report.tsv"

        # Check if the report file exists
        if [ -f "$report_file" ]; then
            # Create the filtered_fasta directory for this sample
            filtered_dir="$fasta_dir/filtered_fasta"
            mkdir -p "$filtered_dir"

            # Loop through all bins in the FASTA directory
            for bin_file in "$fasta_dir"/*.fa; do
                if [ -f "$bin_file" ]; then
                    bin_id=$(basename "$bin_file" .fa)
                    echo "Processing sample ID: $sample_id, Bin ID: $bin_id"

                    # Check if the bin meets the criteria
                    if meets_criteria "$report_file" "$bin_id"; then
                        cp "$bin_file" "$filtered_dir/"
                    fi
                fi
            done
        else
            echo "Warning: Report file not found for sample ID: $sample_id"
        fi
    else
        echo "Warning: FASTA directory not found or empty for sample ID: $sample_id"
    fi
done < "$samples_file"

echo "Disco!"