#!/usr/bin/perl -w

my $unlabelled = "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-testing-small";
my $resultsdir = "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/results";

if (! -d "$unlabelled-labelled") {
  mkdir "$unlabelled-labelled";
}

my $corpus = "jobs";
my $learner = "new Recommended.CRFAnnotatorLearner()";
my $other = $learner;
$other =~ s/\W/_/g;

foreach my $file (split /\n/, `ls $resultsdir/$corpus-*-$other.result`) {
  print "<$file>\n";
  if ($file =~ /^$resultsdir\/$corpus-(.+)-$other.result$/) {
    my $span = $1;
    # now let's get the items
    foreach my $line (split /\n/, `cat "$file"`) {
      # addToType job119474.tagged.pl 53 10 _prediction
      if ($line =~ /^addToType\s+(.+?)\s+(\d+)\s+(\d+)\s+_prediction$/) {
	my $datafile = $1;
	my $offset = $2;
	my $length = $3;
	my $c = `cat "$unlabelled/$datafile"`;
	
      } else {
	print "ERROR: $line\n";
      }
    }
  }
}

