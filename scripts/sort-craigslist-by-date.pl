#!/usr/bin/perl -w

use Data::Dumper;
use Date::Manip;
use File::Stat;

my $time = {};
foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source`) {
  if (-f $file) {
    # get a stat on this
    my $stat = File::Stat->new($file);
    $time->{$file} = $stat->ctime;
  }
}

# print Dumper($time);
foreach my $file (sort {$time->{$b} <=> $time->{$a}} keys %$time) {
  my $date = &ParseDateString("epoch ".$time->{$file});
  print $date."\t".$file."\n";
}
