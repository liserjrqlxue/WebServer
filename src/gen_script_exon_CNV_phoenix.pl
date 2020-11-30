use strict; 
use Getopt::Long;
use Cwd;
use File::Basename;

my$info=shift or die$!;
my$workdir=shift or die$!;

open IN1, "<$info" or die "cannot read info:$!\n";
open OUT1, ">$workdir/script" or die "cannot output script:$!\n";
open OUT2, ">$workdir/sample_QC_info.xls" or die "cannot output info:$!\n";
print OUT2 "Sample\tAverageDepth\tDepth>=20\tQ20\tQ30\n";
my @grep_result;
while (<IN1>) { #each sample
    chomp;
    my($sample_name_in,$gene)=(split /\s+/,$_);
    my $part1 = substr($sample_name_in, 0,2); my $part2=substr($sample_name_in, 3);
    my $sample_name1= "$part1\.$part2";
    @grep_result = `less /ifs7/B2C_USER/yehaodong/phoenix |awk '{if(\$1~"$sample_name1"){print \$0}}'`;    #<-------------database
    foreach my $grep_result(@grep_result){
    	print "grep_result is $grep_result\n";
    	chomp;
    	my $sample_name2=(split /\t/,$grep_result)[0];
    	my $outpath=(split /\t/,$grep_result)[10];
		my $coverage=();
		my $q20;my $q30;my $depth;my $cov20;
		my @gl= glob "$outpath/result/$sample_name2/$sample_name2\_quality.txt" ;
		print "$gl[0]\n";
    	if (-e "$outpath/result/$sample_name2/$sample_name2\_quality.txt"){
			$q20=`grep Q20 $outpath/result/$sample_name2/$sample_name2\_quality.txt|awk -F "\\t" '{print \$NF}'`;chomp $q20;
			print "q20 is $q20\n";
			$q30=`grep Q30 $outpath/result/$sample_name2/$sample_name2\_quality.txt|awk -F "\\t" '{print \$NF}'`;chomp $q30;
			print "q30 is $q30\n";
		}
		$coverage="$outpath/work/$sample_name2/coverage/coverage.report";
		print "coverage file is $coverage\n";
		open IN2, "<$coverage" or next;
		print $q20;

		while (<IN2>) {
			chomp;
       		if ($_=~/\[Target\] Average depth\(rmdup\)/){
	        	$depth=(split /\t/,$_)[1];
	        	print "depth is $depth\n";
			}elsif($_=~/\[Target\] Coverage \(>=20x\)/){
				$cov20=(split /\t/,$_)[1];
				print "cov20x is $cov20\n";
			}
    	}
		if ($q20 >= "90%" and $q30>="85%" and $depth >= 100 and $cov20>="95%"){
			print "write script\n";
			print OUT1 "perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/new_exon_picture_picture_2000.pl $gene $outpath/work/$sample_name2/coverage/depth.tsv.gz\n";  #20190905
			print OUT2 "$sample_name2\t$depth\t$cov20\t$q20\t$q30\n";
		}
    }
}
print STDERR "qsub -cwd -l vf=15G,p=1 -P B2C_SGD -wd $workdir $workdir/script\n";
print STDERR `qsub -cwd -l vf=15G,p=1 -P B2C_SGD -wd $workdir $workdir/script`;

my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
