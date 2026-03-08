#!/bin/bash
#SBATCH --account=b234-llus-ag
#SBATCH --time=48:00:00
#SBATCH --job-name=llus_test
#SBATCH --output=llus_test-%J.out
#SBATCH --ntasks=1    # number of MPI processes
#SBATCH --mem=64G      # memory; default unit is megabytes
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=email@email.com
#SBATCH --mail-type=ALL

srun --x11 --pty bash
module load casa/6.6.4

echo "Job array ID:"
echo $SLURM_ARRAY_TASK_ID
casapy /users/eros/code/meerkat_processing/run_llus_test_image.py $SLURM_ARRAY_TASK_ID
