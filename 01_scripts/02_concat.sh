#!/bin/bash

# Concat VCF from each chromosome
# srun -c 1 -p small -J 02_concat -o log/02_concat_%j.log /bin/sh 01_scripts/02_concat.sh &

# VARIABLES
GENOME="03_genome/genome.fasta"
CHR_LIST="02_infos/chr_list.txt"
BAM_DIR="04_bam"
CALLS_DIR="05_calls"
MERGED_DIR="06_merged"
FILT_DIR="07_filtered"

REGION=$1
BAM_LIST=$(for file in $(ls $BAM_DIR/*.bam); do echo '--bam' "$file" ; done)

CPU=2

VCF_LIST="$MERGED_DIR/VCF_list.txt"

## Paths and exec locations for running manta
MANTA_INST_DIR=$(conda info --envs | grep -Po 'manta\K.*' | sed 's: ::g' | sed 's/\*//')
CONFIG_FILE=$(find $MANTA_INST_DIR/bin -name 'configManta.py')
CONVERT_INV=$(find $MANTA_INST_DIR/bin -name 'convertInversion.py')
SAMTOOLS_PATH=$(find $MANTA_INST_DIR -name 'samtools')


# LOAD REQUIRED MODULES
module load bcftools/1.15

# 0. Make VCF list
if [[ -f $VCF_LIST ]]
then
  rm $VCF_LIST
fi

less $CHR_LIST | while read CHR
do
  echo "$CALLS_DIR/"$CHR"/"$CHR"_sorted.vcf.gz" >> $VCF_LIST
done

# 1. Concat, add tags and sort
bcftools concat -f $VCF_LIST | bcftools +fill-tags | bcftools sort -Oz > $MERGED_DIR/merged_sorted.vcf.gz
