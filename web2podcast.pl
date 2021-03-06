#!/usr/local/bin/perl
# Drew Stephens <drew@dinomite.net>
# 2009-3-5
#
# Create a podcast from a DI stream rip
use warnings;
use strict;

use DateTime;
use Data::GUID;
use Getopt::Std;
use POSIX qw(strftime);

# Configure these
my $RIP_DIR = '/home/dinomite/tmp/streamRips';
my $WEB_DIR = '/home/dinomite/public_html/podcasts';
my $WEB_ROOT = 'http://dinomite.net/~dinomite/podcasts';

my $usage =<< "EOT";
$0 [hd] showName artist description
    showName - The name of the show (given by StreamRipper)
    ripSubdir - Subdirectory for this show's rips
    artist - The show artist
    description - The description for the XMLfile

    Use -d for debugging output and to not clean up after finishing.
EOT

# Get options
our ($opt_h, $opt_d);
getopts('dh');

die $usage if (scalar(@ARGV) != 4 || $opt_h);
my $debug = 1 if ($opt_d);
print "Running debug mode; args:\n" if ($debug);
map {print "\t$_\n"} @ARGV;

# Get command line information
my $showName = $ARGV[0];
my $ripSubdir = $ARGV[1];
my $description = $ARGV[2];
my $artist = $ARGV[3];

# Create the names for use in the XML file
my $joinedName = downcase($showName);
my $baseDir = "$WEB_DIR/$joinedName";
my $baseURL = "$WEB_ROOT/$joinedName";

# Use a loose regex to find the downloaded show file
my $showFileGrep = $showName;
$showFileGrep =~ s/[ ]/./g;
# Move it to the web directory
my $showFileCommand = "ls $RIP_DIR/$ripSubdir | grep -i '$showFileGrep' | head -1";
my $showFile = `$showFileCommand`;
chomp $showFile;
# Die if the show isn't there
print "showFileCommand: $showFileCommand\nshowFile: $showFile\n" if ($debug);
die "$showName ($showFileGrep) not found in $RIP_DIR/$ripSubdir\n" if ($showFile eq '');

# Create destination file name
my $newFile = downcase($showFile);
# Strip the streamripper numbers
$newFile =~ s/00\d\d_//;

# Move the show MP3 to the web directory
mkdir($baseDir) unless (-d $baseDir);
my $copyShowFileCommand = "cp \"$RIP_DIR/$ripSubdir/$showFile\" \"$baseDir/$newFile\"";
print "copyShowFileCommand: $copyShowFileCommand\n" if ($debug);
system $copyShowFileCommand;

# Get the size
my @stats = stat "$baseDir/$newFile";
my $fileSize = $stats[7];

# Human date & ISO8601 date
my $date = DateTime->now->ymd;
my $pubDate = strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time()));

# The web-accessible file URL
my $fileURL = "$baseURL/$newFile";
$fileURL =~ s/'/&apos;/g;

# Create the XML file
my $guid = Data::GUID->new->as_string();
my $xmlOutput =<< "EOT";
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes='http://www.itunes.com/dtds/podcast-1.0.dtd' version='2.0'>
    <channel>
        <title>$showName</title>
        <link>$baseURL/$joinedName</link>
        <description>$description</description>
        <itunes:summary>$description</itunes:summary>
        <itunes:category text="Music"/>

        <item>
            <title>$showName - $date</title>
            <guid isPermaLink='false'>$guid</guid>
            <enclosure url='$fileURL' type='audio/mpeg' length='$fileSize'/>
            <pubDate>$pubDate</pubDate>
            <itunes:category text="Music"/>
            <itunes:author>$artist</itunes:author>
        </item>
    </channel>
</rss>
EOT

my $xmlFileLocation = "$baseDir/$joinedName.xml";
open XMLFILE, ">$xmlFileLocation";
print XMLFILE $xmlOutput;
close XMLFILE;

# Clean up (or leave detritus if in debug mode)
unless ($debug) {
    system("rm $RIP_DIR/$ripSubdir/*.mp3");
    system("rm -r $RIP_DIR/$ripSubdir/incomplete");
}

# Make a filesystem-friendly name; lowercase, underscores instead of spaces
sub downcase {
    my $string = shift;

    $string = lc($string);
    $string =~ s/ /_/g;

    return $string;
}
