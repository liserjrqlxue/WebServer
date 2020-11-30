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

my $time_string1 = `date "+%Y_%m_%d_%H%M"`;
chomp $time_string1;

our %opts = (
    #'list' => "./list",
    'filetype' => "vcf,Tier1,excel,picture",
    'target' => "/ifs9/B2C_SGD/PROJECT/upload/sample_data_soft_links/$time_string1",
    'QC' =>"strict",
);

GetOptions(\%opts, "list=s", "target:s", "filetype:s", "QC:s" ,"help|h" );
die `pod2text $0` unless $opts{list} ;
die `pos2text $0` if($opts{help});
print "start\n";
print"$opts{target}\n$opts{filetype}\n$opts{QC}\n";

print "target is $opts{target}\n";
mkdir $opts{target} unless -d $opts{target};
open IN1, "<$opts{list}" or die "cannot read $opts{list}:$!\n";
open OUT, ">$opts{target}/found_list.xls" or die "cannot output $opts{target}/found_list.xls:$!\n";
print OUT "sample_name\tsample_library_ID\tRawdata_path\tResult_data_path\n";
my @grep_result;
while (<IN1>) { #each sample
        my $depthtag=();
        chomp;
	my @sample_name=split(/\s+/,$_);
        my $sample_name_in=$sample_name[0];
	my $part1 = substr($sample_name_in, 0,2); my $part2=substr($sample_name_in, 3);
        my $sample_name1= "$part1\.$part2";
        #test sanple 17S0294118
        print "*******$sample_name1";
	#chomp $sample_name1;
        @grep_result = `less /ifs9/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list |awk '{if(\$1~"$sample_name1"){print \$0}}'`;    #<-------------database
	#print $grep_result[0]."\n";
        my ( @sample_name2, @sample_lib_ID,@rawdata_path,@outpath);
        print OUT"$sample_name1\tnotfound in system\n" if @grep_result<1 ;
        print "$sample_name1\tnotfound in system\n" if @grep_result<1 ;
        if ($#grep_result > -1) {
                foreach my $grep_result(@grep_result){
                        print "==grep_result is $grep_result";
                        my $sample_name2=(split /\t/,$grep_result)[0];
                        my $sample_lib_ID=(split /\t/,$grep_result)[2];
                        my $rawdata_path=(split /\t/,$grep_result)[8];
                        my $outpath=(split /\t/,$grep_result)[9];
                        my $product=(split /\t/,$grep_result)[5];
                        my $tail_part=(split /F12FHQHSSJ0877_HUMvoaX/,$rawdata_path)[1];
                        #print "tail part is $tail_part\n";
                        #print OUT "$sample_name2\t$sample_lib_ID\t$rawdata_path\t$outpath\n";
                        #===========================get QC and QC check======================
                        my $coverage;
                        my $depth=();
                        my $q20=0; my $q30=0; my $cov20=0;
                        #print "find  $outpath/total_coverage_depth_stat\n";
                        if (-e "$outpath/total_coverage_depth_stat") {
                                open TOTAL, "<$outpath/total_coverage_depth_stat" or print "cannot open $outpath/total_coverage_depth_stat:$!\n";
                                while (<TOTAL>){
                                        chomp;
                                        next if /Order/;
                                        my $line=$_;
                                        my $t_sample=(split /\t/,$line)[1];
                                        if($t_sample eq $sample_name2){
                                                #print "in totalfile sample is $t_sample\n";
                                                $depth=(split /\t/,$line)[4];
                                                $q20=(split /\t/,$line)[2];
                                                $q30=(split /\t/,$line)[3];
                                                $cov20=(split /\t/,$line)[5] if `head -n 1 $outpath/total_coverage_depth_stat`=~/Deptt\>\=20\(\%\)/;
                                                #print "2 depth is $depth\nq20 is $q20\nq30 is $q30\ncov20 is $cov20\n";
                                        }   
                                }
                        }
                        if(  $cov20==0 ){   
                                #print "in 2\n";
                                if( -e "$outpath/$sample_name2/coverage/coverage.report"){
                                      $coverage="$outpath/$sample_name2/coverage/coverage.report";
                                }
                                open IN2, "<$coverage" or print  OUT "cannot open $coverage:$!\n";
                                while (<IN2>) {
                                        chomp;
                                        if ($_=~/\[Target\] Coverage \(>=20x\)/){
                                            #print "line is ($_)\n";
                                           $cov20=(split /\t/,$_)[1];
                                           $cov20=(split /\%/,$cov20)[0];
                                            #print "1 cov20 is $cov20\n";
                                        }
                                }
                        }
                        if( not defined $depth ){
                                print "$sample_name_in\t$sample_name2\tdepth not check\n";
                                print OUT "$sample_name_in\t$sample_name2\tdepth not check\n";
                                $depthtag="depth_unchecked";
                        }
                        #print "product is $product\n";
                        my $tag=0;
                        if($opts{QC}=~/strict/){
                                if ($product=~/BGI59/){ $tag=1 if ($depth >=100 and $q20>=89 and $q30>=84 and $cov20>=95 );}
                                else{  $tag=1 if ($depth >=100 and $q20>=89 and $q30>=84) ;}
                        }else{
                                if ($product=~/BGI59/){ $tag=1 if ($depth >=79 and $q20>=89 and $q30>=84 ); }
                                else{ $tag=1 if ($depth >=99 and $q30>=80); }    
                        }
                        #print "at last tag is $tag\n";
                        #===========================find files======================

                        if ($tag == 1) {
                                #print "glob $outpath/$sample_name2/*.vcf*\n";
                                my @vcf= glob "$outpath/$sample_name2/*.vcf*";  my $vcf=$vcf[0];
                                #print "vcf is $vcf\n";
                                `mkdir -p $opts{target}/$sample_name2-$product` unless -d "$opts{target}/$sample_name2-$product";
                                if ($opts{filetype}=~/VCF|vcf|Vcf/){
									if ( -e $vcf) {`ln -s $vcf  $opts{target}/$sample_name2-$product/`;}else{ print OUT "+++>$outpath/$sample_name2/*.vcf* not exsit\n";}
								}
                                #============================
                                my @excel=();
                                my @excel1=();
                                my @excel2=();
                                my @tier1=();
                                if ($product=~/BGI59/){
                                        #print "glob $outpath/$sample_name2/$sample_name2.*.xlsx\n";
                                        @excel=glob "$outpath/$sample_name2/$sample_name2.*.xlsx"||glob "$outpath/$sample_name2/$sample_name2\_extract.xlsx";
                                        @tier1=glob "$outpath/$sample_name2/$sample_name2.*out.ACMG.updateFunc.Tier1.*xlsx";
                                        if ($opts{filetype}=~/Tier1|tier1/ and -e $tier1[0]){
                                            foreach my $tier1 (@tier1){
                                                `ln -s $tier1 $opts{target}/$sample_name2-$product`;
                                            }
                                        }
                                        if ($opts{filetype}=~/excel/ and -e $excel[0]){
                                            foreach my $excel (@excel){
                                                `ln -s $excel $opts{target}/$sample_name2-$product`;
                                            }
                                        }#else{
                                        #	print OUT "+++>$outpath/$sample_name2/\texcel not exsit\n";
                                        #}
                                }elsif($product=~/PP600/){
                                       @excel=glob "$outpath/$sample_name2.anno.txt";
                                       if ($opts{filetype}=~/excel/ and -e $excel[0]){`ln -s $excel[0] $opts{target}/$sample_name2-$product`;}else{print OUT "+++>$outpath/$sample_name2/\texcel not exsit\n";}
                                }else{
                                    @excel1=glob "$outpath/result_all_samples/$sample_name2\_*_snp.out\n";
                                    @excel2=glob "$outpath/result_all_samples/$sample_name2\_*_indel.out\n"; 
                                    push @excel, (@excel1,@excel2);
                                    if (@excel and $opts{filetype}=~/excel/ ){
                                            mkdir -p "$opts{target}/$sample_name2-$product" unless -d  "$opts{target}/$sample_name2-$product";
                                            foreach my $excel(@excel){
                                                if (-e $excel){
                                                    `ln -s $excel $opts{target}/$sample_name2-$product`;
                                                   	 my $file= basename $excel;
                                                   	 my $excel_xls="$file\.xls";
                                                   	 chdir "$opts{target}\/$sample_name2-$product";
                                                   	 print "mv $file $excel_xls\n";
                                                    `mv $file $excel_xls`;
                                                }
                                            }
                                    }
                                }
                                #=============================
                                my $exome_picture=();
                                $exome_picture= glob "$outpath/exon_graph_filter/$sample_name2";
                                if ( $opts{filetype}=~/picture/ and -d  $exome_picture) {
                                    mkdir -p "$opts{target}/$sample_name2-$product/exon_graph_filter" unless -d "$opts{target}/$sample_name2-$product/exon_graph_filter";
                                    `ln -s $exome_picture/* $opts{target}/$sample_name2-$product/exon_graph_filter/`;
                                }
                        }else{
                                print OUT "+++>$outpath/$sample_name2/ depth not OK\n";
                        }
                }
        }else{
                print OUT "+++>$sample_name_in\tnotfound\n"; 
        }

 }
open OUT2, ">$opts{target}/make_md5.sh" or die "cannot output list:$!\n";
print OUT2 "find . -type l |xargs -i md5sum {} > MD5.txt";
my $size=`du -shL $opts{target}`;
print "total size is $size\n";
print OUT "total size is $size\n";
chdir "$opts{target}";
print "zipping files....please wait...\n";
`zip -r $time_string1.zip *`;
print "Done!\n";
#print "zip -r $opts{target}/$time_string.zip $opts{target}/*\n";
#open OUT3, ">$opts{target}/merge.sh" or die "cannot output $opts{target}/merge.sh:$!\n";
#print OUT3 "perl /ifs4/HST_5B/PROJECT/SGD/tyj/data_copy/merge_data_FQ_v3_FQ+VCF.pl -t $opts{target}";
#close OUT3;
my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
