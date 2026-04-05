### Logged into the HPC
```
ssh erandolp@bridges2.psc.edu
```
- Type password, you wont be able to see any characters as you type, keep typing.
- Hit ENTER
- You will land in the `jet` disk, use this disk space for lightweight analysis, eg.: testing scripts, etc.

### Go to your ocean folder
```
cd /ocean/projects/agr250001p/erandolp
```

### Cloned repository

```
git clone repo-url
```
- Replace repo-url with your actual repository link

### Installed multiqc -- a quality control software
```
module load python/3.8.6
```
```
/jet/packages/spack/opt/spack/linux-centos8-zen2/gcc-10.2.0/python-3.8.6-jaihmn5fofhkpkdsskfz25ez6s2camcf/bin/python3 -m ensurepip --default-pip
```
```
/jet/packages/spack/opt/spack/linux-centos8-zen2/gcc-10.2.0/python-3.8.6-jaihmn5fofhkpkdsskfz25ez6s2camcf/bin/python3 -m pip install --upgrade pip
```
```
/jet/packages/spack/opt/spack/linux-centos8-zen2/gcc-10.2.0/python-3.8.6-jaihmn5fofhkpkdsskfz25ez6s2camcf/bin/python3 -m pip install --user multiqc
```
- Test multiqc
```
multiqc --help
```
### Install qiime2
```
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.2-py38-linux-conda.yml
```
```
module load anaconda3
```
```
conda env create -n qiime2-amplicon-2024.2 --file qiime2-amplicon-2024.2-py38-linux-conda.yml
```
```
conda activate qiime2-amplicon-2024.2
```
- Make sure you deactivate the environment after you are done with qiime
```
conda deactivate
```
## Create an alias to go to ocean disk
```
alias myocean="cd /ocean/projects/agr250001p/erandolp"
echo 'alias myocean="cd /ocean/projects/agr250001p/erandolp"' >> ~/.bashrc
source ~/.bashrc
```

## Create symlink to data
```
ln -s /ocean/projects/agr250001p/shared/whitefly/rawdata .
```
## Quality control with FastQC
```
module load FastQC
```
```
mkdir fastqc_out
```
```
fastqc -t 4 rawdata/*.fastq.gz -o fastqc_out
```
## Summarize quality control results with multiQC
```
multiqc fastqc_out --filename multiqc_endosym.html
```
## Upload file to repository
```
git add multiqc_endosym.html
```
```
git commit -m "Uploading qc summary to repository"
```
```
git push origin main
```
## Store key in hpc
```
git config --global credential.helper store
```
```
git push origin main
```
## Running qiime
```
module load anaconda3        
conda activate qiime2-amplicon-2024.2
```
```
mkdir reads_qza
```
```
qiime tools import \
  --type SampleData[PairedEndSequencesWithQuality] \
  --input-path rawdata/ \
  --output-path reads_qza/reads.qza \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt
```

```
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences reads_qza/reads.qza \
  --p-cores 4 \
  --p-front-f TCGTCGGCAGCGTCAGATGTGTATAAGAGACAGGTGYCAGCMGCCGCGGTAA \
  --p-front-r GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAGGGACTACNVGGGTWTCTAAT \
  --p-discard-untrimmed \
  --p-no-indels \
  --o-trimmed-sequences reads_qza/reads_trimmed.qza
```
```
qiime demux summarize \
  --i-data reads_qza/reads_trimmed.qza \
  --o-visualization reads_qza/reads_trimmed_summary.qzv
```
```
git add "reads_qza/reads_trimmed_summary.qzv"
git commit -m "Adding reads summary results"
git push origin main
```
# Denoising reads
## Ask for more computer resources
```
#Takes too long, we will write a pipeline instead
salloc --mem=100G --time=6:00:00 --cpus-per-task=32
```
1. Join pair-end reds
```         
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs reads_qza/reads_trimmed.qza \
  --output-dir reads_qza/reads_joined
```
2. Filter out low-quality reads
```         
qiime quality-filter q-score \
  --i-demux reads_qza/reads_joined/merged_sequences.qza \
  --o-filter-stats filt_stats.qza \
  --o-filtered-sequences reads_qza/reads_trimmed_joined_filt.qza
```
3. Summarize results
```         
qiime demux summarize \
  --i-data reads_qza/reads_trimmed_joined_filt.qza \
  --o-visualization reads_qza/reads_trimmed_joined_filt_summary.qzv
```
- Add, commit and push `reads_qza/reads_trimmed_joined_filt.qzv` to Git
- Download and open in https://view.qiime2.org/

4. Actual denoising with deblur

```         
qiime deblur denoise-16S \
  --i-demultiplexed-seqs reads_qza/reads_trimmed_joined_filt.qza \
  --p-trim-length 390 \
  --p-sample-stats \
  --p-jobs-to-start 4 \
  --p-min-reads 1 \
  --output-dir deblur_output
```
- Note: this command may take up to 10 minutes or so to run.

