#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw( :encoding(UTF-8) :std );
binmode STDIN, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $htmlrootdir = '../noureddin.github.io/ndpi-flowcharts/';
my $diarootdir = 'dpi/';
opendir my $diadir, +$diarootdir;

my @chartedfns;
my %htmlfiles = ('index.html' => undef);

while (my $diafile = readdir($diadir)) {
    next unless ($diafile =~ m/[.]dia$/);

    my $svgfile = $diafile=~s|dia$|svg|r;
    my $htmlfile = $svgfile=~s/svg$/html/r;

    $htmlfiles{$htmlfile} = undef;

    $diafile = $diarootdir.$diafile;
    $htmlfile = $htmlrootdir.$htmlfile;


    my $title = $svgfile=~s|-|/|r =~ s/[.].*//r;

    push @chartedfns, $title
        if ($title !~ m|/|);

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
    my $topoffset = (19.89-$1*2/3)/2;  # 19.89cm emperically equals 720px -- works on my machine :P
    $topoffset = 0 if $topoffset < 0;

    # slurp the rest of the svg file
    $svgimg .= do { local $/ = undef; <$infile> };
    $svgimg =~ s|font-size="[.0-9]+"|font-size="0.75"|g;

    close $infile;
    unlink $svgfile;

    open my $outfile, '>', $htmlfile;

    print {$outfile} <<~"EOT";
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>$title</title>
            <style>
              \@font-face {
                /* https://www.amirifont.org/ */
                font-family: Amiri;
                font-style: normal;
                font-weight: 400;
                src: url('Amiri-Regular.woff2') format('woff2'),
                     url('Amiri-Regular.woff') format('woff');
              }
              svg {
                position: relative;
                top: ${topoffset}cm;
              }
              a { outline: none; }
              a:hover  :not(text) { fill: rgb(204, 204, 255); }
              a:active :not(text) { fill: rgb(150, 150, 255); }
            </style>
          </head>
          <body>
            <div align="center">

        $svgimg

            </div>
          </body>
        </html>
        EOT

    close $outfile;
}
closedir $diadir;

# Remove all htmlfiles that are not in %htmlfiles; these are files that no longer
#   have corresponding $diafile: for example their $diafile is renamed or removed.
opendir my $htmldir, +$htmlrootdir;
while (my $htmlfile = readdir($htmldir)) {
    next unless ($htmlfile =~ m/[.]html$/);
    unlink $htmlfile unless exists $htmlfiles{$htmlfile};
}
closedir $htmldir;

open my $indexfh, '>', $htmlrootdir.'index.html';
print {$indexfh} <<~"EOT";
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8">
      <title>nDPI Flowcharts (Unofficial)</title>
      <style>
        * { text-align: center; }
        .subheader { font-size: 75%; }
        li { list-style: none; }
        table { /* center */ margin: 0 auto; border: none; }
        td:first-child { text-align: left; }
        td.def { text-align: right; font-size: 65%; }
        a { text-decoration: none; color: #1034A6; } /* Egyptian Blue, b/c I'm Egyptian :P */
        #main {
          text-align: center;
          font-weight: bold;
          font-size: 150%;
        }
        hr { margin-top: 1rem; }
      </style>
    </head>
    <body>
      <h1>nDPI Flowcharts (Unofficial)</h1>
      <div id="main"><a href="main.html">Start Here!</a></div>
      <hr>
      <h2>Currently Charted Functions</h2>
      <table>
  EOT

my $chartedfns = join '',
    map { qq[      <tr><td><a href="$_->[0].html">$_->[0]</a></td><td class="def">defined in <b>$_->[1]</b></td></tr>\n] }
    sort { $a->[1] cmp $b->[1] || $a->[0] cmp $b->[0] }
    map { [ $_->[0], ($_->[1] =~ /^[.]/)? $_->[1] =~ s|^\.\.\/||r : 'example/'.$_->[1] ] }
    grep { $_->[0] ne 'main' }
    map { [split] }
    map { `bash where-is-defined.sh $_` }
        @chartedfns;

# Probably the following is the worst way to have some vertical space between
#   rows that contain functions that are defined in different source files.
my $prevsource;
for (split "\n", $chartedfns) {
    /<b>([^<]+)</;

    if (not defined $prevsource) {
        $prevsource = $1;
        print {$indexfh} $_, "\n";
        next;
    }

    if ($prevsource ne $1) {
        s|<tr>|<tr><td style="padding:5px"></td><td></td></tr>\n      <tr>|;
        $prevsource = $1;
    }

    print {$indexfh} $_, "\n";
}

print {$indexfh} <<~"EOT";
      </table><hr>
      <h2>Not-yet Charted Functions<br><span class="subheader">(That Are Linked From The Currently Charted Functions)</span></h2>
      <table>
  EOT

print {$indexfh}
    qq[      <tr><td>$_->[0]</td><td class="def">defined in <b>$_->[1]</b></td></tr>\n]
        for
            sort { $a->[1] cmp $b->[1] || $a->[0] cmp $b->[0] }
            map { [split / +\.\.\// ] }
                split "\n", `bash where-is-defined.sh`;

my $repo = 'github.com/noureddin/ndpi-flowcharts';
my $demo = 'noureddin.github.io/ndpi-flowcharts';
my $orig = 'github.com/ntop/nDPI';
print {$indexfh} <<~"EOT";
      </table><hr>
      <p>Online Repo: <a href="https://$repo">$repo</a></p>
      <p>Online Demo: <a href="https://$demo">$demo</a></p>
      <p>nDPI   Repo: <a href="https://$orig">$orig</a></p>
    </body>
  </html>
  EOT

close $indexfh;

