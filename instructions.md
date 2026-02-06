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

