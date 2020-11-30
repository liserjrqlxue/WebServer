#!/usr/bin/perl -w
use strict;
use File::Basename;
my @find= glob "/ifs7/B2C_SGD/PROJECT/BGISEQ-500_Project/upload/dataEveryWeek/Upload/1*";
print "$#find\n";
if ( $#find< 0){
	print "no file to upload.\n";	
}else{
	print "Got file to upload!\n";
}
