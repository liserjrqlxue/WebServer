#!/vol6/home/bgi_thmed/bin/perl -w

# Author: SHI Quan
# Note: this program is plot the reads covered target position. Please report bugs to me.
# use blank instead of deletion, gray char for soft linked position. '*' for padding.

use strict;
use warnings;
use Getopt::Long;
use Faidx;

my $version = '0.1.5';
##======================================================================================
my (
    $bam,       $chr,    $pos,    $rmdup,    $filter,   $repeat,
    $reference, $length, $screen, $anno,     $samtools, $refdir, 
    $Rs,	$prefix, $debug,  $readgroup, $RGlist,  $showbase, $title
  )
  = (
    0, 0, 0, 0, 0, 0, 0, 100, 0, 0, "/ifs9/BC_B2C_01A/B2C_SGD/quning/bin/samtools-0.1.19/samtools",
    "/ifs9/B2C_COM_P2/pub/sgd/Pipeline/analysis_pipeline/src/db/hg19/hg19_chM.fa.rz",
    "Rscript", "./", 0, "", "", 0,""
  );
my $result = GetOptions(
    "-b:s"      => \$bam,
    "-c:s"      => \$chr,
    "-p:s"      => \$pos,
    "-l:i"      => \$length,
    "-t:s"      => \$samtools,
    "-rg:s"	=> \$readgroup,
    "-Rgf:s"	=> \$RGlist,
    "-Rs:s"	=> \$Rs,
    "-refdir:s" => \$refdir,
    "-prefix:s" => \$prefix,
		"-title:s"=>\$title,
    "-showbase" => sub { $showbase = 'TURE' },
    "-a"	=> sub { $anno = 'TURE'},
    "-f"        => \$filter, #sub { $filter = 'TRUE' },
    "-d"        => sub { $rmdup = 'TRUE' },
    "-r"        => sub { $reference = 'TRUE' },
    "-s"        => sub { $screen = 5 },
    "-debug"    => sub { $debug = 1 }
);
##=====================================================================================
my $usage   = <<"USAGE";

################################## plotreads######################################
										   
   USAGE:  plotreads.pl <-b BAM> <-c chrtag> <-p posstr> [OPTIONS]
   Version: $version
										   
	    [essential parameters]						   
	    	-b      [FILE]	the sorted bam file <BAM>				   
		-c      [STR]	reference sequence name, the chromosome	<chr>		   
		-p      [STR]	the  position in the chromesome  <position>		   
		    		123456	    :mark the snp position at 123456		   
		    		123456in123457  :mark the insertion between 123456 and 123457  
		    		123456to123457  :mark the position from 123456 to 123457	   
										   
	    [optional parameters]						   
		-rg	[STR]	The read group you want to draw
		-Rgf	[FILE]  Read group list for multiple read group per sample.
		-t      [FILE]	samtools to be used, version >= 0.1.16 [$samtools]
		-Rs     [FILE]	Rscript to be used [$Rs]
		-l      [NUM]	the length of a read. defalut is $length(bp) <length of read>   
		-refdir [FILE]	hg19 reference fasta file path [$refdir]
		-prefix [STR]	string to add to the start of output graph. [$prefix]
		-showbase	arbitrarily show bases whenever -r is available or not.
		-f	[NUM]	only show reads which mapping quality > NUM (default is unremoved)
		-d		remove duplication reads, cigar level dups (default is unremoved)
		-r		with reference (default is no reference)
		-a		with count the number of duplicate reads, depend on -d option specified, default no plot.
		-s		screen the first 5bp and last 5bp
		-debug  	Intermedia files will be kept.
   ==========================================================================     
               Please Report BUGs to Me!!!					   
   ==========================================================================	   
   HISTORY:									   
	version:0.0.1	March,12nd 2012	    SHI Quan(shiquan\@genomics.cn)	   
	version:0.0.2	May, 4th 2012	    SHI Quan			   
	version:0.0.3	March,15th 2013	    Liu Tao (liutao\@genomics.cn)
	version:0.0.4	April,8th 2013	    Liu Tao
	version:0.0.5	April,10th 2013	    Liu Tao
	version:0.1.0	May,3rd 2013	    Liu Tao
	version:0.1.1	May,14th 2013	    Liu Tao
	version:0.1.2	Sep,6th 2013	    Liu Tao
	version:0.1.3	Oct,28th 2013	    Liu Tao
	version:0.1.4   May,16th 2014	    Liu Tao (change to R3.0 and support RGlist)
        version:0.1.5   January, 6th 2015   Shi Quan (update ggplot2 code, remove -u option)
 
