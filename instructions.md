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
.

