#!/bin/bash
#SBATCH --job-name=microbiome
#SBATCH --cpus-per-task=32
#SBATCH --mem=100G
#SBATCH --time=16:00:00
#SBATCH --output=microbiome.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=jparedes@svsu.edu

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
  --p-front-f TCGTCGGCAGCGTCAGATGTGTATAAGAGACAGGTGYCAGCMGCCGCGGTAA \
  --p-front-r GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAGGGACTACNVGGGTWTCTAAT \
  --p-discard-untrimmed \
  --p-no-indels \
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
