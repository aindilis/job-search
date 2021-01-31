#!/usr/bin/perl -w

use System::MEAD;

use Data::Dumper;

my $mead = System::MEAD->new;
$mead->StartServer;

my $dir = "/var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList";
# my $dir = "/var/lib/myfrdcsa/codebases/internal/job-search/scripts/test";

foreach my $file (split /\n/, `find $dir`) {
  if ($file =~ /\.txt$/) {
    my $c = `cat "$file"`;
    print Dumper($mead->Summarize(Text => $c));
  }
}
