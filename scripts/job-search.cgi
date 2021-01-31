#!/usr/bin/perl

use BOSS::Config;
use Sayer;

use CGI qw/:standard *table start_ul/;
use Data::Dumper;
use IO::File;
use String::ShellQuote;
use Text::InHTML;
use URI::Escape;

$UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/internal/job-search";

my $config = BOSS::Config->new
  (ConfFile => "/etc/myfrdcsa/config/job-search.conf");

my $baseuri = $config->RCConfig->{BaseURI};
my $projectinfo = $config->RCConfig->{Project};

my $string = $ENV{QUERY_STRING};

# Say(Dumper(\%ENV));

my $query = new CGI($string);

sub Name {
  return "<a href=\"http://frdcsa.org\">FRDCSA</a>/<a href=\"http://posithon.org\">POSI</a> <a href=\"http://frdcsa.onshore.net/frdcsa/internal/job-search\">Job-Search</a> <a href=\"$baseuri\">System</a>";
}

print header,start_html('FRDCSA/POSI Job-Search System'),
  h1(Name()),
  hr();

my @list1 = param();
my @list2 = $query->param();
push @list1, @list2;
if (! scalar @list1) {

  print p("Welcome to the ".Name().".  This system is able to analyze
  your resume and then find matching positions from Craigslist.");

  CitySelectionForm();
}

my @addcities = $query->param('add-cities');
if (scalar @addcities) {
  AddCitiesForm();
}

my @cities = param('cities');
if (scalar @cities) {
  my @uploadedfiles = param('uploaded_file');
  if (scalar @uploadedfiles) {
    my @fhs = upload('uploaded_file');
    foreach my $fh (@fhs) {
      my $filename = shift @uploadedfiles;
      my $cachename = "resume://".remote_host().":".$filename;
      $cachename =~ s/\W/_/g;
      my $outputfile = $UNIVERSAL::systemdir."/data/resumecache/$cachename";
      my $fh2 = new IO::File;
      if ($fh2->open("> $outputfile")) {
	while (<$fh>) {
	  print $fh2 $_;
	}
      }
      $fh2->close;
      ProcessResume
	(
	 Cities => \@cities,
	 Filename => $outputfile,
	);
    }
  } else {
    FileUploadForm
      (Cities => \@cities);
  }
}

sub ProcessResume {
  my %args = @_;
  require PerlLib::ToText;
  my $totext = PerlLib::ToText->new();
  my $res = $totext->ToText(File => $args{Filename});
  # print Dumper($totext,$res,$args{Filename});
  my $textfilename = $args{Filename}.".job-search.txt";
  if (! -f $textfilename) {
    if (exists $res->{Success}) {
      my $fh = IO::File->new();
      if ($fh->open("> $textfilename")) {
	print $fh $res->{Text};
      }
    } else {
      ExitMessage("ERROR: Conversion of file to text failed: ".$res->{FailureReason});
    }
  }
  if (-f $textfilename) {
    # my $c = `cat "$textfilename"`;
    # AnalyzeResumeText(Text => $c);
    # now from here we do the actual job search phase

    print p("Sending resume to resume matching system.  Please note that this may take a while (several minutes) for the data for your cities to load.  It also may fail, silently :(");

    require UniLang::Util::TempAgent;

    my $tempagent = UniLang::Util::TempAgent->new();
    my $message = $tempagent->MyAgent->QueryAgent
      (
       Receiver => "Job-Search",
       Contents => "resume-match",
       Data => {
		Cities => $args{Cities},
		Resumes => [
			    $textfilename,
			   ],
	       },
      );

    foreach my $key (keys %{$message->Data->{Results}}) {
      my $file = $message->Data->{Results}->{$key}->{OutputLocation};
      if (-f $file) {
	my $c = `cat "$file"`;
	$c =~ s/<\/?html>//g;
	print $c;
      }
    }
  }
}

sub AnalyzeResumeText {
  my %args = @_;
  my $contents = $args{Text};
  require Lingua::EN::Fathom;

  my $text = new Lingua::EN::Fathom;

  # $text->analyse_file("sample.txt");

  $accumulate = 1;
  $text->analyse_block($contents,$accumulate);

  $num_chars             = $text->num_chars;
  $num_words             = $text->num_words;
  $percent_complex_words = $text->percent_complex_words;
  $num_sentences         = $text->num_sentences;
  $num_text_lines        = $text->num_text_lines;
  $num_blank_lines       = $text->num_blank_lines;
  $num_paragraphs        = $text->num_paragraphs;
  $syllables_per_word    = $text->syllables_per_word;
  $words_per_sentence    = $text->words_per_sentence;


  %words = $text->unique_words;
  foreach $word ( sort keys %words ) {
    # print p("$words{$word} :$word\n");
  }

  $fog     = $text->fog;
  $flesch  = $text->flesch;
  $kincaid = $text->kincaid;

  print p(b("Readability Analysis"));
  print map{br($_)} split /\n/,$text->report;
}

print end_html;

sub ExitMessage {
  my $message = shift;
  print p($message) if $message;
  print end_html;
  exit(0);
}

sub CitySelectionForm {
  print p(b("City Selection Stage"));

  print p("Please select the cities you wish to include in your
  search.");
  # (Are your cities missing from this list?  Go <a
  # href=\"$baseuri?add-cities=1\">here</a> to request they be added.)");

  print start_form,
    checkbox_group
      (
       -name=>'cities',
       -values => GetAvailableCities(),
      ),
	p,
	  submit,
	    end_form;
}

sub AddCitiesForm {
  print p(b("Add Cities Stage"));
  print p("Please select cities you wish us to also monitor.");

  my $cities = {};
  foreach my $city (@{GetAllCities()}) {
    $cities->{$city} = 1
  }
  foreach my $city (@{GetAvailableCities()}) {
    if (exists $cities->{$city}) {
      delete $cities->{$city};
    }
  }

  print start_form,
    checkbox_group
      (
       -name=>'cities',
       -values => [sort keys %$cities],
      ),
	p,
	  submit,
	    end_form;
}

sub GetAvailableCities {
  my $dir = "$UNIVERSAL::systemdir/data/source/CraigsList";
  my $cities;
  foreach my $item (split /\n/, `ls "$dir"`) {
    if ($item =~ /^([^\.]+)\./) {
      $cities->{$1} = 1;
    }
  }
  return [sort keys %$cities];
}

sub GetAllCities {
  require WWW::Mechanize::Cached;
  require Cache::FileCache;

  my $cacheobj =
    Cache::FileCache->new
	(
	 {
	  namespace => 'job-search',
	  default_expires_in => "1 days",
	  cache_root => "$UNIVERSAL::systemdir/data/FileCache",
	 }
	);

  my $cacher =
    WWW::Mechanize::Cached->new
	(
	 cache => $cacheobj,
	 timeout => 15,
	);

  $cacher->get("http://geo.craigslist.org/iso/us");

  my $cities = {};
  foreach my $link ($cacher->links) {
    my $url = $link->[0];
    if ($url =~ /http:\/\/(\w+).craigslist.org/g) {
      $cities->{$1} = $url;
    }
  }

  return [sort keys %$cities];
}


sub FileUploadForm {
  my %args = @_;
  print p(b("Resume Upload Stage")),
    start_form
      (
       -method => "POST",
       -action => "$baseuri",
       -enctype => &CGI::MULTIPART,
      ),
	p("Please specify your resume file (or a set of files):"),
	  filefield
	    (
	     -name=>'uploaded_file',
	     -size=>40,
	    ),
	      hidden
		(
		 -name => 'cities',
		 -values => $args{Cities},
		),
		  p,
		    submit
		      (
		       -name=>'submit',
		       -value=>'Send',
		      );
}

1;
