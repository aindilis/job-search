#!/usr/bin/perl -w

use Data::Dumper;

my @matches;

my $keys = {};
my $values = {};
my $cross = {};
my $dir = "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs";
foreach my $file (split /\n/,`ls $dir`) {
  my $c = `cat "$dir/$file"`;
  my @matches = $c =~ /<([^\>]+)>(.*?)<\/\1>/g;
  while (@matches) {
    my ($key,$value) = (shift @matches,shift @matches);
    $keys->{$key} = 1;
    $values->{$value} = 1;
    $cross->{$key}->{$value} = 1;
    # print "<$key,$value>\n";
  }
}
# print Dumper([sort keys %$keys]);
# print Dumper([sort keys %$values]);
print Dumper($cross);
