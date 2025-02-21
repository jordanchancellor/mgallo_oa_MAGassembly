#!/bin/bash
#SBATCH --mem=150GB
#SBATCH --time=12:00:00
#SBATCH --partition=epyc-64
#SBATCH --cpus-per-task=64
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J getdeezreps
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# usage: sbatch --array=1-3 scripts/dREP.sbatch

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
fasta_dir="${wd}/assembly/dastool/${sample_id}_DASTool_bins/filtered_fasta/"
checkmoutdir="${wd}/assembly/checkm_filtered/${sample_id}/"
drep_outdir="${wd}/assembly/dastool/${sample_id}_DASTool_bins/filtered_fasta/drep"
genomeinfo="${checkmoutdir}/dRep.genomeInfo"

module purge
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh

# Step 1: run checkm on filtered fastas 
conda activate checkm

checkm lineage_wf -t $SLURM_CPUS_PER_TASK \
                  -x fa --tab_table -f ${checkmoutdir}/checkm.txt \
                  ${fasta_dir} ${checkmoutdir}

conda deactivate 

# Step 2: create csv with completeness info from checkm report .txt file
report_dir="${checkmoutdir}"

# Check if the directory exists
if [ -d "$report_dir" ]; then
    report_file="${report_dir}/checkm.txt"

    # Check if the report file exists
    if [ -f "$report_file" ]; then
        echo "genome,completeness,contamination" > ${report_dir}/dRep.genomeInfo
        cut -f1,12,13 ${report_file} \
        | sed 's/\t/.fa\t/' \
        | sed 's/\t/,/g' \
        | tail -n+2 >> ${report_dir}/dRep.genomeInfo
    else
        echo "Warning: checkm Report file not found for sample ID: $sample_id"
    fi
fi

# Step 3: run dRep if more than one fasta file passed checkm filtering

if [ -f "${report_dir}/dRep.genomeInfo" ] && [ $(wc -l < "${report_dir}/dRep.genomeInfo") -gt 2 ]; then
    # Run dRep
    echo "Running dRep on file ${report_dir}/dRep.genomeInfo for sample $sample_id"
    conda activate drep
    dRep dereplicate ${drep_outdir} \
        --genomeInfo ${genomeinfo} \
        -g ${fasta_dir}/*.fa \
        -p $SLURM_CPUS_PER_TASK \
        --ignoreGenomeQuality -d
    conda deactivate
elif [ -f "${report_dir}/dRep.genomeInfo" ]; then
    echo "Only one fasta file passed checkm filtering for sample $sample_id. Skipping dereplication."
else
    echo "Warning: dRep.genomeInfo file not found for sample ID: $sample_id"
fi

echo "Disco!"