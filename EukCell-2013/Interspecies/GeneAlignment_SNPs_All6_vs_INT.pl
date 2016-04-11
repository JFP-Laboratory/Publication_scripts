#!/usr/bin/perl

## Loads a list of genes from a text file, one gene per line (e.g. ECU01_0100).
## Then each corresponding ECI, ECII and ECIII sequence is loaded (e.g. ECI/ECII/ECIII_ECU01_0100.string) and put into their own arrays with one base per line.
## Each aligned position is compared between the three genes, and written to the appropriate output files (*.invar, *.gaps, *.snps, *.metrics).
## This is possible because the genes have been aligned. A single frame shift will kill this script.
## Note 1: that if alignments are not based on codons, each gap containing gene will need to be verified.
## Note 2: The sequence must be on one line without a fasta header. Use fasta_to_string.pl script to convert to strings.
## Note 3: Added metrics for SNPs to bin the genes later on according to the relative amount of SNPs they display.


use strict;
use warnings;

my $usage = 'perl GeneAlignment_SNPs_All6_vs_INT.pl list.txt';

die $usage unless @ARGV;

while (my $txt = shift @ARGV) {

	open IN, "<$txt" or die "cannot open $txt";
	
		while (my $line = <IN>) {

			chomp $line;
		
			if ($line =~ /^(ECU\d+.*)/) { ## match the query to fit the desired gene names in the list provided
			
				my $ECU = $1;
		
				my $seq1= "ECI_$ECU.string";	## match the file extention to that of the input file used
				my $seq2 = "ECII_$ECU.string";	## match the file extention to that of the input file used
				my $seq3 = "ECIII_$ECU.string";	## match the file extention to that of the input file used
				my $seq4 = "INT_$ECU.string";	## match the file extention to that of the input file used
				my $seq5 = "HEL_$ECU.string";	## match the file extention to that of the input file used
				my $seq6 = "ROM_$ECU.string";	## match the file extention to that of the input file used

				open (IN1, $seq1);
				open (IN2, $seq2);
				open (IN3, $seq3);
				open (IN4, $seq4);
				open (IN5, $seq5);
				open (IN6, $seq6);

				open INVAR, ">$ECU.int.invar";
				open SNPs, ">$ECU.int.snps";
				open GAPs, ">$ECU.int.gaps";
				open MET, ">$ECU.int.metrics";
				print MET "Gene\tlength\tSNPs\tRatio\n";

				my $strain1 = <IN1>;
				my $strain2 = <IN2>;
				my $strain3 = <IN3>;
				my $strain4 = <IN4>;
				my $strain5 = <IN5>;
				my $strain6 = <IN6>;

				my @ECI = split ('', $strain1);
				my @ECII = split ('', $strain2);
				my @ECIII = split ('', $strain3);
				my @INT = split ('', $strain4);
				my @HEL = split ('', $strain5);
				my @ROM = split ('', $strain6);

				my $length = scalar @ECI;
				my $end = $length-1;

				my $position = 1;
				my $SNPs = 0;
				

				for (0..($end-1)) {
					
					if (($ECI[$_] eq '-') || ($ECII[$_] eq '-') || ($ECIII[$_] eq '-')|| ($INT[$_] eq '-')) {
					print GAPs "$position\t$ECI[$_]\t$ECII[$_]\t$ECIII[$_]\t$INT[$_]\n";
					$position++; 
					}
					elsif (($ECI[$_] eq $ECII[$_]) && ($ECI[$_] eq $ECIII[$_])&& ($ECI[$_] eq $INT[$_])) {
					print INVAR "$position\t$ECI[$_]\t$ECII[$_]\t$ECIII[$_]\t$INT[$_]\n";
					$position++; 
					}
					else {
					print SNPs "$position\t$ECI[$_]\t$ECII[$_]\t$ECIII[$_]\t$INT[$_]\n";
					$position++;
					$SNPs++;
					}
				}
				
				for ($end..$end) {
					
					my $ratio = ($SNPs/$length);
	
					if (($ECI[$_] eq '-') || ($ECII[$_] eq '-') || ($ECIII[$_] eq '-')|| ($INT[$_] eq '-')) {
					print GAPs "$position\t$ECI[$_]\t$ECII[$_]\t$ECIII[$_]\t$INT[$_]\n";
					$position++; 
					print MET "$ECU\t$length\t$SNPs\t$ratio\n";
					$SNPs = 0;
					}
					elsif (($ECI[$_] eq $ECII[$_]) && ($ECI[$_] eq $ECIII[$_])&& ($ECI[$_] eq $INT[$_])) {
					print INVAR "$position\t$ECI[$_]\t$ECII[$_]\t$ECIII[$_]\t$INT[$_]\n";
					$position++; 
					print MET "$ECU\t$length\t$SNPs\t$ratio\n";
					$SNPs = 0;
					}
					else {
					print SNPs "$position\t$ECI[$_]\t$ECII[$_]\t$ECIII[$_]\t$INT[$_]\n";
					$position++;
					$SNPs++;
					print MET "$ECU\t$length\t$SNPs\t$ratio\n";
					$SNPs = 0;
					}
				}
			}	
		}

	close IN1;
	close IN2;
	close IN3;
	close INVAR;
	close SNPs;
	close GAPs;
	close MET;

}

exit;

## Written by JF Pombert, Canadian Institute for Advanced Research
## University of British Columbia (2012)