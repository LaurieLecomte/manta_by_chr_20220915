# SV calling from short reads using **MANTA**

# Pipeline Overview

As noted in manta's [documentation](https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md#capabilities), manta has not been tested for joint SV calling in large cohorts and may crash if too many or too heavy files are provided as inputs. 
This pipeline parallelizes the SV calling step across **chromosomes** in order to reduce memory requirements. Note that this workaround will likely **prevent manta from detecting inter-chromosomal translocations**.

1. Call SVs in all samples by chromosome
2. Concatenate all VCFs
3. Filter


# Prerequisites

### Files 

* A **reference genome** (`.fasta`) and its **index** (`.fai`) in `03_genome`
* **Bam files** for all samples and their index. These can be soft-linked in the `04_bam` folder for easier handling : if `$BAM_PATH` is the remote path to bam files, use `for file in $(ls -1 $BAM_PATH/*); do ln -s $file ./04_bam; done`
* A **bam files list** in `02_infos`. This list can be generated with the following command, where `$BAM_DIR` is the path of the directory where bam files are located : `ls -1 $BAM_DIR/*.bam > 02_infos/bam_list.txt`
* A **chromosomes list** (or contigs, or sites) in `02_infos`. This list is used for parallelizing the SV calling step. It can be produced from the indexed genome file ("$GENOME".fai) : `less "$GENOME".fai | cut -f1 > 02_infos/chr_list.txt`. **If some chromosomes are to be excluded from the SV calling step, these need to be removed from the list beforehand.**

* Optional : a list of samples IDs and their population (and/or sex) for popgen analysis, such as PCA or FST calculation, in `02_infos`. 