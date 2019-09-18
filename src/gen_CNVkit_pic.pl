#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd;
use File::Basename;

my$info=shift or die$!;   #sample ,or sample chr pos1 pos2, split by space
my$workdir=shift or die$!;
open IN1, "<$info" or die "cannot read info:$!\n";
open OUT1, ">$workdir/script" or die "cannot output script:$!\n";
open OUT2, ">$workdir/sample_QC_info.xls" or die "cannot output info:$!\n";
print OUT2 "Sample\tAverageDepth\tDepth>=20(%)\tCoverage(%)\tCaptureEffiency(%)\tGC(%)\n";
my @grep_result;
while (<IN1>) { #each sample
	chomp;
	my ($sample_name_in,$chr,$pos1,$pos2)=(" "," "," "," ");
	my @a=(split /\s+/,$_);
	if (scalar @a==4) {
		($sample_name_in,$chr,$pos1,$pos2)=($a[0],$a[1],$a[2],$a[3]);
	}elsif(scalar @a==1){
		$sample_name_in=$a[0];
	}
	my $part1 = substr($sample_name_in, 0,2); my $part2=substr($sample_name_in, 3);
	my $sample_name1= "$part1\.$part2";
	#test sanple 17S0294118
	@grep_result = `less /ifs7/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list |awk '{if(\$1~"$sample_name1"){print \$0}}'`;	#<-------------database
	# @grep_result = `grep $sample_name1 /ifs7/B2C_SGD/USER/yangqian/database/sampleInfoData/sample_list`; 
	foreach my $grep_result(@grep_result){
	print "grep_result is $grep_result\n";
	chomp;
	my $sample_name2=(split /\t/,$grep_result)[0];
	my $outpath=(split /\t/,$grep_result)[9];
	my $product=(split /\t/,$grep_result)[5];
	my $coverage=();
	my $q30=();
	my $tag=0;
	my $depth2= my $depth=my $Coverage=my $x=my $CaptureEffiency=my $GC=();
	if (-e "$outpath/total_coverage_depth_stat"){
		open TOTAL, "<$outpath/total_coverage_depth_stat" or die "cannot open $outpath/total_coverage_depth_stat:$!\n";
		while (<TOTAL>){
			chomp;
			next if /Order/;
			my $line=$_;
			my $t_sample=(split /\t/,$line)[1];
			if($t_sample eq $sample_name2){
				print "in totalfile sample is $t_sample\n";
				$depth=(split /\t/,$line)[4];
				$q30=(split /\t/,$line)[3];
				if ($depth > 100){
					$Coverage=(split /\t/,$line)[5];
					$CaptureEffiency=(split /\t/,$line)[7];
					$GC=(split /\t/,$line)[8];
				}
			}
		}
	}
	my $coverage_file="$outpath/$sample_name2/coverage/coverage.report";
	print "coverage file is $coverage_file\n";
	open IN2, "<$coverage_file" or next;
	while (<IN2>) {
		#print "in loop1\n line is $_\n";
		chomp;
		# if (($_=~/\[Target\] Average depth/ and (not $_=~/rmdup/) )or $_=~/Average sequencing depth of target region/){
		if (($_=~/\[Target\] Average depth/) or $_=~/Average sequencing depth of target region/){
			#print "in a\n";
			#print "line is $_\n";
			$depth2=(split /\t/,$_)[1];
			#print "depth2 depth is $depth2\n";
		}elsif($_=~/\[Target\] Coverage \(>=20x\)/ or  $_=~/Fraction of target region covered with at least 20X/ ){
			#print "in b\n";
			$x=(split /\t/,$_)[1];
			if($x=~/;/){$x=(split /;/,$x)[1];}
			$x=(split /\%/,$x)[0];
			print "in loop \n20x is $x\n";
		}elsif($_=~/\[Target\] Coverage \(>0x\)/ or $_=~/Coverage of target region/ ){
			#print "in c\n";
			$Coverage=(split /\t/,$_)[1] if not defined $Coverage;
			#print "Coverage is $Coverage\n";
		}elsif($_=~/Data mapped to target region \(Mb\)/ or $_=~/\[Target\] Fraction of Target Data in all data/){
			#print "in d\n";
			$CaptureEffiency=(split /\t/,$_)[1] if not defined $CaptureEffiency;
			if($CaptureEffiency=~/;/){$CaptureEffiency=(split /;/,$CaptureEffiency)[1];}
			#print "CaptureEffiency is $CaptureEffiency\n";
		}
	}
	#print "product is $product\n";
	#print "depth is $depth\n";
	#print "20x is $x\n";print "Coverage is $Coverage\n";print "CaptureEffiency is $CaptureEffiency\n";
	if ($product=~/BGI59/ and $outpath=~/BGISEQ/ or $outpath=~/Zebra/ or  $outpath=~/MGISEQ-2000/) {
		$tag=1 if ($depth >=100 or $depth2>=100) and $x>=95 and $q30>85;
	}else{
		$tag=0;
	}

	if ($tag == 1) {
		if (scalar @a==4){
			print OUT1 "sh /ifs7/B2C_RD_P2/USER/hanrui/WES/plot/run_CNVkit_plot.sh $sample_name_in $outpath ./ $chr $pos1 $pos2\n";
		}elsif(scalar @a==1){
			print OUT1 "sh /ifs7/B2C_RD_P2/USER/hanrui/WES/plot/run_CNVkit_plot.sh $sample_name_in $outpath ./\n";
		}
		print OUT2 "$sample_name2\t$depth2\t$x\t$Coverage\t$CaptureEffiency\t$GC\n";
	}
	}
}
print STDERR "qsub -cwd -l vf=2G,p=1 -P B2C_SGD -wd $workdir $workdir/script\n";
print STDERR `qsub -cwd -l vf=2G,p=1 -P B2C_SGD -wd $workdir $workdir/script`;
