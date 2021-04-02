#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd;
use File::Basename;

=head1 DESCRIPTION
    
    You can use this program to make soft links of the raw data to a dir you want.
    exp: perl program -list <list> -QC <strict|loose> -filetype <vcf,Tier1,Tier3,excel,exome_picture> -target </ifs9/B2C_SGD/PROJECT/upload/sample_data_soft_links/date>


=head2 PARAMETERS

    -list: The path and file name of a list containig sample name. each of them should be sperated by \n.
    -target: The folder to put the soft links. such as /ifs9/B2C_SGD/PROJECT/upload/sample_data_soft_links/2019_08_08_1545.
    -filetype: The file type you want to copy,  each of them should be sperated by "," ;
                filetype include vcf,Tier1,excel,exome_picture
		excel include Tier123 and bed.gz.*.xlsx
                defult is vcf,Tier1,excel
    -hlpe|-h:the help information. 
             by yujingtang@genomics.cn
    
=cut

my $time_string = `date "+%Y_%m_%d_%H%M"`;
chomp $time_string;

our %opts = (
    #'list' => "./list",
    'filetype' => "vcf,Tier1,excel,picture",
    'target' => "/ifs9/B2C_SGD/PROJECT/upload/sample_data_soft_links/$time_string",
    'QC' =>"strict",
);

GetOptions(\%opts, "list=s", "target:s", "filetype:s", "QC:s" ,"help|h" );
die `pod2text $0` unless $opts{list} ;
die `pos2text $0` if($opts{help});
print "start\n";
print"$opts{target}\n$opts{filetype}\n$opts{QC}\n";
my $QC=$opts{QC};
print "target is $opts{target}\n";
mkdir $opts{target} unless -d $opts{target};
open IN1, "<$opts{list}" or die "cannot read $opts{list}:$!\n";
open OUT, ">$opts{target}/found_list.xls" or die "cannot output $opts{target}/found_list.xls:$!\n";
print OUT "sample_name\tsample_library_ID\tRawdata_path\tResult_data_path\n";
my @grep_result;
while (<IN1>) { #each sample
        chomp;
		my $sample_name=(split(/\s+/,$_))[0];chomp $sample_name;
        #test sanple 17S0294118
		print "$QC\n";
        print "*******$sample_name\n";
		if ($QC=~/strict/){
			#print "perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $sample_name\n";
			@grep_result = `perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $sample_name`;
		}elsif ($QC=~/loose/){
			#print "perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $sample_name L\n";
			@grep_result = `perl /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/src/samplepath.pl $sample_name L`;
		}
		
        print OUT"$sample_name\tnotfound in system\n" if @grep_result<1 ;
        print "$sample_name\tnotfound in system\n$grep_result[0]" if @grep_result<1 ;
        if ($#grep_result > -1){
			`mkdir -p $opts{target}/$sample_name`;
			if ($opts{filetype}=~/VCF|vcf|Vcf/ ){
				my @outpath=split(/\t/,$grep_result[0]);chomp $outpath[1];
				my @vcf= glob "$outpath[1]/*.vcf*";
				if (-e $vcf[0]){
					`ln -s $vcf[0] $opts{target}/$sample_name/`;
				}else{
					print OUT "+++>$sample_name vcf not exsit\n";
				}
			}
			if ($opts{filetype}=~/excel/ ){
				my @outpath=split(/\t/,$grep_result[0]);chomp $outpath[1];
				my @excel=glob "$outpath[1]/*.xlsx";
				if (-e $excel[0]){
					foreach my $excel (@excel){
						`ln -s $excel $opts{target}/$sample_name/`;
					}
				}else{
					print OUT "+++>$sample_name Tier*.xlsx not exsit\n";
				}
			}
			if ($opts{filetype}=~/Tier1|tier1/){
				my @outpath=split(/\t/,$grep_result[0]);chomp $outpath[1];
				my @tier1=glob "$outpath[1]/*Tier1*.xlsx";
				if (-e $tier1[0]){
					foreach my $tier1 (@tier1){	
						`ln -s $tier1 $opts{target}/$sample_name/`;
					}
				}else{
					print OUT "+++>$sample_name Tier1*.xlsx not exsit\n";
				}
			}
			if ($opts{filetype}=~/bam/){
				my @outpath=split(/\t/,$grep_result[0]);chomp $outpath[0];
				open BAM, ">>$opts{target}/bampath.txt";
				my @bam=glob "$outpath[0]/bwa/*.final.bam";
				if (-e $bam[0]){
					print BAM "$sample_name\t$bam[0]\n";
				}
			}
		}
}
open OUT2, ">$opts{target}/make_md5.sh" or die "cannot output list:$!\n";
print OUT2 "find . -type l |xargs -i md5sum {} > MD5.txt";
#my $size=`du -shL $opts{target}`;
#print "total size is $size\n";
#print OUT "total size is $size\n";
chdir "$opts{target}";
print "zipping files....please wait...\n";
`zip -r $time_string.zip *`;
print "Done!";
#print "zip -r $opts{target}/$time_string.zip $opts{target}/*\n";
#open OUT3, ">$opts{target}/merge.sh" or die "cannot output $opts{target}/merge.sh:$!\n";
#print OUT3 "perl /ifs4/HST_5B/PROJECT/SGD/tyj/data_copy/merge_data_FQ_v3_FQ+VCF.pl -t $opts{target}";
#close OUT3;
