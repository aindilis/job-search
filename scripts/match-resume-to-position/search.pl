#!/usr/bin/perl -w

use BOSS::Config;
use Capability::NER;
# use Manager::Dialog qw(SubsetSelect);
use PerlLib::HTMLConverter;

use Data::Dumper;
use HTML::Table;
use Lingua::EN::StopWords qw(%StopWords);
use Lingua::EN::Tagger;

$specification = q(
	-c <cities>...	Cities
	-r <resume>	Resume

  );

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;

my $tagger = Lingua::EN::Tagger->new;
my $conv = PerlLib::HTMLConverter->new;
my $tokenizer = Rival::String::Tokenizer2;

if (! exists $conf->{'-c'}) {
  die "no cities!\n";
}

my @cities = @{$conf->{'-c'}};
my $storagefile = "storage-".join("-",@cities).".dat";
my $documents = {};

my $resumeurl = "http://frdcsa.org/";
my $resumefile = $conf->{'-r'} or die "no resume!\n";

my $date = `date "+%Y%m%d-%H%M%S"`;
chomp $date;
my $outputlocation = $resumefile;
$outputlocation =~ s/^.*\///;
$outputlocation = "/var/www/job-search/results/$outputlocation-$date.html";

my $ner = Capability::NER->new(Engine => "Stanford");

print Dumper
  (GetDoc
   (
    File => $resumefile,
    Type => "resume",
   ));

if (! -f $storagefile) {
  foreach my $city (@cities) {
    foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/$city.craigslist.org | grep -vE '\.txt'`) {
      if (-f $file) {
	print "adding: $file\n";
	$documents->{$file} =
	  GetDoc
	    (File => $file);
      }
    }
  }
  my $OUT;
  open (OUT,">$storagefile") or die "ouch!\n";
  print OUT Dumper($documents);
  close(OUT);
} else {
  # load $storagefile
  my $c = `cat $storagefile`;
  $VAR1 = undef;
  eval $c;
  $documents = $VAR1;
  $VAR1 = undef;
}

# now build the phrase index, so that we can find similar documents by phrases
print "Building phrase index\n";
my $phrases = {};
foreach my $title (keys %$documents) {
  foreach my $phrase (keys %{$documents->{$title}}) {
    $phrases->{$phrase}->{$title} = 1;
  }
}
# remove phrases that are in every document
my $num_docs = scalar keys %$documents;
foreach my $phrase (keys %$phrases) {
  if ($num_docs == scalar keys %{$phrases->{$phrase}}) {
    delete $phrases->{$phrase};
  }
}

print "Done\n";

# now we need to find similar documents

ProcessResume
  (
   ResumeFile => $resumefile,
   ResumeURL => $resumeurl,
   OutputLocation => $outputlocation,
  );

sub ProcessCraigslistResumes {
  print "Iterating over resumes\n";
  foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data | grep -vE '\.txt'`) {
    if (-f $file) {
      print "processing resume: $file\n";

      my $outputlocation = $file;
      $outputlocation =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data/||;
      $outputlocation =~ s|/|-|g;
      $outputlocation = "/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/results/$outputlocation";

      my $resumeurl = $file;
      $resumeurl =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data/|http://|;
      $resumeurl =~ s/\.txt$//;
      ProcessResume
	(
	 ResumeFile => $file,
	 ResumeURL => $resumeurl,
	 OutputLocation => $outputlocation,
	);
    }
  }
}

sub ProcessResume {
  my %args = @_;
  my $file = $args{ResumeFile};
  my $resumeurl = $args{ResumeURL};
  my $outputlocation = $args{OutputLocation};

  my $res = FindSimilar($file);
  my $OUT;
  open(OUT,">$outputlocation") or die "ouch!\n";
  my @table;
  foreach my $title (sort {$res->{Scores}->{$b} <=> $res->{Scores}->{$a}} keys %{$res->{Scores}}) {
    my $url = $title;
    $url =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/|http://|;
    $url =~ s/\.txt$//;
    my @row = (sprintf("%1.4f", $res->{Scores}->{$title}), sprintf("<a href=\"%s\">%s</a><br>",$url,$url), join(", ",sort keys %{$res->{SharedPhrases}->{$title}}));
    push @table, \@row;
  }
  my $htmltable = HTML::Table->new
    (
     -align=>'center',
     -border=>1,
     # -bgcolor=>'lightblue',
     # -spacing=>0,
     # -padding=>0,
     # -style=>'color: blue',
     -evenrowclass=>'even',
     -oddrowclass=>'odd',
     -data=> \@table,
    );
  print OUT join("\n",
		 (
		  "<html>",
		  "<h3>Recommended Positions</h3>",
		  "for <a href=\"$resumeurl\">$resumeurl</a><br>",
		  $htmltable->getTable,
		  "</html>",
		 )
		);

  close(OUT);
}

sub FindSimilar {
  my $file = shift;
  my $doc = GetDoc
    (File => $file,
     Type => Resume);
  my $score = {};
  my $sharedphrases = {};
  foreach my $phrase (keys %$doc) {
    foreach my $title (keys %{$phrases->{$phrase}}) {
      $score->{$title} += $documents->{$title}->{$phrase} * $doc->{$phrase};
      $sharedphrases->{$title}->{$phrase} = 1;
    }
  }
  return {
	  Scores => $score,
	  SharedPhrases => $sharedphrases,
	 };
}

sub GetDoc {
  my %args = @_;
  my $file = $args{File};
  my $text = "";
  if ($file =~ /\.txt$/) {
    if (-f $file) {
      $text = `cat $file`;
    }
  } else {
    my $outputfile = "$file.txt";
    if (! -f $outputfile) {
      my $converted = $conv->ConvertFileToTxt
	(
	 Input => $file,
	 Output => $outputfile,
	);
    }
    $text = `cat $outputfile`;
  }

  if ($args{Type} eq "resume") {
    # do named entity detection here
    my $nerresult = $ner->NERExtract(Text => $text);
    foreach my $entry (@$nerresult) {
      my $string = join(" ",@{$entry->[0]});
      $string =~ s/(\W)/\\$1/g;
      $text =~ s/$string/ /g;
    }
  }

  # get_noun_phrases
  my $tagged_text = $tagger->add_tags( $text );
  my %nps = $tagger->get_noun_phrases($tagged_text);

  my $doc = {};
  foreach my $origtoken (keys %nps) {
    my $token = $origtoken;
    $token =~ s/\W/ /g;
    $token =~ s/\s+/ /g;
    $token =~ s/^\s+//g;
    $token =~ s/\s+$//g;
    if (! exists $StopWords{$token}) {
      $doc->{lc($token)} = $nps{$origtoken};
    }
  }
  return $doc;
}
