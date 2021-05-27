#!/bin/bash

input=$1
gender=$2

prefix=`basename $input`
dirname=`dirname $input`

jobid=`qsub -cwd -l vf=10g,num_proc=3 -P B2C_SGD -q b2c_com_s1.q -e $dirname -o $dirname -terse $0 $*` || jobid=0
[[ $jobid != 0 ]] && exit

cfg=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/bin/config_BGI59M_CG_single.2019.pl
anno=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/bin/bgicg_anno.pl
anno2xlsx=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/anno2xlsx/anno2xlsx

mkdir -p $dirname/annotation
/ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/perl $anno  $cfg -t vcf -n 5 -b 5000 -q -o $dirname/annotation/$prefix.out -g $gender $input

time /ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/ACMGlocalAnno/ACMGlocalAnno -input $dirname/annotation/$prefix.out -output $dirname/annotation/$prefix.out.acmg

/ifs9/B2C_COM_PH2/pipelines/wes-annotation/env/miniconda3/envs/ss/bin/python3 /ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/localSpliceAI/spliceai_anno.py -c /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/spliceai.yaml -b $dirname/annotation/$prefix.out.acmg -o $dirname/annotation/$prefix.out.acmg --process 5
. /ifs9/B2C_COM_PH2/pipelines/wes-annotation/env/miniconda3/etc/profile.d/conda.sh

conda activate vep
export PYTHONPATH=/ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/PVS/:$PYTHONPATH
python /ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/PVS/localautopvs1/autopvs1_in_bgianno.py -i $dirname/annotation/$prefix.out.acmg.spliceai.tsv -o $dirname/annotation/$prefix.out.acmg.spliceai.autopvs1.tsv -p 1
conda deactivate

$anno2xlsx -mt -acmg -autoPVS1 -redis -prefix $dirname/$prefix -snv $dirname/annotation/$prefix.out.acmg.spliceai.autopvs1.tsv -gender $gender -redisAddr 10.2.1.4:6380
