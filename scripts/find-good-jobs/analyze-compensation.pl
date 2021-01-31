#!/usr/bin/perl -w

use Data::Dumper;

my @items = qw(cpg crg cwg dmg lbg wrg tlg);

foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList`) {
  if (-f $file) {
    foreach my $item (@items) {
      if (1 or $file =~ /$item/) {
	if (0) {
	  my $c = `grep "Compensation:" "$file"`;
	  if ($c =~ /<li>\s+Compensation:\s+(.+?)\s+<\//) {
	    my $pay = $1;
	    if ($pay =~ /\b(hr|hour)\b/i) {
	      print "$file\t$pay\n";
	    }
	  }
	}
	if (1) {
	  $c = `grep "Rate:" "$file"`;
	  if ($c =~ /^Rate:\s+(.+?)$/) {
	    my $pay = $1;
	    if ($pay =~ /\b(hr|hour)\b/i) {
	      print "$file\t$pay\n";
	    }
	  }
	}
      }
    }
  }
}
