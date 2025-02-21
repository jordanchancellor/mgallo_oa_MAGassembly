#!/bin/bash

# Function to check if the previous job array has completed successfully
function check_previous_job {
    # Use squeue to check the status of the previous job array
    if squeue -j 22970630 &> /dev/null; then
        return 1  # Previous job array is still running
    else
        return 0  # Previous job array has completed
    fi
}

# Function to check if the new job array has already been submitted
function check_new_job {
    # Use squeue to check if the new job array is already in the queue
    if squeue squeue -n dastool &> /dev/null; then
        return 1  # New job array is still in the queue
    else
        return 0  # New job array has completed
    fi
}

# Main function
function main {
    # Check if the previous job array has completed
    if check_previous_job; then
        echo "Previous job array has completed."

        # Check if the new job array has already been submitted
        if check_new_job; then
            echo "New job array has already been submitted."
        else
            # Submit a new job array using sbatch
            echo "Submitting new job array..."
            sbatch --array=1-9 scripts/dastool.sbatch

            echo "New job array submitted."
        fi
    else
        echo "Previous job array is still running."
    fi
}

# Call the main function
main
