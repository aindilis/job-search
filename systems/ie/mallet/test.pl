#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

if (0) {
  foreach my $file (split /\n/, `ls -1  ../../../data/source/CraigsList-backup/chicago.craigslist.org/wcl/sof/*.txt`) {
    print $file."\n";
    if ($file =~ /(\d+)\.html\.txt$/) {
      my $number = $1;
      system "./process-data-sets.pl --job --process ".shell_quote($file)." > data/output/$number.txt";
    }
  }
}

if (0) {
  foreach my $file (split /\n/, `ls -1  ../../../data/source/CraigsList-backup/chicago.craigslist.org/wcl/res/*.txt`) {
    print $file."\n";
    if ($file =~ /(\d+)\.html\.txt$/) {
      my $number = $1;
      system "./process-data-sets.pl --resume --process ".shell_quote($file)." > data/output/$number.txt";
    }
  }
}
