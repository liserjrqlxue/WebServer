#!/usr/bin/perl
use warnings;
use strict;
die "usage:perl $0 <sample> <chr> <start> <end> <cn> <outdir>\n",unless @ARGV==6;
my $dir=find_dir($ARGV[0]);
open CNV,">$ARGV[5]/CNV_$ARGV[0]/_$ARGV[1]_$ARGV[2]-$ARGV[3].xls";
print CNV "Sample\tChr\tStart\tEnd\tCopyNum\tDetect\tLen\n";
open GD,"$dir/CNVkit/sample_gender.xls",or die $!;
my %gender;
while (<GD>){
	chomp;
	my @array=split/\s+/,$_;
	$gender{$array[0]}=$array[$#array];
}
close GD;
my %XY;
open XY,"$dir/CNVkit/sample_aneuploid.xls",or die $!;
while (<XY>){
	chomp;
	my @array=split/\s+/,$_;
	$XY{$array[0]}=$array[1];
}
my $det;
if ($ARGV[1] eq "chrX"){
	if ($gender{$ARGV[0]} eq "M"){
		if ($ARGV[4]>1){
			$det="Dup";
		}
		if ($ARGV[4]<1){
			$det="Del";
		}
	}else{
		if ($ARGV[4]>2){
			$det="Dup";
		}
		if ($ARGV[4]<2){
			$det="Del";
		}
	}
}elsif ($ARGV[1] eq "chrY"){
	if ($gender{$ARGV[0]} eq "M"){
		if ($ARGV[4]>1){
			$det="Dup";
		}
		if ($ARGV[4]<1){
			$det="Del";
		}
	}else{
		if ($ARGV[4]>0){
			$det="Dup";
		}
	}
}else{
	if ($ARGV[4]>2){
		$det="Dup";
	}
  if ($ARGV[4]<2){
		$det="Del";
	}
}
my $len=$ARGV[3]-$ARGV[2]+1;
print CNV "$ARGV[0]\t$ARGV[1]\t$ARGV[2]\t$ARGV[3]\t$ARGV[4]\t$det\t$len\n";
close CNV;
print "perl /share/backup/hanrui/pipeline/CNVkit/bin/merge_result_1K_withN.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3].xls /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/20190816_BGISEQ-50017SZ0002016_2017_2018_21/./CNVkit/sample_aneuploid.xls /share/backup/hanrui/pipeline/CNVkit/bin/data/hg19.N_region /share/backup/hanrui/pipeline/CNVkit/bin/data/hg19.cytoBand $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv.xls\n";
`perl /share/backup/hanrui/pipeline/CNVkit/bin/merge_result_1K_withN.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3].xls /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/20190816_BGISEQ-50017SZ0002016_2017_2018_21/./CNVkit/sample_aneuploid.xls /share/backup/hanrui/pipeline/CNVkit/bin/data/hg19.N_region /share/backup/hanrui/pipeline/CNVkit/bin/data/hg19.cytoBand $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv.xls`;
print "perl /share/backup/hanrui/pipeline/CNV_anno/script/add_gene_OMIM.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene.xls\n";
`perl /share/backup/hanrui/pipeline/CNV_anno/script/add_gene_OMIM.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene.xls`;
print "perl /share/backup/hanrui/pipeline/CNV_anno/script/BGI_160.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene.xls $dir/CNVkit/sample_gender.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160.xls\n";
`perl /share/backup/hanrui/pipeline/CNV_anno/script/BGI_160.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene.xls $dir/CNVkit/sample_gender.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160.xls`;
print "perl /share/backup/hanrui/pipeline/CNV_anno/script/CNV_anno_Clinvar_Decipher.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160.xls $dir/CNVkit/sample_gender.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher.xls\n";
`perl /share/backup/hanrui/pipeline/CNV_anno/script/CNV_anno_Clinvar_Decipher.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160.xls $dir/CNVkit/sample_gender.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher.xls`;
print "perl /share/backup/hanrui/pipeline/CNV_anno/script/add_Clinvar_DGV_BGI45W.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher.xls $dir/CNVkit/sample_gender.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV.xls\n";
`perl /share/backup/hanrui/pipeline/CNV_anno/script/add_Clinvar_DGV_BGI45W.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher.xls $dir/CNVkit/sample_gender.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV.xls`;
print "perl perl /share/backup/hanrui/pipeline/CNV_anno/script/add_Pathogenicity.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls\n";
`perl /share/backup/hanrui/pipeline/CNV_anno/script/add_Pathogenicity.pl $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV.xls $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls`;
print "/ifs7/B2C_SGD/PROJECT/PP12_Project/wangyaoshen/go/bin/anno2xlsx -large $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls -list $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_large_CNV\n";
`/ifs7/B2C_SGD/PROJECT/PP12_Project/wangyaoshen/go/bin/anno2xlsx -large $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls -list $ARGV[1] -prefix $ARGV[5]/CNV_$ARGV[0]_$ARGV[1]_$ARGV[2]-$ARGV[3]_large_CNV`;

sub find_dir {
    my $sample_name_in=shift;
    $sample_name_in=(split /\s+/,$sample_name_in)[0];
    chomp $sample_name_in;
    print "sample is ($sample_name_in)\n";
    my @grep_result;
    my $depthtag=();
    my $part1 = substr($sample_name_in, 0,2); my $part2=substr($sample_name_in, 3);
    my $sample_name1= "$part1\.$part2";
    #open OUT2, ">$prefix/sample_QC_info.xls" or die "cannot output info:$!\n";
    @grep_result = `less /ifs9/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list |awk '{if(\$1~"$sample_name1"){print \$0}}'`;    #<-------------database
    my ( @sample_name2, @sample_lib_ID,@rawdata_path,@outpath);
    return "$sample_name_in\tnotfound in system\n" if @grep_result<1 and die;
    if ($#grep_result > -1) {
        foreach my $grep_result(@grep_result){
            my $sample_name2=(split /\t/,$grep_result)[0];
            my $sample_lib_ID=(split /\t/,$grep_result)[2];
            my $outpath=(split /\t/,$grep_result)[9];
            my $product=(split /\t/,$grep_result)[5];
            #===========================get QC and QC check======================
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
            open IN2, "<$coverage_file" or next;
            while (<IN2>) {
                chomp;
                if (($_=~/\[Target\] Average depth\(rmdup\)/) or $_=~/Average sequencing depth of target region/){
                    $depth2=(split /\t/,$_)[1];
                }elsif($_=~/\[Target\] Coverage \(>=20x\)/ or  $_=~/Fraction of target region covered with at least 20X/ ){
                    $x=(split /\t/,$_)[1];
                    if($x=~/;/){$x=(split /;/,$x)[1];}
                    $x=(split /\%/,$x)[0];
                }elsif($_=~/\[Target\] Coverage \(>0x\)/ or $_=~/Coverage of target region/ ){
                    $Coverage=(split /\t/,$_)[1] if not defined $Coverage;
                }elsif($_=~/Data mapped to target region \(Mb\)/ or $_=~/\[Target\] Fraction of Target Data in all data/){
                    $CaptureEffiency=(split /\t/,$_)[1] if not defined $CaptureEffiency;
                    if($CaptureEffiency=~/;/){$CaptureEffiency=(split /;/,$CaptureEffiency)[1];}
                }
            }
            if ($product=~/BGI59/ and $outpath=~/BGISEQ/ or $outpath=~/Zebra/ or  $outpath=~/MGISEQ-2000/) {
                $tag=1 if ($depth >=100 or $depth2>=100) and $x>=95 and $q30>85;
            }else{
                $tag=1 if ($depth >=100 or $depth2>=100) and $q30>85;
            }
            if ($tag==1 ) {
                return "$outpath";
            }else{
                return "$sample_name_in\tdepth not ok\n" if $tag==0 and die;
            }
        }
    }
}

my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`