####################################################################################

USAGE

die $usage unless ( $bam && $chr && $pos );
my $pot = 0;
$prefix .= "_" if ($prefix !~ /[\/_]$/);
#my $title = $prefix;
#$title =~ s/^.*\///;
#$title =~ s/_$/::/;
my $pic;
my $hg19_fai;
if ($reference) {
    $hg19_fai = Faidx->new($refdir) or die "Error: can not get hg19 reference handle\n";
}

##=====================================================================================
my ( $start, $end )  = ( 0, 0 );
my ( $pos1,  $pos2 ) = ( 0, 0 );

if ( $pos =~ /^(\d+)$/ ) {
    $pot   = $pos;
    $start = $1 - $length + 1;
    $end   = $1;
    $pos1  = $pos2 = $pos;
    $pic   = "$chr" . "_$pos";
}
elsif ( $pos =~ /^(\d+)in(\d+)$/ ) {
    $pot   = $1 + 1;
    $start = $1 - $length + 1;
    $end   = $1;
    $pos1  = $1;
    $pos2  = $2;
    $pic   = "$chr" . "_$1in$2";
}
elsif ( $pos =~ /^(\d+)to(\d+)$/ ) {
    $pot   = $1;
    $start = $1 - $length + 1;
    $end   = $2;
    $pos1  = $1;
    $pos2  = $2;
    $pic   = "$chr" . "_$1to$2";
}
$start += $screen;
$end -= $screen;
##======================================================================
my %pos;
my %insert; # {row}{pos}
my %clip;   # {row}{pos}
my %mmap;   # {row}
my %ins;    # {pos}
my %xtam;   # {row}
my %strand;
my %uniq;
my %alias;
my $depth = 0;
my %header_reset = ();

$prefix .= $pic;
my $optsamview = ($filter>20) ? '-q 1 ' : ''; # using filter options in samtools view to filter reads directly.
$optsamview .= (($readgroup eq "") ? (( $RGlist eq "" ) ? "" : "-R $RGlist " ) : "-r $readgroup ");
$optsamview .= "-F 256";
my $alter_bai = $bam;
$alter_bai =~ s/\.bam$/.bai/;
if ((  -f $bam.".bai" and -r $bam.".bai" ) or ( -f $alter_bai and -r $alter_bai )) {
	print "$samtools view $optsamview $bam $chr:$pos1-$pos2 |\n";
    open BAM, "$samtools view $optsamview $bam $chr:$pos1-$pos2 |" or die;
}
else {
    open BAM, "echo -e \"$chr\t".($pos1-1)."\t$pos2\" | $samtools view $optsamview -L - $bam |" or die;
}

