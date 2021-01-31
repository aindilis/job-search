#!/usr/bin/perl -w

use System::MinorThird;

use Data::Dumper;

my $input = [
	     {
	      Corpus => "jobs",
	      Train => "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs",
	      Test => "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-testing-small",
	     },
	     {
	      Corpus => "resumes",
	      Train => "/var/lib/myfrdcsa/datasets/resume300/data",
	      Test => "/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/resumes-testing",
	     },
	    ];

my $minorthird = System::MinorThird->new();
my $modeldir = "/var/lib/myfrdcsa/codebases/data/job-search/ie/models";
my $resultdir = "/var/lib/myfrdcsa/codebases/data/job-search/ie/results";

# -learner “new VPHMMLearner(new CollinsPerceptronLearner(1,5), new Recommended.TokenFE(), new InsideOutsideRedution())”
# my $learner = "CRFLearner";
# my $learner = "new VPHMMLearner(new CollinsPerceptronLearner(1,5), new Recommended.TokenFE(), new InsideOutsideRedution())";
# my $learner = "new Recommended.VPHMMLearner(new CollinsPerceptronLearner(1,5), new Recommended.TokenFE(), new InsideOutsideRedution())";
# my $learner = "new VPHMMLearner(new CollinsPerceptronLearner(1,5), new Recommended.TokenFE(), new InsideOutsideReduction())";
my $learner = "new Recommended.CRFAnnotatorLearner()";
# my $learner = "new Recommended.VPHMMLearner(new CollinsPerceptronLearner(1,5), new Recommended.TokenFE(), new InsideOutsideReduction())";
# my $learner = "new edu.cmu.minorthird.ui.Recommended$VPHMMLearner(new edu.cmu.minorthird.classify.sequential.CollinsPerceptronLearner(1,5), new edu.cmu.minorthird.ui.Recommended$TokenFE(), new InsideOutsideReduction())";

# Recommended$SemiCRFAnnotatorLearner.class
# Recommended$SVMCMMLearner.class
# Recommended$VPSMMLearner2.class
# Recommended$MEMMLearner.class
# # Recommended$SegmentAnnotatorLearner.class
# Recommended$CRFAnnotatorLearner.class
# Recommended$VPCMMLearner.class
# Recommended$VPHMMLearner.class
# Recommended$VPSMMLearner.class
# # Recommended$SequenceAnnotatorLearner.class

# # # Recommended$TokenPropUsingFE.class
# # # Recommended$TokenFE$MyCLP.class
# # # Recommended$HMMTokenFE.class
# # # Recommended$NaiveBayes.class
# # # Recommended$MultitokenSpanFE$MyCLP.class
# # # Recommended$VotedPerceptronLearner.class
# # # Recommended$HMMTokenFE$MyCLP.class
# # # Recommended$KnnLearner.class
# # # Recommended$TokenFE.class
# # # Recommended$BoostedStumpLearner.class
# # # Recommended$DecisionTreeLearner.class
# # # Recommended$CascadingBinaryLearner.class
# # # Recommended$DocumentFE.class
# # # Recommended$SVMLearner.class
# # # Recommended$MostFrequentFirstLearner.class
# # # Recommended$OneVsAllLearner.class
# # # Recommended$MaxEntLearner.class
# # # Recommended$BoostedDecisionTreeLearner.class
# # # Recommended$MultitokenSpanFE.class
# # # Recommended$VPTagLearner.class
# # # Recommended$TweakedLearner.class
# # # Recommended$HMMAnnotatorLearner.class


foreach my $entry (@$input) {
  # CheckDataset(Dataset => $entry->{Train});
  # CheckDataset(Dataset => $entry->{Test});
  my $corpus = $entry->{Corpus};
  my $res = ExtractKeys(Dir => $entry->{Train});
  my @keys = sort keys %$res;
  print Dumper(\@keys);

  my $other = "";
  if (defined $learner) {
    $other = $learner;
    $other =~ s/\W/_/g;
    $other = "-$other";
  }
  foreach my $key (@keys) {
    $minorthird->LearnExtractor
      (
       LabelledDir => $entry->{Train},
       Span => $key,
       Extractor => "$modeldir/$corpus-$key$other.extractor",
       Learner => $learner,
      );
    $minorthird->RunExtractorOnUnlabelledData
      (
       UnlabelledDir => $entry->{Test},
       Extractor => "$modeldir/$corpus-$key$other.extractor",
       Result => "$resultdir/$corpus-$key$other.result",
       Learner => $learner,
      );
  }
}

sub ExtractKeys {
  my %args = @_;
  my @matches;
  my $keys = {};
  my $values = {};
  my $cross = {};
  my $dir = $args{Dir};
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
  return $cross;
}

sub CheckDataset {
  my %args = @_;
  my $ds = $args{Dataset};
  my $c = "rm $ds/*~";
  print "$c\n";
  system $c;
  foreach my $file (split /\n/, `find "$args{Dataset}"`) {
    my $c = `cat "$file"`;
    my @chars = split //, $c;
    # now make a parser to detect tags
    my @stack;
    my $state = "closed";
    my $candidatetag = "";
    my $i = 0;
    while (@chars) {
      my $char = shift @chars;
      if ($state eq "closed") {
	if ($char eq "<") {
	  $state = "open";
	}
      } elsif ($state eq "open") {
	if ($char eq ">") {
	  # print "<$candidatetag>\n";
	  if ($candidatetag =~ /^\/(.+)$/) {
	    if ($stack[$#stack] eq $1) {
	      pop @stack;
	    } else {
	      print "ERROR: <$file-$i> <".$stack[$#stack]."> <".$1.">\n";
	      exit (0);
	    }
	  } else {
	    push @stack, $candidatetag;
	  }
	  $candidatetag = "";
	  $state = "closed";
	} elsif ($char =~ /[\/\w]/) {
	  $candidatetag = "$candidatetag$char";
	} else {
	  $state = "closed";
	  $candidatetag = "";
	}
      }
      ++$i;
    }
  }
  exit(0);
}
