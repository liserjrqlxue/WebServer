#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd;
use File::Basename;

my$info=shift or die$!;
my$workdir=shift or die$!;

open IN1, "<$info" or die "cannot read info:$!\n";
open OUT1, ">$workdir/script" or die "cannot output script:$!\n";
open OUT2, ">$workdir/sample_QC_info.xls" or die "cannot output info:$!\n";
print OUT2 "Sample\tAverageDepth\tDepth>=30(%)\tCoverage(%)\tCaptureEffiency(%)\tGC(%)\n";
my @grep_result;
while (<IN1>) { #each sample
    chomp;
    my($sample_name_in,$gene)=(split /\s+/,$_);
    my $part1 = substr($sample_name_in, 0,2); my $part2=substr($sample_name_in, 3);
    my $sample_name1= "$part1\.$part2";
    #test sanple 17S0294118
    @grep_result = `less /ifs7/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list |awk '{if(\$1~"$sample_name1"){print \$0}}'`;    #<-------------database
   # @grep_result = `grep $sample_name1 /ifs7/B2C_SGD/USER/yangqian/database/sampleInfoData/sample_list`; 
    foreach my $grep_result(@grep_result){
    print "grep_result is $grep_result\n";
        chomp;
        my $sample_name2=(split /\t/,$grep_result)[0];
        my $outpath=(split /\t/,$grep_result)[9];
        my $product=(split /\t/,$grep_result)[5];
	my $coverage=();
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
			if ($depth > 80){
			$Coverage=(split /\t/,$line)[5];
			$CaptureEffiency=(split /\t/,$line)[7];
			$GC=(split /\t/,$line)[8];
			}
                 }
           }
	}
	#	if( -s "$outpath/$sample_name2/coverage/sgd.coverage.report"){
	 #               $coverage="$outpath/$sample_name2/coverage/sgd.coverage.report";
	  #      }else{
	                $coverage="$outpath/$sample_name2/coverage/coverage.report";
	   #     }
		print "coverage file is $coverage\n";
	        open IN2, "<$coverage" or die "cannot open $coverage:$!\n";
	        while (<IN2>) {
		#	print "in loop1\n line is $_\n";
	                chomp;
	               # if (($_=~/\[Target\] Average depth/ and (not $_=~/rmdup/) )or $_=~/Average sequencing depth of target region/){
	               if (($_=~/\[Target\] Average depth/) or $_=~/Average sequencing depth of target region/){
		#		print "in a\n";
				print "line is $_\n";
	                        $depth2=(split /\t/,$_)[1];
	       	                 print "depth2 depth is $depth2\n";
	       	         }elsif($_=~/\[Target\] Coverage \(>=30x\)/ or  $_=~/Fraction of target region covered with at least 30X/ ){
		#		print "in b\n";
				$x=(split /\t/,$_)[1];
				if($x=~/;/){$x=(split /;/,$x)[1];}
				print "in loop \n30x is $x\n";
			}elsif($_=~/\[Target\] Coverage \(>0x\)/ or $_=~/Coverage of target region/ ){
		#		print "in c\n";
				$Coverage=(split /\t/,$_)[1] if not defined $Coverage;
		#		print "Coverage is $Coverage\n";
			}elsif($_=~/Data mapped to target region \(Mb\)/ or $_=~/\[Target\] Fraction of Target Data in all data/){
		#		print "in d\n";
				$CaptureEffiency=(split /\t/,$_)[1] if not defined $CaptureEffiency;
				if($CaptureEffiency=~/;/){$CaptureEffiency=(split /;/,$CaptureEffiency)[1];}
		#		print "CaptureEffiency is $CaptureEffiency\n";
			}
	        }
		
                print "product is $product\n";
                print "depth is $depth\n";
		print "30x is $x\n";print "Coverage is $Coverage\n";print "CaptureEffiency is $CaptureEffiency\n";
	if ($product=~/BGI59/) {
                    $tag=1 if $depth >=80 or $depth2>=80;
                }else{
                   # $tag=1 if $depth >=100 or $depth2 >=100;
                    $tag=0;
                }
	if ($tag == 1) {
		if ($outpath=~/BGISEQ/ or $outpath=~/Zebra/){
        	print OUT1 "perl /ifs7/B2C_SGD/USER/yangqian/script/search_CNV/exon/exon_graph_gene/new_exon_picture_picture_500.pl $gene $outpath/$sample_name2/coverage/depth.tsv.gz\n";
	}else{
		print OUT1 "perl new_exon_picture_picture.pl $gene $sample_name2 $outpath";
	}
		print OUT2 "$sample_name2\t$depth2\t$x\t$Coverage\t$CaptureEffiency\t$GC\n";
	}
    }
}
print STDERR "qsub -cwd -l vf=15G,p=1 -P SGD-RD -wd $workdir $workdir/script\n";
print STDERR `qsub -cwd -l vf=15G,p=1 -P SGD-RD -wd $workdir $workdir/script`;
