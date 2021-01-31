#!/usr/bin/perl -w

use BOSS::Config;
use Capability::Tokenize qw(tokenize_treebank);
use Lingua::EN::Tagger;
use NLU::Util::SpanDiff;
use NLU::Util::AnnotationStyle;
use PerlLib::SwissArmyKnife;

# we'll want to use NLU to process the text (eventually, need to add
# more information to it first)

$specification = q(
	--train			Train the system

	--job			Process job postings
	--resume		Process resume postings

	--process <file>	Process the file, extracting the entries
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";

my $debug = 0;
my $tagger = Lingua::EN::Tagger->new;

if (exists $conf->{'--train'}) {
  Train();
}

if (exists $conf->{'--process'}) {
  ProcessText(File => $conf->{'--process'});
}

sub Train {
  my %args = @_;
  if ($conf->{'--job'}) {
    my @results;
    foreach my $file (split /\n/, `ls -1 /var/lib/myfrdcsa/datasets/job600/data/*.tagged`) {
      # convert to mallet format
      print "<$file>\n";
      my $c = read_file($file);
      my $res = Process(Contents => $c);
      if ($res->{Success}) {
	push @results, $res->{Result};
      }
      GetSignalFromUserToProceed();
    }
    my $fh = IO::File->new();
    $fh->open(">job-train.txt");
    print $fh join("\n", @results);
    $fh->close();
    # system "java -cp \"/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar\" cc.mallet.fst.SimpleTagger --train true --model-file job.model job-train.txt";
  }
  if ($conf->{'--resume'}) {
    my @results;
    foreach my $file (split /\n/, `ls -1 /var/lib/myfrdcsa/datasets/resume300/data/*.bwi`) {
      # convert to mallet format
      print "<$file>\n";
      my $c = read_file($file);
      my $res = Process(Contents => $c);
      if ($res->{Success}) {
	push @results, $res->{Result};
      }
      GetSignalFromUserToProceed();
    }
    my $fh = IO::File->new();
    $fh->open(">resume-train.txt");
    print $fh join("\n", @results);
    $fh->close();
    my $command = "java -cp \"/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar\" cc.mallet.fst.SimpleTagger --train true --model-file resume.model resume-train.txt";
    # system $command;
  }
}

sub Process {
  my %args = @_;
  my $c = $args{Contents};
  my $res = InlineToStandoff
    (
     Contents => $c,
     Debug => 0,
    );
  if ($res->{Success}) {
    my @all;
    my @spans;
    my $tagged_text = $tagger->add_tags($res->{Text});
    my @results = $tagged_text =~ /(.*?)<(\w+)>(.*?)<\/(\2)>(.*?)/sg;
    my $i = 0;
    while (@results) {
      my $pre = shift @results;
      my $tagstart = shift @results;
      my $tagged = shift @results;
      my $tagend = shift @results;
      my $post = shift @results;
      if (@all) {
	push @all, " ";
      }
      push @all, $tagged;
      push @spans, [$tagstart,$i,$i+length($tagged)];
      $i += length($tagged) + 1;
      # what we want to do is add this to the features
    }
    # now process the text and spans and get them back
    print Dumper
      (StandoffToInline
       (
	Text => join("", @all),
	Spans => \@spans,
       ));

    # now we have to rectify the text with the tagged text
    # now we need to adjust the spans by the following diff, I don't know immediately how to do that
    my $res2 = ComputeDiffOnSpans
      (
       StartingText => join("", @all),
       StartingSpans => \@spans,
       EndingText => $res->{Text},
      );
    if ($res2->{Success}) {
      print Dumper
	(StandoffToInline
	 (
	  Text => $res2->{EndingText},
	  Spans => $res2->{EndingSpans},
	 ));
    }
  }
  return;
  # go ahead and extract the tags and spans of these items, plus a
  # version of the text without the tags for starters

  # from there, run it through NLU to get more tags

  # instead of using the system as it is here, fix it to use FRDCSA
  # NLU type spans.  Then convert the POS Tagger to generate NLU
  # spans, and make an adaptor to preprocess the text into the span
  # format first.  Then run NLU on the training and processing
  # data, to add features.  Also email the list with everything to
  # see how it's going.  Splice it into words <have the tokenizer
  # work with NLU as well> and simply determine which tags subsume
  # each token, add those as the features.

  my @results = $c =~ /(.*?)<(\w+)>(.*?)<\/(\2)>(.*?)/sg;
  my @items;
  my @text;
  while (@results) {
    my $pre = shift @results;
    my $tagstart = shift @results;
    my $tagged = shift @results;
    my $tagend = shift @results;
    my $post = shift @results;

    foreach my $item (split /\s+/, tokenize_treebank($pre,"perl")) {
      push @items, [$item,'TAG@non-tag'];
      push @text, $item;
    }
    foreach my $item (split /\s+/, tokenize_treebank($tagged,"perl")) {
      push @items, [$item,'TAG@'.$tagstart];
      push @text, $item;
    }
    foreach my $item (split /\s+/, tokenize_treebank($post,"perl")) {
      push @items, [$item,'TAG@non-tag'];
      push @text, $item;
    }
    # what we want to do is add this to the features
  }
  my $text = join(" ", @text);
  my $tagged_text = $tagger->add_tags( $text );
  my @results2 = $tagged_text =~ /(.*?)<(\w+)>(.*?)<\/(\2)>(.*?)/sg;
  my @items2;
  while (@results2) {
    my $pre = shift @results2;
    my $tagstart = shift @results2;
    my $tagged = shift @results2;
    my $tagend = shift @results2;
    my $post = shift @results2;
    foreach my $item (split /\s+/, tokenize_treebank($tagged,"perl")) {
      push @items2, [$item,'TAG@'.$tagstart];
    }
    # what we want to do is add this to the features
  }
  my $start = shift @items;
  my $start2 = shift @items2;
  my @final;
  while (scalar @items and scalar @items2) {
    if ($start->[0] eq $start2->[0]) {
      # merge their properties
      my $word = shift @$start;
      shift @$start2;
      push @final, [$word,@$start2,@$start];
      $start = shift @items;
      $start2 = shift @items2;
    } else {
      # need to see what's next
      print Dumper([$start,$start2]) if $debug;
      # find the next point of agreement, with the smallest ?L2? distance
      my $depth = 0;
      my $continue = 1;
      while ($continue) {
	print "$depth\n" if $debug;
	++$depth;
	my $matchi;
	my $matchj;
	for (my $i = 0; $i < $depth; ++$i) {
	  for (my $j = 0; $j < $depth; ++$j) {
	    print Dumper([$i,$items[$i]->[0],$j,$items2[$j]->[0]]) if $debug;
	    if ($items[$i]->[0] eq $items2[$j]->[0]) {
	      print Dumper([$i,$items[$i]->[0],$j,$items2[$j]->[0]]) if $debug;
	      $matchi = $i;
	      $matchj = $j;
	      $continue = 0;
	    }
	  }
	}
	if (! $continue) {
	  for (0..($matchi-1)) {
	    shift @items;
	  }
	  for (0..($matchj-1)) {
	    shift @items2;
	  }
	  $start = shift @items;
	  $start2 = shift @items2;
	}
      }
    }
  }
  my @result;
  foreach my $wordunit (@final) {
    push @result, join(" ",@$wordunit)."\n";
  }
  print join("",@result)."\n";
  return {
	  Success => 1,
	  Result => join("",@result),
	 };
}

sub ProcessText {
  my %args = @_;
  my $modelfile;
  if ($conf->{'--job'}) {
    $modelfile = "job.model";
  }
  if ($conf->{'--resume'}) {
    $modelfile = "resume.model";
  }
  # have to format the incoming file


  my $c = read_file($args{File});
  my $text = tokenize_treebank($c,"perl");
  my $tagged_text = $tagger->add_tags( $text );
  my @results = $tagged_text =~ /(.*?)<(\w+)>(.*?)<\/(\2)>(.*?)/sg;
  my @items;
  while (@results) {
    my $pre = shift @results;
    my $tagstart = shift @results;
    my $tagged = shift @results;
    my $tagend = shift @results;
    my $post = shift @results;
    push @items, ['TAG@'.$tagstart,$tagged];
  }
  # print Dumper(\@items);
  my $outfile = "out.features";
  my $fh = IO::File->new();
  $fh->open(">$outfile");
  foreach my $item (@items) {
    print $fh join(" ",@$item)."\n";
  }
  $fh->close();
  my $command = "java -cp \"/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar\" cc.mallet.fst.SimpleTagger --model-file ".shell_quote($modelfile)." ".shell_quote($outfile);
  print "$command\n";
  # system "$command > out.results";
  # now join the results
  my $features = read_file("out.features");
  my $results = read_file("out.results");
  $features =~ s/^\s*//s;
  $features =~ s/\s*$//s;
  $results =~ s/^\s*//s;
  $results =~ s/\s*$//s;
  my @fentries = split /\n/, $features;
  my @rentries = split /\n/, $results;
  my $fcnt = scalar @fentries;
  my $rcnt = scalar @rentries;
  print "$fcnt\t$rcnt\n";
  my $lastr = 'TAG@non-tag';
  if ($fcnt == $rcnt) {
    while (@fentries) {
      my $f = shift @fentries;
      my @items = split /\s+/, $f;
      my $word = pop @items;
      my $r = shift @rentries;
      $currenttag = $r;
      $currenttag =~ s/TAG\@//g;
      $currenttag =~ s/\s*$//;
      if ($r ne $lastr) {
	if ($r eq 'TAG@non-tag') {
	  print "</$lasttag>";
	} elsif ($lastr eq 'TAG@non-tag') {
	  print "<$currenttag>";
	} else {
	  print "</$lasttag><$currenttag>";
	}
      }
      print "$word ";
      $lastr = $r;
      $lasttag = $currenttag;
      # print "$f $r\n";
    }
  }
}

# java -cp "/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar" cc.mallet.fst.SimpleTagger --help
