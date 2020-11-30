#!/usr/bin/perl -w
use strict;
use File::Basename;
use Cwd;
#use Data::Dumper;
my $ge=shift;
my $dir=shift;
my $corrent_dir=getcwd();
my $sample=basename(dirname(dirname($dir)));
my @gene=split /\,/,$ge;
my $nm;
#open BB,">$sample\_exon_avedep.info";
my %hhh;my %hash;my %cov;
foreach my $gene(@gene){
#    $hash{$gene}{"1"}=0;
#    $cov{$gene}{"1"}=0;
    #open AA,"/ifs4/B2C_NIFTY/USER/quning/data/refgene/onlyNMfor_eachGene.refgene";
    open AA,"/ifs9/BC_B2C_01A/B2C_SGD/quning/data/refgene/onlyNMfor_eachGene.refgene";
    $/="\n\n";
    while (<AA>){
        chomp;
        my @sa=split /\n/;
        my @line=split /\t/,$sa[0];  #NM_015120       chr2    +       73612886        73837046        73612997        73836739        23      ALMS1   cmpl    cmpl    NP_055935
    #   print "$line[8]\n"; is gene
        if ($line[8] eq "$gene"){
            print "well\n";
            $nm=$line[0]; #20180413
            print "nm is $line[0]\n";
            my $gene_nm="$line[8].$line[0]";  #20180417
	    $hash{$gene_nm}{"1"}=0;  #20180418
	    $cov{$gene_nm}{"1"}=0;   #20180418
            for(my $i=1;$i<=$#sa;$i++){ #每一行遍历
                my @sc=split /\t/,$sa[$i]; #sc 是每一行拆分的 sa是每一行
                if ($sa[$i]=~/5-UTR/i && $sa[$i+1]=~/intron/){ #这一行是UTR 下一行是intron
                        my @ss=split /\t/,$sa[$i];
                        my @sss=split /\t/,$sa[$i+1];
                        if ($line[2] eq "+"){   #正链基因
                            $ss[1]=$ss[1]-150;  #前后扩充150bp
                            $sss[2]=$sss[2]+150;
                            @{$hhh{$gene_nm}{"$ss[4]"}}=($line[1],$ss[1],$sss[2]);  #  %hhh{gene}{exome}=@(chr，上限，下限)
                        }
                        if ($line[2] eq "-"){  #负链基因
                            $sss[1]=$sss[1]-150;  #前后扩充150bp
                            $ss[2]=$ss[2]+150;
                            @{$hhh{$gene_nm}{"$ss[4]"}}=($line[1],$sss[1],$ss[2]);   #  %hhh{gene}{exome}=@(chr，上限，下限)
                        }
                        next;

                }
                if ($sc[0]=~/intron/i){next;} #
                if ($sa[$i]=~/5-UTR/i && $sa[$i+1]=~/CDS/){ #这一行是UTR 下一行是CDS
                        my @ss=split /\t/,$sa[$i];
                        my @sss=split /\t/,$sa[$i+1];
                        if ($line[2] eq "+"){   #正链基因
                            $ss[1]=$ss[1]-150;  #前后扩充150bp
                            $sss[2]=$sss[2]+150;
                            @{$hhh{$gene_nm}{"$ss[4]"}}=($line[1],$ss[1],$sss[2]);  #  %hhh{gene}{exome}=@(chr，上限，下限)
                        }
                        if ($line[2] eq "-"){  #负链基因
                            $sss[1]=$sss[1]-150;  #前后扩充150bp
                            $ss[2]=$ss[2]+150;
                            @{$hhh{$gene_nm}{"$ss[4]"}}=($line[1],$sss[1],$ss[2]);   #  %hhh{gene}{exome}=@(chr，上限，下限)
                        }
                        next; 
                }
                if ($sa[$i-1]=~/5-UTR/i && $sa[$i]=~/CDS/){  #上一个是UTR这一行是CDS就next，防止再算一次
                        next;
                }
                $sc[1]=$sc[1]-150;  #在每一行遍历中，上限-150下限+150
                $sc[2]=$sc[2]+150;  
                if ($sa[$i ]=~/CDS/i){  # sa是每一行i是行数 如果这一行匹配到cds
                        @{$hhh{$gene_nm}{"$sc[4]"}}=($line[1],$sc[1],$sc[2]);   # %hhh{gene}{exome}=@(chr, 上限，下限)
                }
            }
        }
    }
    close AA;
}
$/="\n";
my %depth;
open CC,"gzip -cd  $dir |";
while (<CC>){
    chomp;
    next if /Pos/;
    my @arr=split /\t/;
    $depth{$arr[0]}{"$arr[1]"}=$arr[3];  # %depth{chr}{pos}=Rmdup_depth
#   print "$arr[0]\t$arr[1]\t$arr[0]\n";
}
close CC;
#print Dumper \%depth;

foreach my $gg(keys %hhh){  #gene
    foreach my $ee(sort{$a<=>$b} keys %{$hhh{$gg}}){  #exome
        print "exome is $ee\n";
        my $diff=${$hhh{$gg}{$ee}}[2]-${$hhh{$gg}{$ee}}[1]-299;  #算出范围
        my ($cnt,$all)=(0,0);       
        for my $chr(keys %depth){
            for my $pos(keys %{$depth{$chr}}){
                if (${$hhh{$gg}{$ee}}[0] eq "$chr" && $pos>=${$hhh{$gg}{$ee}}[1]+150 && $pos<=${$hhh{$gg}{$ee}}[2]-150){
#                   print "$chr\t$chr\t${$hhh{$gg}{$ee}}[0]\t${$hhh{$gg}{$ee}}[2]\n";
                    $all+=$depth{$chr}{$pos};   #范围内总深度
                    $cnt++;  #cnt是落在范围内的碱基计数
                }
            }
        }
        my $ave=sprintf "%.2f",$all/$diff;   #平均深度
        my $cco=sprintf "%.2f",$cnt/$diff;   #1x覆盖度
        $cco=$cco*100;
        $hash{$gg}{$ee}=$ave;
        $cov{$gg}{$ee}=$cco;
#       print "$cnt\t$diff\n";
    }
}
open BB,">$sample.$nm\_exon_avedep.info";
foreach my $ggg(keys %hash){
    foreach my $eee(sort{$a<=>$b} keys %{$hash{$ggg}}){
        print BB "$ggg\tEX$eee\t$hash{$ggg}{$eee}\t$hash{$ggg}{$eee}\t$cov{$ggg}{$eee}\n";
    }
}
close BB;
#`perl /ifs4/B2C_NIFTY/USER/quning/sgd/bin/exon_graph_shiquan.pl $sample\_exon_avedep.info /ifs7/B2C_SGD/USER/yangqian/script/search_CNV/exon/exon_graph_gene  $sample`;
#print "perl /ifs4/B2C_NIFTY/USER/quning/sgd/bin/exon_graph_shiquan.pl $sample.$nm\_exon_avedep.info $corrent_dir  $sample.$nm\n";
#`perl /ifs4/B2C_NIFTY/USER/quning/sgd/bin/exon_graph_shiquan.pl $sample.$nm\_exon_avedep.info $corrent_dir  $sample.$nm`;
`perl /ifs9/BC_B2C_01A/B2C_SGD/quning/sgd/bin/exon_graph_shiquan.pl $sample.$nm\_exon_avedep.info $corrent_dir  $sample.$nm`;
#print "reault out out at /ifs7/B2C_SGD/USER/yangqian/script/search_CNV/exon/exon_graph_gene \n";

my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
