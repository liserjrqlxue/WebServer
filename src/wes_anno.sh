#!/bin/bash
input=$1
outdir=$(dirname $input)
sampleID=$2
export PATH=/ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/HPC_chip/tools:$PATH
export BGICGA_HOME=/ifs9/BC_B2C_01A/B2C_SGD/Newborn/analysis_pipeline/BGICG_Annotation
cfg=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/bin/config_BGI59M_CG_single.2019.pl
anno=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/bin/bgicg_anno.pl
anno2xlsx=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/anno2xlsx/anno2xlsx

time perl -ne 'chomp;@ln=split /\s+/,$_;print join("\t",@ln),"\n"' $input > $input.fix
time perl $anno $cfg -t tsv -o $input.anno $input.fix
/ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/ACMGlocalAnno/ACMGlocalAnno -input $input.anno -output $input.anno.acmg
/ifs9/B2C_COM_PH2/pipelines/wes-annotation/env/miniconda3/envs/ss/bin/python3 /ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/localSpliceAI/spliceai_anno.py -c /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/spliceai.yaml -b $input.anno.acmg -o $input.anno.acmg --process 5
. /ifs9/B2C_COM_PH2/pipelines/wes-annotation/env/miniconda3/etc/profile.d/conda.sh
conda activate vep
export PYTHONPATH=/ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/PVS/:$PYTHONPATH
python /ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/PVS/localautopvs1/autopvs1_in_bgianno.py -i $input.anno.acmg.spliceai.tsv -o $input.anno.acmg.spliceai.autopvs1.tsv -p 1
conda deactivate

#$anno2xlsx -redis -acmg          -snv $input.anno.ACMG.updateFunc -redisAddr 10.2.1.4:6380
$anno2xlsx -acmg -autoPVS1 -redis -prefix $outdir/$sampleID -snv $input.anno.acmg.spliceai.autopvs1.tsv -redisAddr 10.2.1.4:6380 -allgene

export PYTHONPATH=/ifs9/B2C_COM_PH2/pipelines/wes-annotation/src/bio_toolkit:$PYTHONPATH

python -m bio_toolkit.pipeline.phgd_anno --in $outdir/$sampleID.Tier1.xlsx

time=`date '+%Y-%m-%d %H:%M:%S'`
echo $time $0 >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log
