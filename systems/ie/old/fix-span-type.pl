#!/usr/bin/perl -w

my $dir = shift;
my $newdir = "$dir-fixed-spantype";
if (! -d $newdir) {
  mkdir $newdir;
}
foreach my $file (split /\n/, `ls $dir`) {
  if (-f "$dir/$file") {
    my $it = `cat "$dir/$file"`;
    $it = "<document>\n$it\n</document>\n";
    my $OUT;
    open(OUT,">$newdir/$file") or die "Youza!\n";
    print OUT $it;
    close(OUT);
  }
}
