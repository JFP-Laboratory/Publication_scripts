#!/usr/bin/perl
# Pombert lab 2017
# Plot matrices in CSV format
# Requires R, R-devel, RColorBrewer and the Bioconductor ComplexHeatmap packages

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

## Usage definition
my $usage = "\nUSAGE = Matrix_plotter.pl [OPTIONS]\n
EXAMPLE (simple): Matrix_plotter.pl -i *.dist -f pdf
EXAMPLE (advanced): Matrix_plotter.pl -i *.dist -f jpeg -res 600 -c white blue red yellow -sh 300 -wd 3 -he 10";
my $hint = "Type Matrix_plotter.pl -h (--help) for list of options\n";
die "$usage\n\n$hint\n" unless@ARGV;

my $options = <<'END_OPTIONS';

-h (--help)		Display this list of options
-i (--input)		Input files
-f (--format)		Image format (pdf, svg, jpeg, png) [Default: pdf]
-wd (--width)		Heatmap column width in mm  [Default: 3]
-c (--colors)		Desired library(RColorBrewer) colors in order of decreasing similarity [Default: white blue magenta]
-l (--legend)		Legend position (left, bottom, rigth) [Default: right]
-res (--resolution)	Resolution in DPI (for jpegs and pngs) [Default: 300]
-sh (--shades)		Number of color shades desired [Default: 300]
-si (--size)		Image height in inches [Default: 4] ## Width set automatically 

END_OPTIONS

my $help ='';
my @colors;
my @files;
my $shades = 300;
my $rowfont = 8; my $rowface = 'italic';
my $colfont = 8; my $titlefont = 12;
my $wd = 3; my $htwd; ## width per cell in mm
my $height = 4; my $width; ## file width = automatically adjusted
my $title;
my $format = 'pdf';
my $res = 300;
my $legend = 'right';

GetOptions(
	'h|help' => \$help,
	'i|input=s@{1,}' => \@files,
	'f|format=s' => \$format,
	'wd|width=i' => \$width,
	'si|size=i' => \$height,
	'res|resolution=i' => \$res,
	'c|colors=s@{1,}' => \@colors,
	'sh|shades=i' => \$shades,
	'l|legend=s' => \$legend
);
if ($help){die "$usage\n$options";}
if (scalar @colors == 0){@colors = ('white', 'blue', 'magenta');}

my $file;
while ($file = shift@files){
	my $columns = `head -n 1 $file | grep -o "," | wc -l`;
	chomp $columns;
	$htwd = $columns * $wd;							## Adjusting heatmap width; # columns * desired size per column (in mm) 
	$width = int ($columns * $wd * 0.0393701) + 3;	## Adjusting PDF width (1 mm = 0.0393701 inch) to account for number of columns to plots
	my $map; if ($file =~ /^(\w+)\.(\w+)/){$map = $1; $title = $1.$2; $title =~ s/_/ /g;}
	## Creating header
	open OUT, ">$file.R";
	print OUT '#!/usr/bin/Rscript'."\n";
	print OUT 'library(ComplexHeatmap)'."\n".'library(RColorBrewer)'."\n".'library(methods)'."\n";
	print OUT 'message ("'."Plotting $file\...".'")'."\n";
	## Creating color palette and fonts
	print OUT 'colors <- colorRampPalette(c(';
	for (0..$#colors-1){print OUT '"'."$colors[$_]\", ";}
	print OUT "\"$colors[$#colors]\"".'))(n = '."$shades".')'."\n";
	print OUT 'ht_global_opt(heatmap_row_names_gp = gpar(fontsize = '."$rowfont".', fontface = "'."$rowface".'")';
	print OUT ', heatmap_column_names_gp = gpar(fontsize = '."$colfont".')';
	print OUT ', heatmap_column_title_gp = gpar(fontsize = '."$titlefont".'))'."\n";
	## Output to PDF
	Format();
	## Working on matrix
	print OUT "$map".' <- read.csv("'."$file".'", header=TRUE)'."\n";
	print OUT 'rownames('."$map".') <- '."$map".'[,1]'."\n";
	print OUT 'colnames('."$map".')'."\n";
	print OUT "data_$map".' <- data.matrix('."$map".'[,2:ncol('."$map".')])'."\n";
	print OUT "ht_$map".' = Heatmap('."data_$map".', name = "'."$map".'", width = unit('."$htwd".', "mm"), ';
	print OUT 'cluster_rows = FALSE, cluster_columns = FALSE, rect_gp = gpar(col = "white", lty = 1, lwd = 1), ';
	print OUT 'column_title = "'."$title".'", col = colors)'."\n";
	
	print OUT "class(ht_$map)\n";
	print OUT "draw(ht_$map, heatmap_legend_side = \"$legend\")\n";
	print OUT "dev.off()\n";
	
	close OUT; system "chmod a+x $file.R\; ./$file.R";
}

## subroutines
sub Format {
	my $wide = 3300; my $tall = 3300;
	my $scaling = ($res/300);
	$wide = int($wide*$scaling); $tall = int($tall*$scaling*($height/$width)); print "scaling = $scaling,  wide = $wide, tall = $tall\n";
	if ($format eq 'pdf'){print OUT 'pdf(file="'."$file.pdf".'", useDingbats=FALSE, width='."$width".', height='."$height".')'."\n";}
	elsif ($format eq 'svg'){print OUT 'svg(file="'."$file.svg".'", width='."$width".', height='."$height".')'."\n";}
	elsif (($format eq 'jpeg')||($format eq 'png')){print OUT "$format".'(file="'."$file\.$format".'", width='."$wide".', height='."$tall".', res = '."$res".')'."\n";}
}