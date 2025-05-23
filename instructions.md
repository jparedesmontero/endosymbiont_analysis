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
