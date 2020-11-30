#!/usr/bin/perl
use strict;
use Cwd;
use File::Basename;
use Cwd qw/abs_path/;
use Encode qw/encode decode/;
use FindBin qw($Bin);
use Spreadsheet::XLSX;
use Excel::Writer::XLSX;
use HTML::Entities;
use Getopt::Long;


my ($xlsx,$gene_list,$outxlsx,$dir);
GetOptions(
    "input|i=s"       => \$xlsx,
    "gene|g=s"        => \$gene_list,
    "output|o=s"      => \$outxlsx
);


$dir=dirname($outxlsx);
my %gene="";
my @genelist=(split /,|，/,$gene_list);
foreach my $genelist (@genelist){
		print "gene:$genelist\n";
        $gene{$genelist}=1;
}
if (-e $xlsx) {
    print "new excel name $outxlsx\n";
    my $report = Excel::Writer::XLSX->new($outxlsx)  or die "Error: [$outxlsx] $!\n";  #creat new excel tiet1 filtered
    my $title_format = $report->add_format(
        font      => 'Arial',
        size      => 11,
        bold      => 1,
        align     => 'left',
        valign    => 'top',
        text_wrap => 0
    );

    my $excel = Spreadsheet::XLSX -> new ($xlsx);
    foreach my $sheet (@{$excel -> {Worksheet}}) {
	    my $sheet_name=$sheet->{Name}; # print "last sheet name $last_sheet_name\n";
            #open TXT,">$dir/$sheet_name.txt" or die $!;
            printf ("Sheet: %s\n", $sheet->{Name});
            my $sheetout = $report->add_worksheet($sheet_name);
            my $rowout = 0;
            my $gene_index;
            foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {  #row
                if ($row == 0){
                    foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                        my $text = $sheet -> {Cells} [$row] [$col] -> {Val};
                        if ($sheet_name eq "filter_variants" and  $text eq "Gene Symbol"){
                            $gene_index = $col;
                        }elsif ($sheet_name eq "exon_cnv" and $text eq "exons.hg19"){
                            $gene_index = $col;
                        }elsif ($sheet_name eq "large_cnv" and $text eq "Gene"){
                            $gene_index = $col;
                        }
                        $sheetout ->write( $rowout, $col, decode_entities(H8($text)));

                    }
                    $rowout++;
                }else{
                    my $index_text = $sheet -> {Cells} [$row] [$gene_index] -> {Val};
                    if ($sheet_name eq "filter_variants"){
                        if (filter_variants($index_text)){
                            foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                                my $text=$sheet -> {Cells} [$row] [$col] -> {Val};
                                $sheetout ->write( $rowout, $col, decode_entities(H8($text)));
                            }
                            $rowout++;
                        }
                    }elsif($sheet_name eq "exon_cnv"){
                        if (exon_cnv($index_text)){
                            foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                                my $text=$sheet -> {Cells} [$row] [$col] -> {Val};
                                $sheetout ->write( $rowout, $col, decode_entities(H8($text)));
                            }
                            $rowout++;
                        }
                    }elsif($sheet_name eq "large_cnv"){
                        if (large_cnv($index_text)){
                            foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                                my $text=$sheet -> {Cells} [$row] [$col] -> {Val};
                                $sheetout ->write( $rowout, $col, decode_entities(H8($text)));
                            }
                            $rowout++;
                        }
                    }else{
                        foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
                            my $text=$sheet -> {Cells} [$row] [$col] -> {Val};
                            $sheetout ->write( $rowout, $col, decode_entities(H8($text)));
                        }
                        $rowout++;
                    }
                }
            }
    }
}


sub filter_variants{
    my $cellin = shift;
    if (exists $gene{$cellin}){
        return 1;
    }else{
        return 0;
    }
}

sub exon_cnv{
    my $cellin = shift;
    my @gene_exon_cnv;
    my @gene_part=(split /\,/,$cellin);
    foreach my $gene_part (@gene_part) {
        my @genes=(split /\_/,$gene_part)[0];
        push @gene_exon_cnv,@genes;
    }
    foreach my $gene_exon_cnv (@gene_exon_cnv) {
        #print "$gene_exon_cnv\n";
        if (exists $gene{$gene_exon_cnv}){
            return 1;
        }
    }
    return 0;
}

sub large_cnv{
    my $cellin = shift;
    my @gene_1=(split /:|;/,$cellin);
    foreach my $gene_1 (@gene_1) {
        if (exists $gene{$gene_1}) {
            return 1;
        }
    }
    return 0;
}

sub H8 {
    my $text = shift;
    return decode('utf-8', $text);
}

sub gbk {
    my $text = shift;
    return decode('gbk', $text);
}