5. Summarize dublur output
```         
qiime feature-table summarize \
  --i-table deblur_output/table.qza \
  --o-visualization deblur_output/deblur_table_summary.qzv
```
- Add, commit and push `deblur_output/deblur_table_summary.qzv` to Git

## Denoising with a pipeline
-Create a new file named microbiome.slurm
```
vi microbiome.slurm
```
- Copy and Paste the script below
```
#!/bin/bash
#SBATCH --job-name=ec_microbiome
#SBATCH --cpus-per-task=32
#SBATCH --mem=100G
#SBATCH --time=16:00:00
#SBATCH --output=ec_microbiome.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=emrandol@svsu.edu

cd /ocean/projects/agr250001p/erandolp/endosymbiont_analysis/

module load anaconda3        
conda activate qiime2-amplicon-2024.2

#1. Join pair-end reds
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs reads_qza/reads_trimmed.qza \
  --output-dir reads_qza/reads_joined

#2. Filter out low-quality reads
qiime quality-filter q-score \
  --i-demux reads_qza/reads_joined/merged_sequences.qza \
  --o-filter-stats filt_stats.qza \
  --o-filtered-sequences reads_qza/reads_trimmed_joined_filt.qza

#3. Summarize results       
qiime demux summarize \
  --i-data reads_qza/reads_trimmed_joined_filt.qza \
  --o-visualization reads_qza/reads_trimmed_joined_filt_summary.qzv

#4. Actual denoising with deblur        
qiime deblur denoise-16S \
  --i-demultiplexed-seqs reads_qza/reads_trimmed_joined_filt.qza \
  --p-trim-length 390 \
  --p-sample-stats \
  --p-jobs-to-start 4 \
  --p-min-reads 1 \
  --output-dir deblur_output

#5. Summarize dublur output       
qiime feature-table summarize \
  --i-table deblur_output/table.qza \
  --o-visualization deblur_output/deblur_table_summary.qzv
```
- Exit vi editor by typing ":wq" and enter
- Check the file with "cat microbiome.slurm"
- Run script with
```
sbatch microbiome.slurm
```
## Sample renaming
-We found -I knew this!- that our samples have underscores on them, qimme does not like that. So before we import we have to do the following:
```
mv reads_qza/ reads_qza2
#we are just renaming our old folder
```
-Create reads_qza again
```
mkdir reads_qza
```
-Make sure you are in the "endosymbiont_analysis" folder
```
cd /ocean/projects/agr250001p/erandolp/endosymbiont_analysis
```
- Create a file named "casava.sh"
  - Open the "vi editor"
  ```
  vi casava.sh
  ```
  - Copy raw data into your folder
  ```
  cp -r /ocean/projects/agr250001p/shared/whitefly/rawdata .
  ```
  - Copy and paste the following code:
  ```
  rm -rf casava_reads
  mkdir -p casava_reads
  
  cd rawdata
  
  for r1 in *_R1_001.fastq.gz; do
    r2="${r1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
    [ -f "$r2" ] || { echo "Missing R2 for $r1"; exit 1; }
  
    # sample name = everything before _S (e.g., 6778_10_1G or 6778_N1)
    sample="${r1%%_S*}"
    safe="${sample//_/-}"   # Deblur-safe sample ID (no underscores)
  
    # rebuild casava-style filenames with the SAFE sample name but keep the original suffix
    suffix="${r1#${sample}}"              # e.g. _S18_L001_R1_001.fastq.gz
    out1="../casava_reads/${safe}${suffix}"
  
    suffix2="${r2#${sample}}"
    out2="../casava_reads/${safe}${suffix2}"
  
    ln -s "$(readlink -f "$r1")" "$out1"
    ln -s "$(readlink -f "$r2")" "$out2"
  done
  
  cd ..
  ```
