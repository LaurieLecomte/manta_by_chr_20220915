#!/bin/bash

# Call SV in all samples, parallelized by chr

# parallel -a 02_infos/chr_list.txt -k -j 10 srun -c 1 --mem-per-cpu=10G -p medium --time=7-00:00 -J 01_call_{} -log/01_call_{}_%j.log /bin/sh 01_scripts/01_call.sh {} 
# srun -c 2 -p medium --time=7-00:00 -J 01_call_ssa01-23 -o log/01_call_ssa01-23_%j.log /bin/sh 01_scripts/01_call.sh 'ssa01-23' &

# VARIABLES
GENOME="03_genome/genome.fasta"
CHR_LIST="02_infos/chr_list.txt"
BAM_DIR="04_bam"
CALLS_DIR="05_calls"
MERGED_DIR="06_merged"
FILT_DIR="07_filtered"

REGION=$1

MANTA_INST_DIR=$(conda info --envs | grep -Po 'manta\K.*' | sed 's: ::g' | sed 's/\*//')
CONFIG_FILE=$(find $MANTA_INST_DIR/bin -name 'configManta.py')

BAM_LIST=$(for file in $(ls $BAM_DIR/*.bam); do echo '--bam' "$file" ; done)

# LOAD REQUIRED MODULES

if [[ ! -d $CALLS_DIR/"$REGION" ]]
then
  mkdir $CALLS_DIR/"$REGION"
fi

# increase number of opened files
ulimit -S -n 2048


# 1. Generate bed for given chromosome
#less "$GENOME".fai | grep $REGION | cut -f1,3,4 > 02_infos/"$REGION".bed
#echo $REGION > 02_infos/"$REGION".bed
bgzip 02_infos/"$REGION".bed
tabix -p bed 02_infos/"$REGION".bed.gz

# 2. Workflow configuration : set reference genome and samples for which SV are to be called in order to generate an executable (runWorkflow.py)
$CONFIG_FILE --referenceFasta $GENOME --runDir $CALLS_DIR/"$REGION" --callRegions 02_infos/"$REGION".bed.gz $(echo $BAM_LIST)

# 3. Launch resulting executable
## -j controls the number of cores/nodes
$CALLS_DIR/"$REGION"/runWorkflow.py -j 2

# 4. Rename output
#05_calls/ssa01-23/results/variants/