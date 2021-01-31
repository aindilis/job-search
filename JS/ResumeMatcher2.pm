package JS::ResumeMatcher;

use BOSS::Config;
use Capability::NER;
use PerlLib::HTMLConverter;
use Sayer;

use Data::Dumper;
use HTML::Table;
use Lingua::EN::StopWords qw(%StopWords);
use Lingua::EN::Tagger;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw/ Cities Resumes MyTagger MyConverter StorageFiles MyNER MySayer Documents Phrases /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyTagger(Lingua::EN::Tagger->new);
  $self->MyConverter(PerlLib::HTMLConverter->new);
  $self->Phrases({});

  $self->Documents({});
  $self->MyNER
    (Capability::NER->new
     (Engine => "Stanford"));
  $self->MySayer
    (DBName => "sayer_job_search");
  $self->StorageFiles({});
}

sub MatchResumes {
  my ($self,%args) = @_;
  my $errors = {};
  $self->LoadCities
    (
     Cities => $args{Cities},
    );
  # exit unless resumes and cities
  if (! scalar @{$self->Cities}) {
    $errors->{"No cities"} = 1;
  }
  $self->Resumes($args{Resumes} || []);
  if (! scalar @{$self->Resumes}) {
    $errors->{"No resumes"} = 1;
  }

  if (scalar keys %$errors) {
    print "Errors, can't match resumes.\n";
    return $errors;
  }

  print Dumper({CitiesLoaded => [keys %{$self->Documents}]});

  print "Matching Resumes\n";
  my $results = {};
  my $resumeurl = "http://posithon.org";
  foreach my $resumefile (@{$self->Resumes}) {
    my $date = `date "+%Y%m%d-%H%M%S"`;
    chomp $date;
    my $outputlocation = $resumefile;
    $outputlocation =~ s/^.*\///;
    $outputlocation = "$UNIVERSAL::systemdir/data/resumeanalysis/$outputlocation-$date.html";

    print Dumper
      ($self->GetDoc
       (
	File => $resumefile,
	Type => "resume",
       ));
    print "Done\n";
    # now we need to find similar documents
    $self->ProcessResume
      (
       User => $args{User},
       ResumeFile => $resumefile,
       ResumeURL => $resumeurl,
       OutputLocation => $outputlocation,
       Cities => $args{Cities},
      );
    $results->{$resumefile} = {
			       OutputLocation => $outputlocation,
			      };
  }
  return $results;
}

sub LoadCities {
  my ($self,%args) = @_;
  $self->Cities($args{Cities} || []);

  if (! scalar @{$self->Cities}) {
    print "No cities!\n";
    return;
  }
  foreach my $city (@{$self->Cities}) {
    print "Loading city: $city\n";
    if (! exists $self->Documents->{$city}) {
      $self->StorageFiles->{$city} = "$UNIVERSAL::systemdir/data/resumeanalysis/storage-$city.dat";
      my $mustload = 0;
      if (-f $self->StorageFiles->{$city}) {
	# load $self->StorageFiles->{$city}
	my $storagefile = $self->StorageFiles->{$city};
	my $c = `cat "$storagefile"`;
	$VAR1 = undef;
	eval $c;
	$self->Documents->{$city} = $VAR1;
	$VAR1 = undef;

	# now check that we don't have to load
	my @files = split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/$city.craigslist.org | grep -vE '\.txt' | grep -E '\.html' | grep -vE '/res/'`;
	# print Dumper(\@files);
	if (exists $args{Tiny}) {
	  @files = splice @files,0,100;
	}
	my $matches = {};
	foreach my $file (keys %{$self->Documents->{$city}}) {
	  $matches->{$file}++;
	}
	foreach my $file (@files) {
	  $matches->{$file}++;
	}
	foreach my $key (keys %$matches) {
	  if ($matches->{$key} != 2) {
	    print "MISMATCH: $key\n";
	    $mustload = 1;
	    # last;
	  }
	}
      } else {
	$mustload = 1;
      }
      if ($mustload) {
	print "Must load!\n";
	my $old = $self->Documents->{$city};
	$self->Documents->{$city} = {};
	my @files = split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList/$city.craigslist.org | grep -vE '\.txt' | grep -vE '/res/'`;
	if (exists $args{Tiny}) {
	  @files = splice @files,0,100;
	}
	foreach my $file (@files) {
	  if (-f $file) {
	    if (exists $old->{$file}) {
	      print "using existing: $file\n";
	      $self->Documents->{$city}->{$file} = $old->{$file};
	    } else {
	      print "adding: $file\n";
	      $self->Documents->{$city}->{$file} =
		$self->GetDoc
		  (
		   File => $file,
		  );
	    }
	  }
	}
	my $OUT;
	open (OUT,">".$self->StorageFiles->{$city}) or die "Cannot write Storage file: ".$self->StorageFiles->{$city}."!\n";
	print OUT Dumper($self->Documents->{$city});
	close(OUT);
      }
      # now build the phrase index, so that we can find similar documents by phrases

      print "Building phrase index\n";
      foreach my $title (keys %{$self->Documents->{$city}}) {
	foreach my $phrase (keys %{$self->Documents->{$city}->{$title}}) {
	  $self->Phrases->{$phrase}->{$title} = 1;
	}
      }
      # remove phrases that are in every document
      my $num_docs = scalar keys %{$self->Documents->{$city}};
      foreach my $phrase (keys %{$self->Phrases}) {
	if ($num_docs == scalar keys %{$self->Phrases->{$phrase}}) {
	  delete $self->Phrases->{$phrase};
	}
      }
    }
  }
}

