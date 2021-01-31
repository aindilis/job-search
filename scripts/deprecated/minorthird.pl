#!/usr/bin/perl -w

# program to test minorthird wrapper

use PerlLib::MinorThird;

use Data::Dumper;

my $datadir = "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs";

my $mt = PerlLib::MinorThird->new
  (TrainingDir => "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs",
   TestingDir => "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-testing");

foreach my $file (split /\n/, `ls $datadir`) {
  my $f = "$datadir/$file";
  my $c = `cat "$f"`;
  my $e = PerlLib::MinorThird::Entry->new
    (
     ID => $f,
     StorageFile => $f,
     Contents => $c,
    );
  $mt->TrainingSet->Add($e->ID => $e);
}

$mt->TrainExtractor;

# foreach my $file (split /\n/, `find data/sources/Craigslist`) {
#   my $f = "$datadir/$file";
#   my $c = `cat "$f"`;
#   my $e = PerlLib::MinorThird::Entry->new
#     (
#      ID => $c,
#      StorageFile => "$c".".mt",
#      Contents => $c,
#     );
#   $mt->TrainingSet->Add($e->ID => $e);
# }

# $mt->Extract;

print Dumper([map $_->Results, $mt->TestingSet->Values]);
