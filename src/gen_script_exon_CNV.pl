use strict; 
use Getopt::Long;
use Cwd;
use File::Basename;

my$info=shift or die$!;
my$workdir=shift or die$!;

open IN1, "<$info" or die "cannot read info:$!\n";
open OUT1, ">$workdir/script" or die "cannot output script:$!\n";
while (<IN1>) { #each sample
    chomp;
    my($sample_name_in,$gene)=(split /\s+/,$_);
	my @path=`perl src/samplepath.pl $sample_name_in`;
	my $outpath=(split /\t/,$path[0])[0];
	print "write script\n";
	print OUT1 "perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/new_exon_picture_picture_2000.pl $gene $outpath/coverage/depth.tsv.gz\n";  #20190905
}
print STDERR "qsub -cwd -l vf=15G,p=1 -P B2C_SGD -q bc_b2c.q -wd $workdir $workdir/script\n";
print STDERR `qsub -cwd -l vf=15G,p=1 -P B2C_SGD -q bc_b2c.q -wd $workdir $workdir/script`;
#
my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
