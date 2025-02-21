#!/bin/bash
#SBATCH --mem=500GB
#SBATCH --time=1-0
#SBATCH --partition=largemem
#SBATCH --cpus-per-task=12
#SBATCH --error=%x_%a.err
#SBATCH --output=%x_%a.out
#SBATCH -J getunmapped
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

# a pipeline to extract reads that did not map to M.gallo reference genome using bam files with bwa mem and output sam files
# a bash and conda-dependent pipeline

# usage: sbatch --array=1-3 scripts/getunmappedreads.sbatch

# define global variables

wd="/project/noujdine_61/jchancel/MAG_assembly_gallo_OA"
samples_file="${wd}/samples_file.txt"
sample_id="$(cat $samples_file | sed -n ${SLURM_ARRAY_TASK_ID}p)"
outdir="${wd}/gallo_decontam/${sample_id}/"
sortedbamfile="/project/noujdine_61/jchancel/gallo_oa_popgen_pipeline/var-calling/mpileups/${sample_id}.sorted.bam"
reads1="${outdir}/${sample_id}_R1.fq.gz"
reads2="${outdir}/${sample_id}_R2.fq.gz"

# load modules
module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
module load gcc/11.3.0
module load samtools

# make output directory (if needed)

if [[ ! -d $outdir ]]
then
	printf "Creating output directory ${outdir}.\n\n"
	mkdir $outdir 
fi

conda activate samtools

# extract unmapped reads from sorted bam (name sorterd bam required for downstream samtools fastq) files and output into bam format

echo "extracting unmapped reads from ${sortedbamfile}"

samtools view -f 4 -b ${sortedbamfile} > ${outdir}/${sample_id}.unmapped.sorted.bam

# revert bam file to paired fastq read files

echo "Reverting bam file to paired fastq read files."

samtools fastq ${outdir}/${sample_id}.unmapped.sorted.bam \
    -1 ${outdir}/${sample_id}_R1.fq.gz \
    -2 ${outdir}/${sample_id}_R2.fq.gz \
    -s ${outdir}/${sample_id}_singleton.fastq -n

conda deactivate

# error correct reads with spades

echo "Running read error correction using SPAdes."

conda activate spades

spades.py --only-error-correction -t 12 -1 ${reads1} -2 ${reads2} -o ${outdir} -m 400

conda deactivate 

echo "Done!"