-Make the casava.sh file executable
```
chmod u+x casava.sh
```
- Run the casava.sh file
```
./casava.sh
```
- It is always good to confirm you are in the right directory, type `pwd` and the outpur should be:
```
/ocean/projects/agr250001p/erandolp/endosymbiont_analysis
```
- If not `cd /ocean/projects/agr250001p/erandolp/endosymbiont_analysis`
- Make sure anaconda and qiime are loaded
## Run the whole analysis using a slurm script
- Open the vi editor
```
vi microbiome.slurm
```
- Type `I` to edit file
- Copy and paste the following code:
```
#!/bin/bash
#SBATCH --job-name=microbiome
#SBATCH --cpus-per-task=32
#SBATCH --mem=100G
#SBATCH --time=16:00:00
#SBATCH --output=microbiome.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=emrandol@svsu.edu

set -euo pipefail

echo "Starting: $(date)"
echo "Host: $(hostname)"
echo "Cores: ${SLURM_CPUS_PER_TASK:-32}"
echo "Workdir: $(pwd)"

# --- Activate QIIME2 env (edit to match your setup) ---
module load anaconda3
conda activate qiime2-amplicon-2024.2

# ---- paths ----
READS_QZA="reads_qza"
DEBLUR_DIR="deblur_output"

# ---- clean previous outputs (QIIME won't overwrite) ----
rm -f  "${READS_QZA}/reads.qza" \
       "${READS_QZA}/reads_trimmed.qza" \
       "${READS_QZA}/reads_trimmed_summary.qzv" \
       "${READS_QZA}/reads_trimmed_joined_filt.qza" \
       "${READS_QZA}/reads_trimmed_joined_filt_summary.qzv" \
       "filt_stats.qza"

rm -rf "${READS_QZA}/reads_joined" "${DEBLUR_DIR}"
mkdir -p "${READS_QZA}"

# ---- 0) Import (Casava per-sample-dir format) ----
qiime tools import \
  --type SampleData[PairedEndSequencesWithQuality] \
  --input-path casava_reads \
  --output-path "${READS_QZA}/reads.qza" \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt

# ---- 1) Trim primers/adapters ----
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences "${READS_QZA}/reads.qza" \
  --p-cores 4 \
  --p-front-f GTGYCAGCMGCCGCGGTAA \
  --p-front-r GGACTACNVGGGTWTCTAAT \
  --o-trimmed-sequences "${READS_QZA}/reads_trimmed.qza"

qiime demux summarize \
  --i-data "${READS_QZA}/reads_trimmed.qza" \
  --o-visualization "${READS_QZA}/reads_trimmed_summary.qzv"

# ---- 2) Join paired reads ----
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs "${READS_QZA}/reads_trimmed.qza" \
  --output-dir "${READS_QZA}/reads_joined"

# ---- 3) Quality filter ----
qiime quality-filter q-score \
  --i-demux "${READS_QZA}/reads_joined/merged_sequences.qza" \
  --o-filter-stats "filt_stats.qza" \
  --o-filtered-sequences "${READS_QZA}/reads_trimmed_joined_filt.qza"

qiime demux summarize \
  --i-data "${READS_QZA}/reads_trimmed_joined_filt.qza" \
  --o-visualization "${READS_QZA}/reads_trimmed_joined_filt_summary.qzv"

# ---- 4) Deblur denoise ----
qiime deblur denoise-16S \
  --i-demultiplexed-seqs "${READS_QZA}/reads_trimmed_joined_filt.qza" \
  --p-trim-length 240 \
  --p-sample-stats \
  --p-jobs-to-start 4 \
  --p-min-reads 1 \
  --output-dir "${DEBLUR_DIR}"

# ---- 5) Summarize Deblur outputs ----
qiime feature-table summarize \
  --i-table "${DEBLUR_DIR}/table.qza" \
  --o-visualization "${DEBLUR_DIR}/deblur_table_summary.qzv"

qiime deblur visualize-stats \
  --i-deblur-stats "${DEBLUR_DIR}/stats.qza" \
  --o-visualization "${DEBLUR_DIR}/deblur_stats.qzv"

# ---- 6) Taxonomy assignment + filtering + barplots ----

# Download classifier (cached if it already exists)
mkdir -p classifiers
CLASSIFIER="classifiers/silva-138-99-nb-classifier.qza"

if [ ! -f "$CLASSIFIER" ]; then
  wget -O "$CLASSIFIER" https://data.qiime2.org/2023.9/common/silva-138-99-nb-classifier.qza
fi

# Classify Deblur rep seqs
rm -rf taxa
qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads "${DEBLUR_DIR}/representative_sequences.qza" \
  --p-n-jobs 8 \
  --output-dir taxa

# Filter low-frequency features from Deblur table
qiime feature-table filter-features \
  --i-table "${DEBLUR_DIR}/table.qza" \
  --p-min-frequency 2 \
  --p-min-samples 1 \
  --o-filtered-table deblur_table_filt.qza

# Remove mitochondria/chloroplast and keep Bacteria/Archaea (contains "p__")
qiime taxa filter-table \
  --i-table deblur_table_filt.qza \
  --i-taxonomy taxa/classification.qza \
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-table deblur_table_filt_contam.qza

cp deblur_table_filt_contam.qza deblur_table_final.qza

# Filter rep seqs to match final table
qiime feature-table filter-seqs \
  --i-data "${DEBLUR_DIR}/representative_sequences.qza" \
  --i-table deblur_table_final.qza \
  --o-filtered-data deblur_rep_seqs_final.qza

# Summaries
qiime feature-table summarize \
  --i-table deblur_table_final.qza \
  --o-visualization deblur_table_final_summary.qzv

# Taxa barplot (uses FINAL filtered table)
qiime taxa barplot \
  --i-table deblur_table_final.qza \
  --i-taxonomy taxa/classification.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization taxa-bar-plots.qzv


echo "Done: $(date)"
```
- Exit vi editor `:wq`
- Run command with:
```
sbatch microbiome.slurm
```
### Create metadata file
```
echo "sample-id" > metadata.tsv
ls casava_reads/*_R1_001.fastq.gz \
  | sed 's#.*/##' \
  | sed 's/_S[0-9]\+_L001_R1_001.fastq.gz//' \
  | sort -u >> metadata.tsv
```