sub ProcessResume {
  my ($self,%args) = @_;
  my $file = $args{ResumeFile};
  my $resumeurl = $args{ResumeURL};
  my $outputlocation = $args{OutputLocation};

  my $res = $self->FindSimilar
    (
     File => $file,
     Cities => $args{Cities},
    );
  my $OUT;
  open(OUT,">$outputlocation") or die "Cannot write resume analysis results to $outputlocation!\n";
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
		  "for ".($args{User} || "unknown user"),
		  $htmltable->getTable,
		  "</html>",
		 )
		);

  close(OUT);
}

sub FindSimilar {
  my ($self,%args) = @_;
  my $file = $args{File};
  my $doc = $self->GetDoc
    (
     File => $file,
     Type => "resume",
    );
  my $score = {};
  my $sharedphrases = {};
  foreach my $phrase (keys %$doc) {
    # print Dumper([keys %{$self->Phrases->{$phrase}}]); # safety
    foreach my $title (keys %{$self->Phrases->{$phrase}}) {
      foreach my $city (@{$args{Cities}}) {
	if (exists $self->Documents->{$city}->{$title}->{$phrase} and
	    exists $doc->{$phrase}) {
	  $score->{$title} += $self->Documents->{$city}->{$title}->{$phrase} * $doc->{$phrase};
	} else {
	  $score->{$title} += 0;
	}
	$sharedphrases->{$title}->{$phrase} = 1;
      }
    }
  }
  return {
	  Scores => $score,
	  SharedPhrases => $sharedphrases,
	 };
}

sub GetDoc {
  my ($self,%args) = @_;
  my $file = $args{File};
  my $debug = $args{Debug} || ($args{Type} eq "resume");
  my $text = "";
  if ($file =~ /\.txt$/) {
    if (-f $file) {
      $text = `cat $file`;
    }
  } else {
    my $outputfile = "$file.txt";
    if (! -f $outputfile) {
      print "Converting to text\n" if $debug;
      my $converted = $self->MyConverter->ConvertFileToTxt
	(
	 Input => $file,
	 Output => $outputfile,
	);
    }
    $text = `cat $outputfile`;
  }

  if (0 and exists $args{Type} and $args{Type} eq "resume") {
    print "Performing named entity detection\n" if $debug;
    my $nerresult = $self->MyNER->NERExtract(Text => $text);
    foreach my $entry (@$nerresult) {
      my $string = join(" ",@{$entry->[0]});
      $string =~ s/(\W)/\\$1/g;
      $text =~ s/$string/ /g;
    }
  }

  print "Getting noun phrases\n" if $debug;
  my $tagged_text = $self->MyTagger->add_tags( $text );
  my %nps = $self->MyTagger->get_noun_phrases($tagged_text);

  print "Building Dictionary\n" if $debug;
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

# ################################################################################
# # miscellaneous

# sub ProcessCraigslistResumes {
#   my ($self,%args) = @_;
#   print "Iterating over resumes\n";
#   foreach my $file (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data | grep -vE '\.txt'`) {
#     if (-f $file) {
#       print "processing resume: $file\n";

#       my $outputlocation = $file;
#       $outputlocation =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data/||;
#       $outputlocation =~ s|/|-|g;
#       $outputlocation = "/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/results/$outputlocation";

#       my $resumeurl = $file;
#       $resumeurl =~ s|/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data/|http://|;
#       $resumeurl =~ s/\.txt$//;
#       $self->ProcessResume
# 	(
# 	 ResumeFile => $file,
# 	 ResumeURL => $resumeurl,
# 	 OutputLocation => $outputlocation,
# 	);
#     }
#   }
# }

1;
