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

