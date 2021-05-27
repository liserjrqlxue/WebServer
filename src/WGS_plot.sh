sms_bam=$1
input=$2
outdir=$3

jobid=`qsub -cwd -l vf=5g,num_proc=3 -P B2C_SGD -q b2c_com_s1.q -e $outdir -o $outdir -terse $0 $*` || jobid=0
[[ $jobid != 0 ]] && exit

/ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/python3 \
/ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/public/WGS_plot/cnv/cnv_check.py \
--list $input \
--alldirs $sms_bam \
--outdir $outdir \
--index /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/public/WGS_plot/cnv/bed_lis_index.gz \
--tools /ifs9/BC_B2C_01A/B2C_SGD/SOFTWARES/bin/
