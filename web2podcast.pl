#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net>
# 2009-3-5
#
# Create a podcast from a DI stream rip
use warnings;
use strict;

use DateTime;
use POSIX qw(strftime);

# Configure these
my $RIP_DIR = '/home/dinomite/tmp/streamRips';
my $WEB_DIR = '/home/dinomite/public_html/podcasts';
my $WEB_ROOT = 'http://dinomite.net/~dinomite/podcasts';

my $usage =<< "EOT";
$0 showName
    showName - The name of the show (given by StreamRipper)
    artist - The show artist
    description - The description for the XMLfile
EOT

die $usage unless (scalar(@ARGV) == 3);
my $showName = $ARGV[0];
my $description = $ARGV[1];
my $artist = $ARGV[2];

my $joinedName = downcase($showName);
my $baseDir = "$WEB_DIR/$joinedName";
my $baseURL = "$WEB_ROOT/$joinedName";

# Find the show file & move it to the web directory
my $showFile = `ls $RIP_DIR | grep "$showName"`;
chomp $showFile;
# Die if the show isn't there
die "$showName not found in $RIP_DIR\n" if ($showFile eq '');

my $newFile = downcase($showFile);
# Strip the streamripper numbers
$newFile =~ s/00\d\d_//;

# Move the show MP3 to the web directory
mkpath($baseDir) unless (-d $baseDir);
system "mv \"$RIP_DIR/$showFile\" \"$baseDir/$newFile\"";

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
            <guid isPermaLink='false'>$fileURL</guid>
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

# Clean up
system( "rm -r $RIP_DIR/*" );

# Make a filesystem-friendly name; lowercase, underscores instead of spaces
sub downcase {
    my $string = shift;

    $string = lc($string);
    $string =~ s/ /_/g;

    return $string;
}
