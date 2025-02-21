#!/bin/bash
#SBATCH --mem=0
#SBATCH --time=2-0
#SBATCH --partition=htcondor
#SBATCH --cpus-per-task=12
#SBATCH --error=%x.err
#SBATCH --output=%x.out
#SBATCH -J gtdbtkdb
#SBATCH --mail-type=END
#SBATCH --mail-user=jchancel@usc.edu

module load conda
source /spack/conda/miniconda3/23.3.1/etc/profile.d/conda.sh
conda activate gtdbtk-2.1.1

set -e

# Configuration
N_FILES_IN_TAR=241860
TARGET_TAR="/project/biodb/gtdb/release207/207.0/auxillary_files/gtdbtk_r207_v2_data.tar.gz"

# Script variables (no need to configure)
TARGET_DIR=${1:-$GTDBTK_DATA_PATH}

# Check if this is overriding an existing version
mkdir -p "$TARGET_DIR"
n_folders=$(find "$TARGET_DIR" -maxdepth 1 -type d | wc -l)
if [ "$n_folders" -gt 1 ]; then
  echo "[ERROR] - The GTDB-Tk database directory must be empty, please empty it: $TARGET_DIR"
  exit 1
fi

# Uncompress and pipe output to TQDM
echo "[INFO] - Extracting archive..."
tar xvzf "$TARGET_TAR" -C "${TARGET_DIR}" --strip 1 | tqdm --unit=file --total=$N_FILES_IN_TAR --smoothing=0.1 >/dev/null

# Remove the file after successful extraction
echo "[INFO] - The GTDB-Tk database has been successfully downloaded and extracted."

# Set the environment variable
if conda env config vars set GTDBTK_DATA_PATH="$TARGET_DIR"; then
  echo "[INFO] - Added GTDBTK_DATA_PATH ($TARGET_DIR) to the GTDB-Tk conda environment."
else
  echo "[INFO] - Conda not found in PATH, please be sure to set the GTDBTK_DATA_PATH envrionment variable"
  echo "export GTDBTK_DATA_PATH=$TARGET_DIR before running GTDB-Tk. "
fi

exit 0