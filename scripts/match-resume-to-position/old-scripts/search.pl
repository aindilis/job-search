#!/usr/bin/perl -w

use PerlLib::HTMLConverter;
use Rival::String::Tokenizer2;

use Data::Dumper;
use HTML::Table;
use Search::ContextGraph;

my $conv = PerlLib::HTMLConverter->new;
my $tokenizer = Rival::String::Tokenizer2;

my $cg = Search::ContextGraph->new();

my $cgstoragefile = "contextgraph.cng";

sub GetDoc {
  my $file = shift;
  my $outputfile = "$file.txt";
  if (! -f $outputfile) {
    my $converted = $conv->ConvertFileToTxt
      (
       Input => $file,
       Output => $outputfile,
      );
  }
  my $text = `cat $outputfile`;
  my $doc = {};
  foreach my $token (@{$tokenizer->Tokenize(Text => $text)}) {
    $doc->{lc($token)}++;
  }
  return $doc;
}

if (! -f $cgstoragefile) {
  foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/pittsburgh.craigslist.org | grep -e '\.txt'`) {
    if (-f $file) {
      print "adding: $file\n";
      my $text =
	$cg->add( $file, GetDoc($file) );
    }
  }
  $cg->store($cgstoragefile);
} else {
  $cg = Search::ContextGraph->retrieve( $cgstoragefile );
}

# now add the resume
my $stuff = GetDoc("/var/lib/myfrdcsa/codebases/internal/job-search/data/profiles/Sara-Masters/sara-masters-resume.txt");
$cg->add( "Resume", $stuff);

my ( $docs, $words ) = $cg->mixed_search
  ({
    terms => [ keys %$stuff ]
   });

sub GetTermsForDocument {
  my $doc = shift;
  return [map {s/^T:// and $_} keys %{$cg->{neighbors}{"D:$doc"}}];
}

sub GetSharedTerms {
  my ($a, $b) = @_;
  my $at = GetTermsForDocument($a);
  my $bt = GetTermsForDocument($b);
  # print Dumper([$at,$bt]);
  my $terms = {};
  foreach my $t (@$at) {
    $terms->{$t} = 1;
  }
  my @matches;
  foreach my $t2 (@$bt) {
    push @matches, $t2 if exists $terms->{$t2};
  }
  return [sort @matches];
}

print "<html>\n";
my @table;
foreach my $key (sort {$docs->{$b} <=> $docs->{$a}} keys %$docs) {
  next if ($key eq "Resume");
  my $url = $key;
  $url =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/|http://|;
  $url =~ s/\.txt$//;
  my @row = (sprintf("%1.4f", $docs->{$key}), sprintf("<a href=\"%s\">%s</a><br>",$url,$url), join(", ",@{GetSharedTerms("Resume",$key)}));
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