BAM: while (<BAM>) {
    chomp;
    my @linetmp = split(/\t/);
    my ( $flag, $rname, $pos, $mq, $cigar, $seq, @extras ) = @linetmp[1 .. 5,9,11 .. $#linetmp];

    my $uniopt = 1;
    my $xtamopt = 0;
    my $unipair_opt = 1;
    foreach my $m (@extras) {
	if ($m eq "XT:A:M") {
	    $xtamopt = 1;
	}
	elsif ($m eq "MQ:i:0") {
	    $unipair_opt = 0;
	}
    }
    #next BAM if $filter and $mq < $filter;
    #$uniopt = 0 if ($mq == 0 and $unipair_opt == 0);
    #next BAM if ($repeat and $uniopt == 0);

    my $strnd = ($flag & 0x10) ? "-" : "+";
    if ($rmdup) {
        if (    exists $uniq{$rname}
            and exists $uniq{$rname}{$pos}
            and exists $uniq{$rname}{$pos}{$cigar}
            and exists $uniq{$rname}{$pos}{$cigar}{$strnd} )
        {
            $uniq{$rname}{$pos}{$cigar}{$strnd}++;
            next BAM;
        }
        else {
            $uniq{$rname}{$pos}{$cigar}{$strnd} = 1;
        }
    }

    $depth++;
    $alias{$depth}{$pos} = join("\t", $rname, $cigar);

    $mmap{$depth} = 1 if ($uniopt == 0);
    $xtam{$depth} = 1 if ($xtamopt == 1);
    $strand{$depth} = $strnd;
    my $tmp      = 0;
    my $header   = $pos;
    my $oripos   = $header;
    my @sequence = split //, $seq;
    my @num      = split /\D/, $cigar;
    my @mat      = split /\d+/, $cigar;
    shift @mat;
    my @line = ();


    for my $i ( 0 .. $#num ) {
        if ( $mat[$i] =~ /M/ ) {
            for ( 1 .. $num[$i] ) {
                my $x = shift @sequence;
                push @line, $x;
            }
            $pos += $num[$i];
        }
        elsif ( $mat[$i] =~ /I/ ) {
	    $pos --;
            foreach my $j ( 1 .. $num[$i] ) {
                my $x = shift @sequence;
                $insert{$depth}{$pos} .= $x;
            }
	    $ins{$pos} = ( exists $ins{$pos} && ($ins{$pos} > $num[$i]) ) ? $ins{$pos} : $num[$i];
	    $pos ++;
        }
	elsif ( $mat[$i] =~ /S/ ) {
	    if ($i == 0) {
		for(my $offset = $num[$i]; $offset > 0; $offset--) {
		    my $x = shift @sequence;
		    push @line, $x;
		    $clip{$depth}{($pos-$offset)} = 1;
		}
		$header -= $num[$i];
	    }
	    elsif ($i == $#num ) {
		foreach my $j ( 1 .. $num[$i] ) {
		    my $x = shift @sequence;
		    push @line, $x;
		    $clip{$depth}{($pos + $j)} = 1;
		}
	    }
	    else {
		die "Error: inner clip found [$rname:$oripos,$cigar]\nPlease report this to liutao\@genomics.cn.\n";
	    }
	}
	elsif ( $mat[$i] =~ /H/ ) {
	    if ($i == 0 or $i == $#num) {
		# do nothing
	    }
	    else {
		die "Error: inner clip found [$rname:$oripos,$cigar]\nPlease report this to liutao\@genomics.cn.\n";
	    }
	}
        else {
            for ( 1 .. $num[$i] ) {
                my $x = '-';
                push @line, $x;
            }
	    $pos += $num[$i];
        }
    }
    $pos{$depth}{$header} = \@line;
    $header_reset{$depth}{$header} = $oripos;
}
close BAM;

##===========================================================================
die "No reads remained after filterring for $bam [$chr:$pos].\n" if (0 == $depth);

$depth = $depth + 2;

##=========================== Reference =====================================
my %ref;
if ($reference) {
    $chr = 'chr'.$chr if ($chr !~ /^chr/);
    my $start_ref  = $pot - $length - 5;
    my $length_ref = $end - $pot + $length * 2 + 10;
    my $stop_ref = $start_ref + $length_ref - 1;
    my $refseq   = uc($hg19_fai->getseq($chr.':'.$start_ref.'-'.$stop_ref));
    foreach my $i_ref (sort {$b <=> $a} keys %ins) {
	my $ref_pos = $i_ref - $start_ref + 1;
	substr($refseq, $ref_pos, 0, ("*" x $ins{$i_ref}));
    }
    my @refseq = split //, $refseq;
    my $ind = $start_ref;
    foreach my $x_ref (@refseq) {
	$ref{$ind} = $x_ref;
	$ind ++;
    }
}

$hg19_fai->destroy() if (defined $hg19_fai and $hg19_fai->can('destroy'));
##===========================================================================

my %dupanno = ();
foreach my $depth_sort ( sort { $a <=> $b } keys %pos ) {
    my @clipbases = sort {$b<=>$a} keys %{$clip{$depth_sort}};
    foreach my $clipbase ( @clipbases ) {
	my $plot_clip = $clipbase + get_cumulate_ins(\%ins, $clipbase);
	delete $clip{$depth_sort}{$clipbase};
	$clip{$depth_sort}{$plot_clip} = 1;
    }
    foreach my $head_sort ( keys %{ $pos{$depth_sort} } ) {
        my @temp = @{$pos{$depth_sort}{$head_sort}};
	my $plot_head = $head_sort + get_cumulate_ins(\%ins, $head_sort);

	my $ref_rd_len = scalar @temp;
	my @line_sort = ();
        for my $i_sort ( $head_sort .. ($head_sort + $ref_rd_len - 1) ) {
	    my $x_sort = shift @temp;
            if ( exists $insert{$depth_sort}{$i_sort} ) {
                $x_sort .= $insert{$depth_sort}{$i_sort};
		if ( length($insert{$depth_sort}{$i_sort}) < $ins{$i_sort}) {
		    $x_sort .= '*' x ($ins{$i_sort} - (length($insert{$depth_sort}{$i_sort})));
		}
            }
            elsif ( exists $ins{$i_sort}
                and ( !exists $insert{$depth_sort}{$i_sort} ) )
            {
                $x_sort .= '*' x $ins{$i_sort};
            }
            push @line_sort, $x_sort;
            last unless @temp;
        }
	delete $pos{$depth_sort}{$head_sort};
        $pos{$depth_sort}{$plot_head} = [split(//, join("",@line_sort))];
	if ($rmdup) {
	    my $bampos = $header_reset{$depth_sort}{$head_sort};
	    my @keygrp = split(/\t/, $alias{$depth_sort}{$bampos});
	    my $rc = $uniq{$keygrp[0]}{$bampos}{$keygrp[1]};
	    my $fcount = (exists $$rc{"+"}) ? $$rc{"+"} : 0;
	    my $rcount = (exists $$rc{"-"}) ? $$rc{"-"} : 0;
	    $dupanno{$depth_sort}{$plot_head} = "+$fcount-$rcount";
	    $strand{$depth_sort} = ($fcount < $rcount) ? '-' : '+';
	}
    }
}

# change positions and color each base
my $max_dep = (sort {$b<=>$a} keys %pos)[0];
my %color_sel = ();
open OUT, ">$prefix.tmp.dat" or die;
foreach my $depth_s2 ( keys %pos ) {
    my $temp_depth = $max_dep - $depth_s2 + 1;
    foreach my $head_s2 ( keys %{ $pos{$depth_s2} } ) {
        my @temp2 = @{$pos{$depth_s2}{$head_s2}};
	my $outrd_len = scalar (@temp2);
        for my $i_s2 ( $head_s2 .. ($head_s2 + $outrd_len - 1) ) {
            my $x_sort2 = shift @temp2;
	    $x_sort2 = lc($x_sort2) if ($strand{$depth_s2} =~ /\-/);
            next if $x_sort2 eq '-';
            if ( !$showbase and $reference and $ref{$i_s2} and !exists $clip{$depth_s2}{$i_s2} and ( $x_sort2 ne '*' ) ) {
                if ( uc($x_sort2) eq uc($ref{$i_s2}) ) {
                    $x_sort2 = ($strand{$depth_s2} =~ /-/) ? '|' : '=';
                }
            }

	    my $color =
	      ( exists $clip{$depth_s2}{$i_s2} ) ? "D"
	      : (
		( $x_sort2 eq "*" ) ? "B"
		: (
		      ( exists $mmap{$depth_s2} ) ? "C"
		    : ( ( exists $xtam{$depth_s2} ) ? "E" : "A" )
		)
	      );
	    $color_sel{$color} = 1;
            print OUT "$temp_depth\t$i_s2\t$x_sort2\t$color\n";
        }
	if ($anno && exists $dupanno{$depth_s2}{$head_s2}) {
	    $color_sel{"F"} = 1;
	    print OUT join("\t", $temp_depth, ($head_s2 + $outrd_len + 2), $dupanno{$depth_s2}{$head_s2}, "F")."\n";
	}
    }
}

foreach my $i_ref2 ( sort {$a<=>$b} keys %ref ) {
    my $color = ($ref{$i_ref2} eq "*") ? "B" : "A";
    $color_sel{$color} = 1;
    print OUT "$depth\t$i_ref2\t$ref{$i_ref2}\t$color\n";
}
close OUT;

my %color_map = (
    A => q("black"),
    B => q("red"),
    C => q("darkblue"),
    D => q("gray"),
    E => q("darkgreen"),
    F => q("orange")
);

my %label_map = (
    A => q("base"),
    B => q("padding"),
    C => q("multimap"),
    D => q("clip"),
    E => q("XT:A:M"),
    F => q("anno")
);

my $color_string = "c(";
my $label_string = "c(";
foreach my $sel (sort keys %color_sel) {
    $color_string .= $color_map{$sel}.",";
    $label_string .= $label_map{$sel}.",";
}
$color_string =~ s/,+$/)/;
$label_string =~ s/,+$/)/;

if ($pos =~ /in/) {
    $pos1 += get_cumulate_ins(\%ins, $pos1) + 1;
    $pos2 += get_cumulate_ins(\%ins, $pos2) - 1;
}
else {
    $pos1 += get_cumulate_ins(\%ins, $pos1);
    $pos2 += get_cumulate_ins(\%ins, $pos2);
}

my $startpos = $pot - $length - 5;
my $endpos = $end + $length + 5;
my $real_total = $endpos - $startpos + get_cumulate_ins(\%ins, $endpos);
my $wid  = ($real_total+10)/12 + 1;


my %xscale = ();
for (my $i = $startpos; $i < $endpos; $i++) {
    next if ($i % 50 != 0);
    $xscale{($i + get_cumulate_ins(\%ins, $i))} = $i;
}

my @xlims = ( $startpos, ($endpos + get_cumulate_ins(\%ins, $endpos)) );

my $scalex = "breaks=c(".
                join(",", (sort {$a<=>$b} keys %xscale)).
                "), labels=c(".
                join(",", (sort {$a<=>$b} values %xscale))
                ."), limits=c(".
                join(",", @xlims).
                ")";


my $cmd  = $prefix . '.plot.R';
my $name = $prefix . '.png';
open OUT_CMD, ">", $cmd or die;
print OUT_CMD << "EOF";
#!$Rs
require(ggplot2,quiet=TRUE)
previous_theme <- theme_set(theme_bw())
a <- read.table("$prefix.tmp.dat",header=F)
n <- max(a\$V1)
h <- n/12 + 2
#png(file="$name",width=$wid,height=h,units="in",res=96)
bitmap(file="$name",width=$wid,height=h,units="in",res=96)
p <- ggplot(a) + geom_vline(xintercept = $pos1:$pos2, colour = "#ffb6c1",size=2.8)
p <- p + scale_x_continuous($scalex)
p <- p + geom_text(aes(x=V2,y=V1,label=V3,color=V4),size=2)
p <- p + scale_colour_manual(values=$color_string, labels=$label_string, guide = guide_legend(title = NULL))
p <- p + theme(title=element_text("$title"),plot.title = element_text(size=20),panel.background=element_rect(colour=NA))
p <- p + xlab(NULL) + ylab("depth") + coord_cartesian(ylim = c(0, n+2))+ggtitle("$title");
p
garbage<-dev.off()
EOF
close OUT_CMD;
my $return = `$Rs $cmd`;
unlink( $cmd, "$prefix.tmp.dat" ) if (!$debug);

exit 0;

sub get_cumulate_ins {
    my ($all_ins, $p) = @_;
    my $total_ins = 0;
    foreach my $ins_p (sort {$a<=>$b} keys %$all_ins) {
	last if ($ins_p >= $p);
	$total_ins += $$all_ins{$ins_p};
    }
    return $total_ins;
}

my $time_string=`date '+%Y-%m-%d %H:%M:%S'`; chomp $time_string; my $line= "$time_string $0"; 
`echo $line >> /ifs9/B2C_SGD/PROJECT/MGISEQ-2000_Project/exome_diagnose/exome_cnv/WebServer/run.log`
