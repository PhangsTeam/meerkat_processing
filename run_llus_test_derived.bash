#!/bin/bash
#SBATCH --account=b234-llus-ag
#SBATCH --time=12:00:00
#SBATCH --job-name=llus_derived
#SBATCH --output=llus_derived-%J.out
#SBATCH --ntasks=1    # number of MPI processes
#SBATCH --mem=64G      # memory; default unit is megabytes
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=rosolowsky@ualberta.ca
#SBATCH --mail-type=ALL

srun --x11 --pty bash
module load python/3.12.9
pip install --user spectral_cube
pip install --user scipy
python /users/eros/code/meerkat_processing/run_llus_test_derived.py
