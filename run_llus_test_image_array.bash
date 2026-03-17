#!/bin/bash
#SBATCH --account=b234-llus-ag
#SBATCH --time=4:00:00
#SBATCH --job-name=llus_test
#SBATCH --output=llus_test-%J.out
#SBATCH --ntasks=1    # number of MPI processes
#SBATCH --mem=32G      # memory; default unit is megabytes
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=email@email.com
#SBATCH --mail-type=ALL

srun --x11 --pty bash
module load casa/6.6.4

export target='ngc1744'
# Stage string 
# S = staging
# I = imaging
# A = assemble
# P = postprocess
export stagestring='S'

if [ -z ${SLURM_ARRAY_TASK_ID+x} ]; then export SLURM_ARRAY_TASK_ID=-1; else echo "Job array ID is set to '$SLURM_ARRAY_TASK_ID'"; fi
casapy /users/eros/code/meerkat_processing/run_llus_test_image.py $target $stagestring $SLURM_ARRAY_TASK_ID
