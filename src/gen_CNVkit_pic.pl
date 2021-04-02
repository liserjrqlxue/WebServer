#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd;
use File::Basename;

my$info=shift or die$!;   #sample ,or sample chr pos1 pos2, split by space
my$workdir=shift or die$!;
open IN1, "<$info" or die "cannot read info:$!\n";
open OUT1, ">$workdir/script" or die "cannot output script:$!\n";
my @grep_result;
while (<IN1>) { #each sample
	chomp;
	my ($sample_name_in,$chr,$pos1,$pos2)=(" "," "," "," ");
	my @a=(split /\s+/,$_) if length $_ > 0;
	if (scalar @a==4) {
		($sample_name_in,$chr,$pos1,$pos2)=($a[0],$a[1],$a[2],$a[3]);
	}elsif(scalar @a==1){
		$sample_name_in=$a[0];
	}else{
	        print "please input sampleID ,or sampleID chr pos1 pos2, split by space\n" and die;
	}
	my @path=`perl src/samplepath.pl $sample_name_in L`;
	my $outpath=(split /\t/,$path[0])[0];
	if (scalar @a==4){
		print OUT1 "sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/CNVkit/bin/run_CNVkit_plot_v2.sh $sample_name_in $outpath/../ ./ $chr $pos1 $pos2\n" or print "$!\n";
		#`sh /ifs9/BC_PS/hanrui/pipeline/CNVkit/bin/run_CNVkit_plot_v1.sh $sample_name_in $outpath ./ $chr $pos1 $pos2`;
	}elsif(scalar @a==1){
		print OUT1 "sh /ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/CNVkit/bin/run_CNVkit_plot_v2.sh $sample_name_in $outpath/../ $workdir\n" or print "$!\n";
		#`sh /ifs9/BC_PS/hanrui/pipeline/CNVkit/bin/run_CNVkit_plot_v1.sh $sample_name_in $outpath ./`;
	}
}
my %hash = (
1 => "compute-20-32",
2 => "compute-20-10",
3 => "compute-55-11",
4 => "compute-35-104",
);
my $num=int(rand(3)+1);
print "$num\n";
print STDERR "qsub -cwd -l vf=2G,p=1 -P B2C_SGD -q bc_b2c.q -wd $workdir $workdir/script\n";
print STDERR `qsub -cwd -l vf=2G,p=1 -P B2C_SGD -q bc_b2c.q -wd $workdir $workdir/script`;

my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`

