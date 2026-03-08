# meerkat_processing

This gives instructions for running the PHANGS imaging pipeline on the ilifu cluster on the LLUS MeerKAT XLP.

## Requirements and Installation

1. Clone this repository into your workspace on ilifu
```
git clone git@github.com:PhangsTeam/meerkat_processing.git
```
2. In the repository, edit the `llus_keys/master_key.txt` so that the line 
```
key_dir        	     	/users/eros/code/meerkat_processing/llus_keys/
```
points to the location of where you cloned the repository.
3. Clone the PHANGS imaging pipeline into your code space
```
git clone git@github.com:akleroy/phangs_imaging_scripts.git
```
4. Download the `analysis_utils` scripts from NRAO:
```
wget ftp://ftp.cv.nrao.edu/pub/casaguides/analysis_scripts.tar
tar xf analysis_scripts.tar
```
5. In the `meerkat_processing` repository, edit the `run_llus_test_image.py` script to point to the cloned repositories.  Specifically you will need to edit the localization lines:
```
key_file = '/users/eros/code/meerkat_processing/llus_keys/master_key.txt'
sys.path.append(os.path.expanduser("/users/eros/code/phangs_imaging_scripts/"))
sys.path.append(os.path.expanduser("/users/eros/code/analysis_scripts/"))
```
The `key_file` should point to the `master_key.txt` file in this repository.  The `phangs_imaging_scripts` and `analysis_scripts` should point to the repositories that you just downloaded.

## Running the pipeline

For a single target, you should run the imaging pipeline in three steps on the cluster using the SLURM job submission tools.

1. _Stage the Data_ -- This step converts all the calibrated measurement sets for a single target into a staged single measurement set at the expected velocity resolution after continuum subtraction.  This measurement set is moved into the target's `imaging` directory in the LLUS project space.
2. _Run Chunked Imaging_ -- The imaging takes place in "chunks" of adjacent velocity channels so that the CASA imaging doesn't try to run all the imaging at once and require way too much memory. Each velocity chunk is imaged separately and then the cubes will be stitched back together in the next step. 
3. _Integrate Chunks and Postprocess_ -- This step stitches the cubes back together, corrects the cube for the primrary beam response and downsamples to cube to reduce file space.  

The steps are managed by a set of binary flags at the top of the `run_llus_test_image.py` script.

### Step 1:
Edit the `run_llus_test_image.py` script control block
```
chunksize = 10            # Number of velocity channels in an image chunk
target = 'J0459-26'       # Name of the target in the MS / observations
do_staging = True         # Run imaging staging
do_imaging = False
do_assemble = False
do_postprocess = False
do_stats = False
```
Edit the job submission script `run_llus_test_image_array.bash` to include your email in the commented block at the top.  This will send you emails about job status. Edit the path of the script to point to the correct location in your code directory.
```
casapy /users/eros/code/meerkat_processing/run_llus_test_image.py $SLURM_ARRAY_TASK_ID
```

Submit the script for processing from the linux prompt on the login node of ilifu.
```
user@slurm: sbatch run_llus_test_image_array.bash
```

### Step 2:
Edit the `run_llus_test_image.py` script control block:
```
do_staging = False        
do_imaging = True         # Run imaging
do_assemble = False
do_postprocess = False
do_stats = False
```
Submit the script for processing as a job array.  The default imaging produces 11 chunks. 
```
user@slurm: sbatch --array=0-11 run_llus_test_image_array.bash
```

If you don't know the number of chunks for your imaging, just run the first chunk
```
user@slurm: sbatch --array=0 run_llus_test_image_array.bash
```
and then inspect the output file `JOBNUMBER_JOBNAME.out` and look for the imaging line `Chunk 0 of 11` where the latter number will tell you how many chunks are being run.  From there, submit the remainder of the jobs.
```
user@slurm: sbatch --array=1-11 run_llus_test_image_array.bash
```

### Step 3:
Edit the `run_llus_test_image.py` script control block:
```
do_staging = False        
do_imaging = False 
do_assemble = True        # Run cube assembly
do_postprocess = True     # Postprocess the resulting cube
do_stats = False
```
Submit the script for processing.
```
user@slurm: sbatch run_llus_test_image_array.bash
```
The resulting image will be stored in the `postprocess` directory.