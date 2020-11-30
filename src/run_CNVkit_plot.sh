#!/bin/bash
export PATH=/share/backup/zhongwenwei/app/R-3.2.1/bin:$PATH
export R_LIBS_USER=/share/backup/zhongwenwei/app/R-3.2.1/library
export PATH=/share/backup/zhongwenwei/app/Python-2.7.13/bin:$PATH
#export CPATH=/share/backup/zhongwenwei/app/Python-2.7.13/include:$CPATH
#export LD_LIBRARY_PATH=/share/backup/zhongwenwei/app/Python-2.7.13/lib:$LD_LIBRARY_PATH
SampleID=$1
Workdir=$2
Outdir=$3
echo "$SampleID"
Cns=`find $Workdir/CNVkit/ -name $SampleID.cbs.cns`
Cnr=`find $Workdir/CNVkit/ -name $SampleID.cnr`
echo "$Cns";
echo "$Cnr";
VCF=$Workdir/$SampleID/annotation/$SampleID.final.vcf.gz

if [ $#==6 ];then
	Chr=$4
	Start=$5
	End=$6
fi
if [ $Chr ];then
	Plot=$Outdir/$SampleID.$Chr-$Start-$End.pdf
	cnvkit.py scatter -c $Chr:$Start-$End -s $Cns $Cnr -o $Plot -v $VCF
fi

