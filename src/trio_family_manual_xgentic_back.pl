#!/usr/bin/perl -w
use strict;
#yujingtang@genomcs.cn
use File::Basename;
use Cwd;
my $list=shift;
my $here = shift or die$!;
my $qc=shift || "90,85,100,95";
my $is_trio=shift || "null";

`dos2unix $list`;
open IN, "<$list" or die "cannot open list:$!\n";
open JOB_LOG, ">$here/job.log" or die "cannot oputput list:$!\n";
my %family=();
my %family_out=();
my %family_out_gender_seq=();
my %bed_coverage=();
my %sample_count=();
my %gender=();
my %pid=();

$/="\n\n";
while (<IN>){  # each \n\n
	chomp;
	my @sample=split /\n/;
	@{$family{$sample[0]}}=@sample;  #in %family proband store will have repeat, like proband proband A B C ...
}
$/="\n";

foreach my $proband1(sort keys %family){	#in %family proband store will have repeat, like proband proband A B C ...
	print "====== dealing proband  $proband1 ======\n";
	for my $i(0..$#{$family{$proband1}}){ #family members
		my $sample=$family{$proband1}[$i];
		$sample =~ s/^\s+|\s+$//g;
		my $part1 = substr($sample, 0,2); my $part2=substr($sample, 3);
		my $sample_name1= "$part1\.$part2";
		#my @grep_result = `less /ifs7/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list |awk '{if(\$1~"$sample_name1"){print \$0}}'`;	#<-------------database
		my @grep_result = `less /ifs9/B2C_SGD/PROJECT/monitor/sampleInfoData/sample_list|awk '{if(\$1~"$sample_name1"){print \$0}}'`;	#<-------------database
		if ($#grep_result > -1) {
			foreach my $grep_result(@grep_result){
				my $outpath=(split /\t/,$grep_result)[9];
				$sample=(split /\t/,$grep_result)[0];
				print "found sampel $sample\n";
				if($outpath=~/exome/ ){
					my $bed="$outpath/$sample/annotation/$sample.bed.gz";
					my $coverage="$outpath/$sample/coverage/coverage.report"; #print "sample is $sample test coverage is $outpath/$sample/coverage/coverage.report\n";
					my $gender_txt="$outpath/$sample/coverage/gender.txt";
					my $name_hash="$outpath/name.hash";
					my $total="$outpath/total_coverage_depth_stat";
					#print "before=== family{$sample}[0] is $family{$sample}[0]\n";
					if(-e $total){
						my @line=`less $total |grep $sample`;
						my @p=(split /\t/,$line[0]);
						my $q20=$p[2]; my $q30=$p[3]; my $depth=$p[4]; my $cov_20=$p[5]; my $gender=$p[15];
						my @qc=split(/,/,$qc);
						if ($q20>=$qc[0] and  $q30>=$qc[1] and $depth>=$qc[2] and $cov_20>=$qc[3] ){
							#if ($q20>=89 and  $q30>=84 and $depth>=79 and $cov_20>=95 ){
							print "$sample\tq20: $q20 q30: $q30 depth: $depth 20x cov: $cov_20 gender: $gender\tfamily: $proband1 push sample: $family{$proband1}[$i]\n";
							push @{$family_out{$proband1}},($sample);  # $family_out{proband} include (proband A B C)
							#push @{$family_out{$proband1}},($sample) and print "$sample ne $family{$proband1}[0]\n" if  $sample ne $family{$proband1}[0]; #becaeue %family proband store will have repeat, like proband proband A B C ... 
							$bed_coverage{$sample}="$bed\t$coverage";	 #proband and samples are stored # the first sample is proband
							open GENDER, "<$gender_txt" or die "cannot open gender.txt:$!\n";
							while (<GENDER>) {
								   		$_=~/Female/ and $gender{$sample}="F";
										$_=~/Male/ and $gender{$sample}="M";
							}   
							my $pid=`less $name_hash |grep $sample |awk '{print \$4}'`;	 #  add product ID DX....
							chomp ($pid);
							$pid{$sample}=$pid;	
						}else{
							print "$sample\tq20: $q20 q30: $q30 depth: $depth 20x cov: $cov_20 gender: $gender QC NOT OK\n";
						}
					}else{ 
						print "$total not exsist!\n";
					}
				}
			}
		}else{
			print "$sample\tnotfound in system\n"
		}
	}
}
$/="\n";

