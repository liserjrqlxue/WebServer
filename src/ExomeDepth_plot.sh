export LOCAL=/home/wangyaoshen/local
export GCC=$LOCAL/gcc-9.2.0
export PATH=$GCC/bin:$LOCAL/bin:$PATH
export CPATH=$GCC/include:$LOCAL/include
export LIBRARY_PATH=$GCC/lib64:$GCC/lib:$LOCAL/lib64:$LOCAL/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$GCC/lib64:$GCC/lib:$LOCAL/lib64:$LOCAL/lib:$LD_LIBRARY_PATH
Bin=/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/ExomeDepth

sample=$1
path=$(perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $sample|head -1|cut -f 1)
gene=$2
if [ $3 == "X" ]
then
  rds_path=$(find $path/../ExomeDepth -name $sample.[MF].all.exons.rds)
  echo "Rscript $Bin/plotX.R $sample $rds_path public/ExomeDepth/$4 $gene"
  Rscript $Bin/plotX.R $sample $rds_path public/ExomeDepth/$4 $gene
else
  rds_path=$(find $path/../ExomeDepth -name $sample.A.all.exons.rds)
  Rscript $Bin/plot.R $sample $rds_path public/ExomeDepth/$4 $gene
fi
