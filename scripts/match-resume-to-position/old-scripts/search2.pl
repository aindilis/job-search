#!/usr/bin/perl -w

use PerlLib::HTMLConverter;

use Data::Dumper;
use HTML::Table;
use Lingua::EN::StopWords qw(%StopWords);
use Lingua::EN::Tagger;

my $tagger = Lingua::EN::Tagger->new;
my $conv = PerlLib::HTMLConverter->new;
my $tokenizer = Rival::String::Tokenizer2;

my $storagefile = "storage-chicago.dat";
my $city = "chicago";
my $documents = {};

sub GetDoc {
  my $file = shift;
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

if (! -f $storagefile) {
  foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/$city.craigslist.org`) {
    if (-f $file) {
      print "adding: $file\n";
      $documents->{$file} = GetDoc($file);
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

# now build the term index, so that we can find similar documents by terms
print "Building term index\n";
my $terms;
foreach my $title (keys %$documents) {
  foreach my $term (keys %{$documents->{$title}}) {
    $terms->{$term}->{$title} = 1;
  }
}
print "Done\n";

# now we need to find similar documents
my $res = FindSimilar
  ("/var/lib/myfrdcsa/codebases/internal/job-search/data/profiles/Peter-Coons/peter-coons-resume.txt");

sub FindSimilar {
  my $file = shift;
  my $doc = GetDoc($file);
  my $score = {};
  my $sharedterms = {};
  foreach my $term (keys %$doc) {
    foreach my $title (keys %{$terms->{$term}}) {
      $score->{$title} += $documents->{$title}->{$term} * $doc->{$term};
      $sharedterms->{$title}->{$term} = 1;
    }
  }
  return {
	  Scores => $score,
	  SharedTerms => $sharedterms,
	 };
}


print "<html>\n";
my @table;
foreach my $title (sort {$res->{Scores}->{$b} <=> $res->{Scores}->{$a}} keys %{$res->{Scores}}) {
  my $url = $title;
  $url =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/|http://|;
  $url =~ s/\.txt$//;
  my @row = (sprintf("%1.4f", $res->{Scores}->{$title}), sprintf("<a href=\"%s\">%s</a><br>",$url,$url), join(", ",sort keys %{$res->{SharedTerms}->{$title}}));
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
print join("\n",
	   (
	    "<html>",
	    "<h3>Recommended Positions</h3>",
	    $htmltable->getTable,
	    "</html>",
	   )
	  );
