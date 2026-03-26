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
5. In the `meerkat_processing` repository, edit the `run_llus_image.py` script to point to the cloned repositories.  Specifically you will need to edit the localization lines:
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

The steps are managed by a set of text flags in the job submission script.  There is a template script in `run_llus_image.bash`.  You should copy this file out of the `meerkat_processing` directory and into a working space where you will edit files and submit jobs.  You can give it a different name so you can distinguish the control script for different galaxies, but this instruction set assumes you didn't.

### Step 1 (Setup):
Edit the copied version of the `run_llus_image.bash` to set the flag for running the different steps. You will want to run the "staging" step of the data first.  There are two parts of the script for editing. The first part controls job submission to ilifu.  
```
#!/bin/bash
#SBATCH --account=b234-llus-ag
#SBATCH --time=24:00:00
#SBATCH --job-name=llus_4945
#SBATCH --output=llus_-%J.out
#SBATCH --ntasks=1    # number of MPI processes
#SBATCH --mem=32G      # memory; default unit is megabytes
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=email@email.com
#SBATCH --mail-type=ALL
```
Here, you should edit the `--job-name` to refer to a specific galaxy, which helps keep clear which job is running.  Leave the `%J` part of the name alone.  yo ushould also edit the `--mail-user` to point to your email address so you receive job notifications over email.  Next edit the actual job submission script.
```
# Edit these lines to point to correct directory and galaxy name
export code_dir='/users/eros/code/meerkat_processing/'
export target='ngc4945'

# Edit to do correct stage string
# S = staging
# I = imaging
# A = assemble
# P = postprocess
# D = derived
export stagestring='S'
```
Here, you should set the `code_dir` to be the location of where the `run_llus_image.py` script is located.   You should set the target name to be the name of the galaxy being imaged.  Note, this must match the target name given in the `llus_keys/target_definitions.txt` file.   Set the `stagetstring='S'` to start with the staging step of the pipeline.

### Step 2 (Staging):
You are now ready to start imaging.  This needs to happen in (at least) three steps.  Staging, Imaging, and then the remainder, Assembly, Postprocessing, and Derived product generation.  These three phases happen because the Imaging requires submission of a parallel job array process. You should be able to run the staging job at this point `sbatch run_llus_image.bash` in the directory where you copied the file.

### Step 3 (Imaging):
Once that completes, you can run a job array to carry out the imaging.  Edit `run_llus_image.bash` to change the stage string to `I` for imaging and submit a job array. 
```
sbatch --array=0-200 run_llus_image.bash
```
This runs the imaging in an array of jobs that each image 10 channels of the data cube.  The top end of the job array range should be 10 times the number of channels in your final data cube.  The default imaging is about 1/0.3 times the velocity width in km/s.  There is no risk in running to few or too many jobs but you will need to image all the chunks before proceeding to the next step.  In the case above, if there were actually 205 chunks required, then the remaining chunks would be submitted with `sbatch --array=201-2015 run_llus_image.bash`.  The log files in the imaging stage have lines in them that specify the total number of chunks required.

If a chunk fails, you can run that chunk again specifically.  If chunk 108 failed and you need to run it again, e.g., with a longer run time by editing the job submission script, just run `sbatch --array=108 run_llus_image.bash`.

### Step 4 (Completion):
Once imaging runs to completion, you can reassemble the separate imaging chunks into a final job array. This is the "Assembly" stage.  "Postprocessing" produces a final data cube from imaging with primary beam correction and downsampling.  Finally the "Derived" step makes products like masked moment maps.  In principle, you can run all these stages at once by setting the stage string in `run_llus_image.bash` to `stagestring='APD'`.  The derived step tends to require a significant amount of memory.  If you are getting memory issues or a weird `Bus error (core dumped)` message, the best solution seems to be increasing the amount of memory expected for the job.  The final set of products should be available in the `derived` directory once all stages complete.