#!/bin/bash

input=$1
outdir=$(dirname $input)
sampleID=${2:-test}

jobid=`qsub -cwd -l vf=10g,num_proc=3 -P B2C_SGD -q b2c_com_s1.q -e $outdir -o $outdir -terse $0 $*` || jobid=0
[[ $jobid != 0 ]] && exit
cfg=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/bin/config_BGI59M_CG_single.2019.pl
anno=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/bin/bgicg_anno.pl
anno2xlsx=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/anno2xlsx/anno2xlsx

time /ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/perl -ne 'chomp;@ln=split /\s+/,$_;print join("\t",@ln),"\n"' $input > $input.fix
time /ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/perl $anno $cfg -t tsv -o $input.anno $input.fix
/ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/ACMGlocalAnno/ACMGlocalAnno -input $input.anno -output $input.anno.acmg
/ifs9/B2C_COM_PH2/pipelines/wes-annotation/env/miniconda3/envs/ss/bin/python3 /ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/localSpliceAI/spliceai_anno.py -c /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/spliceai.yaml -b $input.anno.acmg -o $input.anno.acmg --process 1

. /ifs9/B2C_COM_PH2/pipelines/wes-annotation/env/miniconda3/etc/profile.d/conda.sh
conda activate vep
export PYTHONPATH=/ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/PVS/:$PYTHONPATH
python /ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/PVS/localautopvs1/autopvs1_in_bgianno.py -i $input.anno.acmg.spliceai.tsv -o $input.anno.acmg.spliceai.autopvs1.tsv -p 1
conda deactivate

$anno2xlsx -acmg -autoPVS1 -redis -prefix $outdir/$sampleID -snv $input.anno.acmg.spliceai.autopvs1.tsv -allgene -cfg /ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/anno2xlsx/etc/config_Tier3.toml

time=`date '+%Y-%m-%d %H:%M:%S'`
echo $time $0 >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log
