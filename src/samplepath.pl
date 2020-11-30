use strict; 
use Getopt::Long;
use Cwd;
use File::Basename;

my $sample=shift or die $!;
my $qctag=shift|| "Y";
phoenix_qc($sample);
exome_diagnose_qc($sample);


sub phoenix_qc {
    my $sample_name=shift;
    my $part1 = substr($sample_name, 0,2); my $part2=substr($sample_name, 3);
    my $sample_name="$part1\.$part2";
	my @grep_result;
    @grep_result = `less /ifs7/B2C_USER/yehaodong/phoenix |awk '{if(\$1~"$sample_name"){print \$0}}'`;    #<-------------database
    foreach my $grep_result(reverse(@grep_result)){
    	chomp $grep_result;
		my $sample_name2=(split /\t/,$grep_result)[0];
    	my $outpath=(split /\t/,$grep_result)[10];
		my $coverage=();
		my $q20;my $q30;my $depth;my $cov20;
    	unless(-e "$outpath/result/$sample_name2/$sample_name2\_quality.txt"){next}
		$q20=`grep Q20 $outpath/result/$sample_name2/$sample_name2\_quality.txt|awk -F "\\t" '{print \$NF}'`;chomp $q20;
		$q30=`grep Q30 $outpath/result/$sample_name2/$sample_name2\_quality.txt|awk -F "\\t" '{print \$NF}'`;chomp $q30;
		$coverage="$outpath/work/$sample_name2/coverage/coverage.report";
		open IN2, "<$coverage" or next;
		while (<IN2>) {
			chomp;
       		if ($_=~/\[Target\] Average depth\(rmdup\)/){
	        	$depth=(split /\t/,$_)[1];
			}elsif($_=~/\[Target\] Coverage \(>=20x\)/){
				$cov20=(split /\t/,$_)[1];
			}
    	}
		if ($qctag eq "Y" and (split /\t/,$grep_result)[4] eq "Y"){
			print "$outpath/work/$sample_name2\t$outpath/result/$sample_name2\n";  #20190905
		}elsif($qctag eq "L" and $q20 >= "90%" and $q30>="85%" and $depth >= 100 and $cov20>="95%"){
			print "$outpath/work/$sample_name2\t$outpath/result/$sample_name2\n";
		}elsif($qctag eq "N"){
			print "$outpath/work/$sample_name2\t$outpath/result/$sample_name2\n";
		}
    }
}

sub exome_diagnose_qc{
	my $sample_name=shift;
	my $part1 = substr($sample_name, 0,2); my $part2=substr($sample_name, 3);
	my $sample_name="$part1\.$part2";
	my @grep_result;
	@grep_result = `less /ifs9/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list |awk '{if(\$1~"$sample_name"){print \$0}}'`;
	foreach my $grep_result(reverse(@grep_result)){
		chomp $grep_result;
		my $sample_name2=(split /\t/,$grep_result)[0];
		my $outpath=(split /\t/,$grep_result)[9];
		my $coverage=();
		my $q20;my $q30;my $depth;my $cov20;
		unless (-e "$outpath/total_coverage_depth_stat"){next};
		$q20=`less $outpath/total_coverage_depth_stat| awk -F '\\t' '{for(i=1;i<=NF;i++)if(\$i~"Q20")num=i;if(\$2~"$sample_name2"){print \$num}}'`;chomp $q20;
		$q30=`less $outpath/total_coverage_depth_stat| awk -F '\\t' '{for(i=1;i<=NF;i++)if(\$i~"Q30")num=i;if(\$2~"$sample_name2"){print \$num}}'`;chomp $q30;
		$coverage="$outpath/$sample_name2/coverage/coverage.report";
		open IN2, "<$coverage" or next;
		while (<IN2>) {
			chomp;
			if ($_=~/\[Target\] Average depth\(rmdup\)/){
				$depth=(split /\t/,$_)[1];
			}
			if($_=~/\[Target\] Coverage \(>=20x\)/){
				$cov20=(split /\t/,$_)[1];
			}else{
				$cov20="100%" #NO Cov20:default=pass
			}
		}
		my $qualified=`cat $outpath/$sample_name2/coverage/QC_check.txt`;chomp $qualified;
		if ($qctag eq "Y" and $qualified=~/\.qualified/){
			print "$outpath/$sample_name2\t$outpath/$sample_name2\n";
		}elsif($qctag eq "L" and $q20 >= "90%" and $q30>="80%" and $depth >= 79){
			print "$outpath/$sample_name2\t$outpath/$sample_name2\n";
		}elsif($qctag eq "N"){
			print "$outpath/$sample_name2\t$outpath/$sample_name2\n";
		}
	}
}
