#!/usr/bin/perl -w

use BOSS::Config;
use Capability::Tokenize qw(tokenize_treebank);
use Lingua::EN::Tagger;
use PerlLib::SwissArmyKnife;

$specification = q(
	--train			Train the system

	--job			Process job postings
	--resume		Process resume postings

	--process <file>	Process the file, extracting the entries

	--annotate		Annotate a sample job posting corpus
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

if (exists $conf->{'--annotate'}) {
  # run on unlabelled files
  RunOnUnlabelledFiles();
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
      # GetSignalFromUserToProceed();
    }
    my $fh = IO::File->new();
    $fh->open(">job-train.txt");
    print $fh join("\n", @results);
    $fh->close();
    system "java -cp \"/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar\" cc.mallet.fst.SimpleTagger --train true --model-file job.model job-train.txt";
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
      # GetSignalFromUserToProceed();
    }
    my $fh = IO::File->new();
    $fh->open(">resume-train.txt");
    print $fh join("\n", @results);
    $fh->close();
    my $command = "java -cp \"/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar\" cc.mallet.fst.SimpleTagger --train true --model-file resume.model resume-train.txt";
    system $command;
  }
}

sub Process {
  my %args = @_;
  my $c = $args{Contents};
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
  system "$command > out.results";
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

sub RunOnUnlabelledFiles {
  my %args = @_;
  foreach my $file (split /\n/, `ls -1 /var/lib/myfrdcsa/codebases/internal/job-search/data/sof/*.txt`) {
    print "<$file>\n";
    my $c = read_file($file);
    my $c2 = Clean(Contents => $c);
    my $fh = IO::File->new();
    $fh->open(">sample.input.txt");
    print $fh $c2;
    $fh->close();
    ProcessText(File => "sample.input.txt");
    GetSignalFromUserToProceed;
  }
}

sub Clean {
  my %args = @_;
  my $c = $args{Contents};
  $c =~ s/^.*?Reply to//s;
  $c =~ s/Location:.*?$//s;
  my @lines = split /[\n\r]/, $c;
  shift @lines;
  shift @lines;
  my @lines2;
  foreach my $line (@lines) {
    if ($line =~ /\S/) {
      push @lines2, $line;
    }
  }
  $c2 = join("\n",@lines2);
  $c2 =~ s/^\s*//s;
  $c2 =~ s/\s*$//s;
  $c2 =~ s/[[:^ascii:]]/ /g;
  return $c2;
}

# java -cp "/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/class:/var/lib/myfrdcsa/sandbox/mallet-2.0.5/mallet-2.0.5/lib/mallet-deps.jar" cc.mallet.fst.SimpleTagger --help
