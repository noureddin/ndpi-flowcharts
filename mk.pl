#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw( :encoding(UTF-8) :std );
binmode STDIN, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

open my $indexfh, '>', 'index.html';
print {$indexfh} qq[
    <title>nDPI Flowcharts (Unofficial)</title>
    <style>
        li { list-style: none; }
        * { text-align: center; }
        .subheader { font-size: 75%; }
    </style>
    <h2>Currently Charted Functions</h2>
    <ul>
];

my $diarootdir = 'dpi/';
opendir my $diadir, +$diarootdir;

my %htmlfiles = ('index.html' => undef);

while (my $diafile = readdir($diadir)) {
    next unless ($diafile =~ m/[.]dia$/);

    my $svgfile = $diafile=~s|dia$|svg|r;
    my $htmlfile = $svgfile=~s/svg$/html/r;
    $diafile = $diarootdir.$diafile;

    $htmlfiles{$htmlfile} = undef;

    my $title = $svgfile=~s|-|/|r =~ s/[.].*//r;

    print {$indexfh} qq{ <li><p><a href="$htmlfile">$title</a></p></li> }
        if ($title !~ /\//);

    # next unless $htmlfile is more recent than $diafile; ie, already converted.
    next if -e $htmlfile && -M $htmlfile < -M $diafile;

    `dia -t svg-py -e "$svgfile" "$diafile" 2>/dev/null`;

    open my $infile, '<', $svgfile;

    # ignore the first 2 lines and retrieve the third
    my $svgimg = (<$infile>,<$infile>,<$infile>);
    # scale the image down a bit
    $svgimg =~ s|(?<=width=")([.0-9]+)|$1*2/3|e;
    $svgimg =~ s|(?<=height=")([.0-9]+)|$1*2/3|e;
    # center the image vertically
    my $topoffset = (19.89-$1*2/3)/2;  # 19.89cm emperically equals 720px
    $topoffset = 0 if $topoffset < 0;

    # slurp the rest of the svg file
    $svgimg .= do { local $/ = undef; <$infile> };
    $svgimg =~ s|font-size="[.0-9]+"|font-size="0.75"|g;
    # $svgimg =~ s|Amiri|Times New Roman|g;

    close $infile;
    unlink $svgfile;

    open my $outfile, '>', $htmlfile;

    print {$outfile} qq{
        <html>
            <head>
                <title>$title</title>
                <style>
                    svg {
                        position: relative;
                        top: ${topoffset}cm;
                    }
                </style>
            </head>
            <body>
                <div align="center">
                    $svgimg
                </div>
            </body>
        </html>
    };

    close $outfile;
}
closedir $diadir;

# remove all htmlfiles that are not in %htmlfiles; these are files that no longer
# have corresponding $diafile, for example their $diafile is renamed or removed.
opendir my $htmldir, '.';
while (my $htmlfile = readdir($htmldir)) {
    next unless ($htmlfile =~ m/[.]html$/);
    unlink $htmlfile unless exists $htmlfiles{$htmlfile};
}
closedir $htmldir;

print {$indexfh} qq[
    </ul><hr>
    <h2>Not-yet Charted Functions<br><span class="subheader">(That Are Linked From The Currently Charted Functions)</span></h2>
    <ul>
];

my @missing = `bash missing.sh`;
print {$indexfh} "<li><p>$_</p></li>" for @missing;

my $repo = 'github.com/noureddin/ndpi-flowcharts';
my $demo = 'noureddin.github.io/ndpi-flowcharts';
my $orig = 'github.com/ntop/nDPI';
print {$indexfh} qq[
    </ul><hr>
    <p>Online Repo: <a href="https://www.$repo">$repo</a></p>
    <p>Online Demo: <a href="https://$demo">$demo</a></p>
    <p>nDPI Repo: <a href="https://www.$orig">$orig</a></p>
];

close $indexfh;
