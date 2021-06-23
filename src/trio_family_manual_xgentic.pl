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
#open JOB_LOG, ">$here/job.log" or die "cannot oputput list:$!\n";
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
#system("sh run.new.sh &");
my $qsub=`qsub -cwd -l vf=15g,num_proc=1 -P B2C_SGD -q bc_b2c.q -terse run.new.sh`;chomp $qsub;
print JOB_LOG "$qsub\t$here\n";
my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`;
