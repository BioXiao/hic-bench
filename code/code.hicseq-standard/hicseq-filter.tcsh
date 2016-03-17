#!/bin/tcsh
source ./code/code.main/custom-tcshrc     # shell settings

##
## USAGE: hic-filter.tcsh OUTPUT-DIR PARAM-SCRIPT ALIGNMENT-BRANCH OBJECT(S)
##

# process command-line inputs
if ($#argv != 4) then
  grep '^##' $0
  exit
endif

set outdir = $1
set params = $2
set branch = $3
set objects = ($4)

# test number of input objects
set object = $objects[1]
if ($#objects != 1) then
  scripts-send2err "Error: this operation allows only one input object!"
  exit 1
endif

# run parameter script
source $params

# indentify genome directory
set genome = `./code/read-sample-sheet.tcsh $sheet $object genome`
set enzyme = `./code/read-sample-sheet.tcsh $sheet $object enzyme`
set genome_dir = inputs/genomes/$genome

# create path
scripts-create-path $outdir/

# filter
scripts-send2err "Filtering aligned reads..."
samtools view $branch/$object/alignments.bam | gtools-hic filter -v -E $genome_dir/$enzyme.fragments.bed --stats $outdir/stats_with_dups.tsv $filter_params | sort -t'	' -k2 >! $outdir/filtered_with_dups.reg

# remove duplicates
scripts-send2err "Removing duplicates..."
cat $outdir/filtered_with_dups.reg | uniq -f1 | gzip >! $outdir/filtered.reg.gz

# update stats
scripts-send2err "Updating statistics..."
set n_intra_uniq = `cat $outdir/filtered_with_dups.reg | cut -f2 | uniq | cut -d' ' -f1,5 | awk '$1==$2' | wc -l`
set n_inter_uniq = `cat $outdir/filtered_with_dups.reg | cut -f2 | uniq | cut -d' ' -f1,5 | awk '$1!=$2' | wc -l`
Rscript ./code/update-filtered-stats.r $outdir/stats_with_dups.tsv $n_intra_uniq $n_inter_uniq >! $outdir/stats.tsv

# cleanup
rm -f $outdir/filtered_with_dups.reg $outdir/stats_with_dups.tsv

# save variables
set >! $outdir/job.vars.tsv

scripts-send2err "Done."




