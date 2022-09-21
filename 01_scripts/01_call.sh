#!/bin/bash

# Call SV in all samples, parallelized by chr

# parallel -a 02_infos/chr_list.txt -k -j 10 srun -c 4 --mem=20G -p medium --time=7-00:00 -J 01_call_{} -log/01_call_{}_%j.log /bin/sh 01_scripts/01_call.sh {} &
# srun -c 2 -p medium --time=7-00:00 -J 01_call_ssa01-23 -o log/01_call_ssa01-23_%j.log /bin/sh 01_scripts/01_call.sh 'ssa01-23' &

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

## Paths and exec locations for running manta
MANTA_INST_DIR=$(conda info --envs | grep -Po 'manta\K.*' | sed 's: ::g' | sed 's/\*//')
CONFIG_FILE=$(find $MANTA_INST_DIR/bin -name 'configManta.py')
CONVERT_INV=$(find $MANTA_INST_DIR/bin -name 'convertInversion.py')
SAMTOOLS_PATH=$(find $MANTA_INST_DIR -name 'samtools')

# LOAD REQUIRED MODULES
module load bcftools/1.15


# Increase opened file number limit
ulimit -S -n 2048

# 0. Create output directory
if [[ ! -d $CALLS_DIR/"$REGION" ]]
then
  mkdir $CALLS_DIR/"$REGION"
else
  rm -r $CALLS_DIR/"$REGION"/*
fi


# 1. Generate bed for given chromosome
less "$GENOME".fai | grep -Fw "$REGION" | cut -f1,3,4 > 02_infos/"$REGION".bed
bgzip 02_infos/"$REGION".bed -f
tabix -p bed 02_infos/"$REGION".bed.gz -f

# 2. Workflow configuration : set reference genome and samples for which SV are to be called in order to generate an executable (runWorkflow.py)
$CONFIG_FILE --referenceFasta $GENOME --runDir $CALLS_DIR/"$REGION" --callRegions 02_infos/"$REGION".bed.gz $(echo $BAM_LIST)

# 3. Launch resulting executable
## -j controls the number of cores/nodes
$CALLS_DIR/"$REGION"/runWorkflow.py -j 2

# 4. Convert BNDs to INVs : the convertInversion.py script changes BNDs to INVs and adds a SVLEN field to these SVs
$CONVERT_INV $SAMTOOLS_PATH $GENOME $CALLS_DIR/"$REGION"/results/variants/diploidSV.vcf.gz > $CALLS_DIR/"$REGION"/results/variants/diploidSV_converted.vcf

# 5. Sort and rename output
bcftools sort $CALLS_DIR/"$REGION"/results/variants/diploidSV_converted.vcf -Oz > $CALLS_DIR/"$REGION"/"$REGION"_sorted.vcf.gz
