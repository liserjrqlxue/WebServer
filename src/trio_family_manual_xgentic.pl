#!/usr/bin/perl -w
use strict;
#yujingtang@genomcs.cn
use File::Basename;
use Cwd;

my $list=shift;
my $here = shift or die$!;
my $qc=shift || "90,85,100,95";
my $is_trio=shift || "null";

`dos2unix $list`;
print "$qc\n";
$here=`readlink -e $here`;chomp $here;
open IN, "<$list" or die "cannot open list:$!\n";
open JOB_LOG, ">$here/job.log" or die "cannot oputput list:$!\n";
open RUN,  ">$here/run.new.sh" or die "cannot output $here/run.new.sh\n";
#my %family=();
#my %gender=();
my %path=();
$/="\n\n";
while (<IN>){  # each \n\n
	chomp;
	my @sample=split /\n/;
#	@{$family{$sample[0]}}=@sample;  #in %family proband store will have repeat, like proband proband A B C ...
	open Famlist, ">$here/$sample[0].list" or die "cannot oputput Famlist:$!\n";
	foreach my $sample(@sample){
		$path{$sample}=(split /\t/,`perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $sample`)[0];
		chomp $path{$sample};
		print Famlist "$path{$sample}\n";
		if ($is_trio=~/couple/){print RUN "sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/xgentic.excel.sh $path{$sample} DX1515 ./ \n"}
		if ($is_trio=~/allgene/){print RUN "sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/xgentic.excel_allgene.sh $path{$sample} DX1515 ./ \n"}
		if ($is_trio=~/single/){print RUN "sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/tools/xgentic.excel.sh $path{$sample} DX0458 ./ \n";}
	}
	if ($is_trio=~/single/){next}
	print RUN "sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/trio/trio.sh $here/$sample[0].list $sample[0] ";
	if ($is_trio=~/couple/){
		print RUN "couple\n";
	}elsif ($is_trio=~/trio/){
		print RUN "trio\n";
	}elsif ($is_trio=~/allgene/){
		print RUN "allgene\n";
	}else{
		print RUN "\n";
	}
}
close RUN;
chdir "$here";
my $qsub=`qsub -cwd -l vf=12g,num_proc=1 -P B2C_SGD -terse run.new.sh`;chomp $qsub;
print JOB_LOG "$qsub\t$here\n";
my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`;



=head

$/="\n";
foreach my $sample (sort keys %path){
	$gender{$sample}=`grep -q "gender Male" $path{$sample}/coverage/gender.txt && echo M||echo F`;
	chomp $gender{$sample};
}

#----------------------------prepare output
foreach my $proband (sort keys %family){
	my @order=order_gender(\@{$family{$proband}});
	print "mkdir $here/$order[0]\n";
	`mkdir $here/$order[0]`;
	my @gender;
	my @bed;
	#my @filterStat;
	my @coverage;
	my @largeCnv;
	my @exonCnv;
	`echo -e 'Sample\tChr\tStart\tEnd\tDetect\tCopy_Num\tactual_len(Kb)\tLen(Kb)\tRatio((End-Start+1)/len)\tCyBand\tSummary' >$here/$order[0]/CNVkit_cnv.xls`;
	`>$here/$order[0]/sample_gender.xls`;
	foreach my $ordered_sample (@order){
			#print "ordered_sample is $ordered_sample\n";
			push @gender,$gender{$ordered_sample};
			push @bed, "$path{$ordered_sample}/annotation/$ordered_sample.out.ACMG.updateFunc";
			#@filterStat=`ls $path{$order[0]}/filter/*/*filter.stat`;chomp @filterStat;
			push @coverage, "$path{$ordered_sample}/coverage/coverage.report";
			my $largeCnvlink=`readlink -e $path{$ordered_sample}/../CNVkit/CNVkit_cnv.xls`;chomp $largeCnvlink;
			`grep $ordered_sample $largeCnvlink>>$here/$order[0]/CNVkit_cnv.xls`;
			my $genderlink=`readlink -e $path{$ordered_sample}/../CNVkit/$ordered_sample.gender||readlink -e $path{$ordered_sample}/../CNVkit/$ordered_sample/*.gender`;chomp $genderlink;
			`cat $genderlink >>$here/$order[0]/sample_gender.xls`;
			#unless (grep{ $_ eq $largeCnvlink } @largeCnv){push @largeCnv,$largeCnvlink}
			my $exonCnvlink=`readlink -e $path{$ordered_sample}/../ExomeDepth/${ordered_sample}_exon_anno.tsv||readlink -e $path{$ordered_sample}/../ExomeDepth/$ordered_sample/all.CNV.calls.anno`;chomp $exonCnvlink;
			push @exonCnv,$exonCnvlink;
	}	
	
	my $tmp= join ( "\\n",@order);
	my $bed=join(" ",@bed);
	#my $karyotype="$path{$order[0]}/../CNVkit/sample_aneuploid.xls";
	#my $filterStat=join(",",@filterStat);
	my $order=join ( ",",@order);
	my $coverage=join ( ",",@coverage);
	my $exonCnv=join(",",@exonCnv);
	`sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/CNVkitanno.sh $here/$order[0]`;
	#my $largeCnv=join(",",@largeCnv);
	open RUN,  ">$here/$order[0]/run.new.sh" or die "cannot output $here/$order[0]/run.new.sh\n";
	print RUN  
	
"#!/bin/bash
echo -e '$tmp' > fam.info
echo family.plus.new.anno
time perl /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/trio/family.plus.all.pl -o $here/$order[0]/$order[0].family.out.ACMG.updateFunc -h /ifs9/B2C_COM_P2/pub/sgd/Pipeline/exome_diagnose_V0/trio/header $bed
/ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/xgentic_Annotation/anno2xlsx/anno2xlsx \\
	-prefix $here/$order[0]/$order[0] \\
   	-acmg \\
   	-redis \\
   	-redisAddr 10.2.1.4:6380 \\
   	-product  DX1515 \\
   	-snv $here/$order[0]/$order[0].family.out.ACMG.updateFunc \\
   	-specVarList /ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/xgentic_Annotation/anno2xlsx/db/spec.var.lite.list \\
   	-list $order \\
   	-qc $coverage \\
   	-exon $exonCnv \\
   	-large $here/$order[0]/CNVkit_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls";
	print RUN "\\\n    -trio\n" if ($is_trio=~/trio/);
	print RUN "\\\n    -couple\n" if ($is_trio=~/couple/);


	chdir "$here/$order[0]";
	my $qsub=&get_job_id(`qsub -cwd -l vf=8g,num_proc=1 -P B2C_SGD run.new.sh`);
	print JOB_LOG "$qsub\t$here/$order[0]\n";
}
close JOB_LOG;

sub order_gender{
	my $family = shift;
	my @family=@$family;
	my @final_order;
	my @male;
	my @female;
	#if (scalar @family=3) and $is_trio=~/trio/ ){
	push @final_order,$family[0];
	for my $i(1..$#family){
		if ($gender{$family[$i]} eq "M"){push @male,$family[$i]}
		if ($gender{$family[$i]} eq "F"){push @female,$family[$i]}
	}
	push @final_order,@male,@female;
	return @final_order;
}

sub get_job_id{
	my $back = shift @_; 
	my $job_id;
	if(defined $back && $back =~ /^Your job (\d+) \(\"(.*?)\"\) has been submitted$/){
		$job_id = $1; 
	}   
	else{
	}   
	return $job_id;
}

my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
=cut
