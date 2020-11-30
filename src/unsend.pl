#!/usr/bin/perl -w
use strict;
use File::Basename;
my @dir=("/ifs7/B2C_SGD/PROJECT/BGISEQ-500_Project/exome_diagnose/","/ifs7/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/","/ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/","/ifs9/B2C_SGD/PROJECT/BGISEQ-500_Project/exome_diagnose/");
chdir("public/unsend/");
print `ls -1 -F |grep \\@ |tr '@\\n' ' ' |xargs rm  \$_`;
foreach my $dir (@dir){
our @issue_dir = glob "$dir/*/";
my $tag=0;
foreach my $issue_dir (@issue_dir){
    next if $issue_dir=~/exom_CNV|trio_family|wys|result|gene_annotations_build|CNV_anno|exome_cnv|failed_issues|get|HeXing|SMA_control|Tier1|tools|temp|Tirt1/;
    my @filestat = stat("$issue_dir/mail_result.txt");
    if (-s "$issue_dir/mail_result.txt"){
        next;        #print "$issue_dir/mail_result.txt exisit and >0\n"; 
    }elsif(-e "$issue_dir/name.hash"){
        print  "\n================== $issue_dir not send yet\n";
        print `ln -s $issue_dir .`;
    }
}
}
