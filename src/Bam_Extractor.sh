#!/bin/bash
set -e
[[ $1 ]] && Workdir=`perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $1|head -1|cut -f 1 ` || ( echo "sh $0 sample position" ; exit 1 )
[[ $2 ]] && position=$2 || ( echo "sh $0 sample position" ; exit 1 ) 
outdir=$3
sample=$(basename $Workdir)
bampath=$Workdir/bwa/$sample.final.bam
[[ -e $bampath ]] && samtools view -b $bampath $position >$outdir/$sample.bam && samtools index $outdir/$sample.bam 
