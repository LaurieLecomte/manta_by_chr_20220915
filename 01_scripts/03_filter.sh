#!/bin/bash

# Filter concatenated VCF
# srun -c 1 -p small -J 03_filter -o log/03_filter_%j.log /bin/sh 01_scripts/03_filter.sh &

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

MERGED_VCF="$MERGED_DIR/merged_sorted.vcf.gz"

## Paths and exec locations for running manta
MANTA_INST_DIR=$(conda info --envs | grep -Po 'manta\K.*' | sed 's: ::g' | sed 's/\*//')
CONFIG_FILE=$(find $MANTA_INST_DIR/bin -name 'configManta.py')
CONVERT_INV=$(find $MANTA_INST_DIR/bin -name 'convertInversion.py')
SAMTOOLS_PATH=$(find $MANTA_INST_DIR -name 'samtools')


# LOAD REQUIRED MODULES
module load bcftools/1.15

# 1. Filter
bcftools filter -i 'FILTER=="PASS"' $MERGED_VCF -Oz > $FILT_DIR/"$(basename -s .vcf.gz $MERGED_VCF)"_PASS.vcf.gz