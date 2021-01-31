#!/usr/bin/perl -w

foreach my $file (split /\n/, `ls -1`) {
  if ($file =~ /^-(.+)$/) {
    system "mv -- $file $1";
  }
}