#-------make family_out order follow gender sequence:proband-father-mother. only work for 3 samples.
foreach my $proband (sort keys %family_out){ #%family_out include proband and have no proband repeat
	my @final_order=();
	my @male=();
	my @female=();
	my @null=();
	#if ($#{$family_out{$proband}}<=2) { #if family have 3 people
	if ($#{$family_out{$proband}}<=2 and $is_trio=~/trio/ ) { #if family have 3 people  #20190619 15:03
		for my $i(1..$#{$family_out{$proband}}){
			print "i is $family_out{$proband}[$i]\n";
			if ($gender{$family_out{$proband}[$i]} eq "M"){push @male, ($family_out{$proband}[$i]);}
			elsif($gender{$family_out{$proband}[$i]} eq "F"){push @female, ($family_out{$proband}[$i]);}
			elsif($gender{$family_out{$proband}[$i]} eq "null" or $gender{$family_out{$proband}[$i]} eq ""){push @null, ($family_out{$proband}[$i]);}
		}
		push @final_order,($family_out{$proband}[0]);
		push @final_order,($male[0]) if scalar @male>= 1;
		push @final_order,($female[0]) if scalar @female>= 1;
		push @final_order,($male[0..$#male]) if scalar @male> 1;
		push @final_order,($female[0..$#female]) if scalar @female> 1;
		push @final_order,(@null) if scalar @null>= 1;
		print "family fellow order is @final_order\n";
		push @{$family_out_gender_seq{$proband}},@final_order;
	}else{
		#print " =============> @{$family_out{$proband}}\n";
		push @{$family_out_gender_seq{$proband}},@{$family_out{$proband}};
	}
}
#----------------------------prepare output
foreach my $proband (sort keys %family_out_gender_seq){
	my @order=();
	my @print_bed=();
	my @print_coverage=();
	my @print_gender;
	#push @order, ($proband);
	for my $i(0..$#{$family_out_gender_seq{$proband}}){
		push @order, ( $family_out_gender_seq{$proband}[$i]) ;
	}
	print "mkdir $here/$order[0]\n";
	`mkdir $here/$order[0]`;
	foreach my $ordered_sample (@order){
		   # print "bed_coverage{$ordered_sample} is $bed_coverage{$ordered_sample}\n";
			print "ordered_sample is $ordered_sample\n";
			push @print_bed, (split /\t/,$bed_coverage{$ordered_sample})[0];
			push @print_coverage, (split /\t/,$bed_coverage{$ordered_sample})[1];
		push @print_gender,$gender{$ordered_sample};
	}	

	my (%exonCnv,%largeCnv,%smn);
	for my $bed(@print_bed){
		my $wd=dirname(dirname(dirname($bed)));
		my $sample=basename(dirname(dirname($bed)));
		if(-e "$wd/ExomeDepth/$sample/all.CNV.calls.anno"){
			$exonCnv{"$wd/ExomeDepth/$sample/all.CNV.calls.anno"}++;
		}elsif(-e "$wd/ExomeDepth/all.CNV.calls.anno"){
			$exonCnv{"$wd/ExomeDepth/all.CNV.calls.anno"}++;
		}
		if(-e "$wd/CNVkit/$sample/CNVkit_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls"){
			$largeCnv{"$wd/CNVkit/$sample/CNVkit_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls"}++;
		}elsif(-e "$wd/CNVkit/CNVkit_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls"){
			$largeCnv{"$wd/CNVkit/CNVkit_cnv_gene_BGI160_Decipher_DGV_Pathogenicity.xls"}++;
		}
		if(-e"$wd/SMA/$sample/SMA_v2.txt"){
			$smn{"$wd/SMA/$sample/SMA_v2.txt"}++;
		}elsif(-e "$wd/SMA/SMA_v2.txt"){
			$smn{"$wd/SMA/SMA_v2.txt"}++;
		}
	}
	my  @print_bed_new= &get_new_bed(\@print_bed);	

	my $tmp= join ( "\\n",@order);
	#open RUN,  ">$here/$proband/run.new.sh" or die "cannot output $here/$proband/run.new.sh\n";
	open RUN,  ">$here/$order[0]/run.new.sh" or die "cannot output $here/$order[0]/run.new.sh\n";
	print RUN  
	"#!/bin/bash\n",
	"prefix=$order[0].bed.gz.family.all.tsv\n",
	"prefix2=$order[0].out.family.all.tsv\n",
	"export Redis_HOST=10.2.1.4\n",
	"export ClinDis_HOST=10.2.1.4\n",
	"export PATH=/ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/HPC_chip/tools:\$PATH\n",
	"export BGICGA_HOME=/ifs9/BC_B2C_01A/B2C_SGD/Newborn/analysis_pipeline/BGICG_Annotation\n",
	"perl=/share/backup/wangyaoshen/perl5/perlbrew/perls/perl-5.26.2/bin/perl\n",
	"excelReport=/ifs9/BC_B2C_01A/B2C_SGD/yangqian/sgd/bin/bgi_seq500_flow/exome/wangyaoshen/excel_report/bin/excel_report.EXOME.pl\n",
	"acmg=/ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/xgentic_Annotation/acmg2015/bin/anno.acmg.pl\n",
	"func=/ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/xgentic_Annotation/update.Function.pl\n",
	"anno2xlsx=/ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/xgentic_Annotation/anno2xlsx/anno2xlsx\n",

	"echo -e '$tmp' > fam.info\n",
	#"echo family.plus\n",
	#"time perl /home/sgd_pub/exome/wangyaoshen/Family_anno/bin/family.plus.all.pl ",join (" ",@print_bed),"\n\n",
	"echo family.plus.new.anno\n",
	"time perl /home/sgd_pub/exome/wangyaoshen/Family_anno/bin/family.plus.all.pl ",join (" ",@print_bed_new),"\n";	

=head
	"echo excel report\n",
	"time \$perl /ifs9/BC_B2C_01A/B2C_SGD/yangqian/sgd/bin/bgi_seq500_flow/exome/wangyaoshen/excel_report/bin/excel_report.EXOME.new.pl",
		" -v \$prefix",
		" -o $order[0].bed.gz.family.xlsx",
		" -redis -sims -native",
		" -fam fam.info",
		" -q ",join (",", @print_coverage),
		" -t seq500 -simple",
		" -g $gender{$order[0]}",
		" -famGender ",join (",", @print_gender),
		" -pid $pid{$order[0]}",
	"\n\n";
=cut	

	my $MaxEntScan=0;
	if($MaxEntScan){
	print RUN  "echo MaxEntScan\n",
	"python=/share/backup/wangyaoshen/src/github.com/pyenv/pyenv/shims/python\n",
	"bindir=/ifs7/B2C_SGD/PROJECT/PP12_Project/ExomeDepth/workspace/MaxEntScan/12.MaxEntScan_pipeline\n",
	"extract=\$bindir/extract_info.py\n",
	"MaxEnt=\$bindir/MaxEntHGMD_v1.2.py\n",
	"match=\$bindir/match_stat.py\n",
	"outdir=\$(dirname \$prefix)\n",
	"\$python \$extract -i \$prefix -o \$outdir\n",
	"\$python \$MaxEnt -v \$prefix.info -s \$prefix\n",
	"rm -v \$prefix.{New_*,Post_*,Pre_*,mut_info.txt,Real_*,SS3_*,SS5_*}\n",
	"\$python \$match -i \$prefix.MaxEntRes.txt -u \$prefix -o \$outdir\n",
	"prefix=\$prefix.MaxEntRes_result\n";
	 }	

	print RUN
	"echo ACMG 2015\n",
	"time perl \$acmg  \$prefix2 > \$prefix2.ACMG\n\n",
	"echo update Function splice+-20\n",
	"time perl \$func \$prefix2.ACMG > \$prefix2.ACMG.updateFunc\n\n",
	"echo output excel\n",
	"\$anno2xlsx\\\n";
	print RUN " -trio\\\n" if ($is_trio=~/trio/);
	print RUN " -couple\\\n" if ($is_trio=~/couple/);
	print RUN
		" -acmg\\\n",
		" -snv \$prefix2.ACMG.updateFunc\\\n",
		" -list ",join(",",@order),"\\\n",
		" -qc ",join(",",@print_coverage),"\\\n",
		" -gender  ",join (",", @print_gender),"\\\n",
		" -specVarList /ifs7/B2C_SGD/PROJECT/PP12_Project/analysis_pipeline/xgentic_Annotation/anno2xlsx/db/spec.var.lite.list\\\n",
		" -redis -redisAddr 10.2.1.4:6380\\\n",
		" -exon ",join(",",keys%exonCnv),"\\\n",
		" -large ",join(",",keys%largeCnv),"\\\n",
		" -smn ",join(",",keys%smn),"\n",
	"\n";	
	

	chdir "$here/$order[0]";
	my $qsub=&get_job_id(`qsub -cwd -l vf=8g,num_proc=1 -P B2C_SGD run.new.sh`);
	print JOB_LOG "$qsub\t$here/$order[0]\n";
	@order=();
	@print_coverage=();
	@print_bed=();
	%exonCnv=();
	%largeCnv=();
	%smn=()
}
close JOB_LOG;

sub get_workdir {
		my $print_bed=shift;
		my @print_bed = @$print_bed;
		my @sample;
		foreach my $bed (@print_bed) {
				my $sample=dirname(dirname(dirname($bed)));
				push @sample, ($sample);
		}
		return @sample;
}

sub get_new_bed{
		my $old_bed=shift;
		my @new_bed="";
		my @old_bed = @$old_bed;
		foreach my $old_bed(@old_bed){
				my $dir=dirname($old_bed);
				my $sample=basename(dirname(dirname($old_bed)));
				my $new_bed="$dir/$sample.out";
				push @new_bed, ($new_bed);
		}
		return @new_bed;
}

sub get_job_id{
	my $back = shift @_; 
	my $job_id;
	if(defined $back && $back =~ /^Your job (\d+) \(\"(.*?)\"\) has been submitted$/){
		$job_id = $1; 
	}   
	else{
	}   
	return $job_id;
}


my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
