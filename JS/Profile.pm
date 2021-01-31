package JS::Profile;

use Manager::Dialog qw (Message QueryUser Choose ChooseByProcessor SubsetSelect);
use MyFRDCSA qw (ConcatDir);
use PerlLib::Collection;
use PerlLib::TFIDF;

use Data::Dumper;
use Lingua::EN::Keywords;
use String::Similarity;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / ID ProfileDir ResumeDir MyManager MySkillAreas MyResumes
         MyPositions Capabilities Satisfies PositionRating Name
         FirstName LastName CurrentResume Selections TFIDF
         /

  ];

sub init {
  my ($self,%args) = @_;

  $self->ID($args{ID});

  $self->PositionRating({});
  $self->Capabilities({});
  $self->Satisfies({});

  if ($args{ProfileDir} and -d $args{ProfileDir}) {
    my $dir = $args{ProfileDir};
    if ($dir =~ /.*\/(.*)-(.*)/) {
      $self->FirstName($1);
      $self->LastName($2);
    } else {
      print "error\n";
    }
  } else {
    $self->FirstName($args{FirstName} || QueryUser("FirstName?"));
    $self->LastName($args{LastName} || QueryUser("LastName?"));
  }

  $self->Name($self->FirstName."-".$self->LastName);

  # load profile
  $self->ProfileDir(ConcatDir("data/profiles",$self->Name));
  if (! -d $self->ProfileDir) {
    system "mkdirhier ".$self->ProfileDir;
  }
  $self->Selections
    (PerlLib::Collection->new
     (Type => "PerlLib::Collection"));
  $self->Selections->Contents({});
}

sub LoadResumes {
  my ($self,%args) = @_;
  Message(Message => "Loading resumes for ".$self->Name."...");
  $self->ResumeDir(ConcatDir($self->ProfileDir,"resumes"));
  my $resumedir = $self->ResumeDir;
  $self->MyResumes(PerlLib::Collection->new(Type => "JS::Resume"));
  $self->MyResumes->Load;
  if (! -d $resumedir) {
    system "mkdir $resumedir";
  }
  my $cnt = 0;
  # foreach my $f (map "$resumedir/$_", split /\n/,`ls $resumedir/*.xml`) {
  foreach my $f (split /\n/,`ls $resumedir/*.xml`) {
    if (-f $f) {
      my $t = $f;
      $t =~ s/\.xml$//;
	my $resume = JS::Resume->new(ID => $cnt++,
				     StorageFile => $f,
				     TargetDir => $t);
      $self->MyResumes->Add($resume->ID => $resume);
      $resume->ParseResumeXML;
      foreach my $c (@{$resume->Capabilities}) {
	$self->Capabilities->{$c} = $resume->ID;
      }
    }
  }
  Message(Message => "$cnt resumes loaded...");
}

sub CreateNewResume {
  my ($self,%args) = @_;
  my $templateresume = "data/templates/resume.xml";
  my $resumedir = $self->ResumeDir;
  my $max = 0;
  foreach my $x (split /\n/,`ls $resumedir/*.xml`) {
    if ($x =~ /\/([0-9]+)\.xml$/) {
      if ($max < $1) {
	$max = $x;
      }
    }
  }
  system "cp $templateresume $resumedir/$max.xml";
  my $resume = JS::Resume->new(StorageFile => $f);
  $self->MyResumes->Add($resume->ID => $resume);
}

sub Interview {
  my ($self,%args) = @_;
  # interview the user to ascertain their skills (heck, even use clear
  # here for quizzing)

  # Job search ought to interview  the user, perhaps using an improved
  #u templated  dialog  system from  audience,  to  extract the  user's
  # skills.  (You see I'm really forgetting the proper role of each of
  # these systems.
}

sub ProcessTextsDescribingCandidate {
  my ($self,%args) = @_;
  my $kws = {};
  foreach my $f (@{$args{Files}}) {
    if (-e $f) {
      my $c = `cat "$f"`;
      foreach my $kw (keywords($c)) {
	$kws->{$kw}++;
      }
    }
  }
  # now have the user select whether they know these things
  print Dumper($kws);
}

sub SelectPositions {
  my ($self,%args) = @_;
  # first make sure to load all positions, then begin reviewing them
  $UNIVERSAL::js->MyManager->LoadPositions;
  # $UNIVERSAL::js->MyManager->MyMinorThird->ExtractPositionInformation;

  Message(Message => "Creating new selection");
  my $title = "applications"; # QueryUser("What should this selection be called?");
  my $selection = PerlLib::Collection->new
    (Type => "JS::Position");
  $selection->Contents({});
  $self->Selections->Add($title => $selection);
  $self->MyPositions($selection);
  $self->PositionRelevance;
  $self->MatchRequirements;

  # make sure they are all parsed?
  # what about automatically computing this?
  foreach my $pos ($UNIVERSAL::js->MyManager->Positions->Values) {
    $selection->Add($pos->ID => $pos);
  }
}

sub PositionRelevance {
  my ($self,%args) = @_;
  $self->PositionRelevanceTFIDF(%args);
}

sub PositionRelevanceOrig {
  my ($self,%args) = @_;
  Message(Message => "Rating positions...");
  foreach my $p ($UNIVERSAL::js->MyManager->Positions->Values) {
    my $id = $p->ID;
    $p->ParseSimple;
    $p = $UNIVERSAL::js->MyManager->Positions->Contents->{$id};
  }
  $UNIVERSAL::js->MyManager->Positions->Save;
  foreach my $p ($UNIVERSAL::js->MyManager->Positions->Values) {
    Message(Message => "Processing ".$p->ID);
    if (! $self->PositionRating->{$p->ID}) {
      my $rating;
      foreach my $r (@{$p->Requirements}) {
	my $similarity = {};
	foreach my $i (keys %{$self->Capabilities}) {
	  $similarity->{$i} = similarity($r,$i);
	}
	# take a convergent exponential decay summation of these or
	# something
	my $count = 0;
	foreach my $i
	  (sort {$similarity->{$a} <=> $similarity->{$b}}
	   keys %{$self->Capabilities}) {
	    $rating += $similarity->{$i} / (2 ** $count++);
	  }
      }
      $self->PositionRating->{$p->ID} = $rating;
    }
  }
  $self->PrintRelevance;
}

sub PositionRelevanceTFIDF {
  my ($self,%args) = @_;
  Message(Message => "Rating positions...");

  # just do tfidf for now
  my $entries = {};
  $entries->{"profile"} = join("\n",keys %{$self->Capabilities});
  # print Dumper($self->Capabilities);
  foreach my $pos ($UNIVERSAL::js->MyManager->Positions->Values) {
    $entries->{$pos->ID} = $pos->Contents;
  }
  $self->TFIDF(PerlLib::TFIDF->new
	       (Entries => $entries));

  foreach my $p ($UNIVERSAL::js->MyManager->Positions->Values) {
    if (! $self->PositionRating->{$p->ID}) {
      $self->PositionRating->{$p->ID} =
	$self->TFIDF->ComputeDocumentSimilarity("profile",$p->ID);
    }
  }
  $self->PrintRelevance;
}

sub PrintRelevance {
  my ($self,%args) = @_;
  foreach my $p (sort {$self->PositionRating->{$b->ID} <=>
			 $self->PositionRating->{$a->ID}}
		 $UNIVERSAL::js->MyManager->Positions->Values) {
    print sprintf("%10f\t%s\n",$self->PositionRating->{$p->ID},$p->StorageFile);
  }
}

sub MatchRequirements {
  my ($self,%args) = @_;
  Message(Message => "Matching requirements...");
  # foreach requirement  in position - need  to find 1  item in resume
  # that satisfies requirement (as best as possible if not fully)
  foreach my $p
    (sort {$self->PositionRating->{$b->ID} <=> $self->PositionRating->{$a->ID}}
     $self->MyPositions->Values) {
      foreach my $r (@{$p->Requirements}) {
	my $similarity = {};
	foreach my $i (keys %{$self->Capabilities}) {
	  $similarity->{$i} = similarity($r,$i);
	}
	# why not automatically select a few and just go with these as a default
	my $selection = {};
	if (1) {
	  my @sorted = sort {$similarity->{$a} <=> $similarity->{$b}}
	    keys %{$self->Capabilities};
	  foreach my $i (@sorted) {
	      if ($similarity->{$i} > 0.5) {
		$selection->{$i} = 1;
	      }
	    }
	  if (! scalar keys %$selection) {
	    $selection->{$sorted->[0]} = 1;
	  }
	}
	# now choose them, in order
	print "REQ: $r\n";
	my @matches = SubsetSelect
	  (Set => [keys %$similarity],
	   Selection => $selection);
	$self->Satisfies->{$r} = [@matches];
      }
    }
  print Dumper($self->Satisfies);
}

sub GenerateResumesForSelectedPositions {
  my ($self,%args) = @_;

  # for now, just do one at a time?
  foreach my $pos ($self->Selected->Values) {
    my $r = JS::Resume->new
      (ApplicablePositions => [$pos->ID]);
  }

  # RELATED READING
  # possibly add relevant reading to topics

  # use a relevance model to sort the reading

  # if there  are books that have  only been read,  list a percentage,
  # chapters, etc.

  # RELATED PROJECTS
  # add projects
}

sub ProcessResume {
  my ($self,%args) = @_;
  Message(Message => "Processing resume...");
  my $res = JS::Resume->new(StorageFile => "data/resumes/resume.xml");

  $res->Render(TargetDir => $self->ProfileDir);
}

sub RecommendReading {
  my ($self,%args) = @_;
  Message(Message => "Recommending reading...");

  # now generate a list of reading that should be undertaken before
  # the person can be thought to know about various skill sets
}

sub SelectResumeOld {
  my ($self,%args) = @_;
  $self->CurrentResume
    ($self->MyResumes->Contents->
     {Choose($self->MyResumes->Keys)});
}

sub SelectResume {
  my ($self,%args) = @_;
  my $selectedresume = ChooseByProcessor
    (
     Processor => sub {$_->StorageFile},
     Values => [sort {$a->StorageFile cmp $b->StorageFile} $self->MyResumes->Values],
    );
  $self->CurrentResume
    ($self->MyResumes->Contents->{$selectedresume->[0]->ID});
}

sub CheckCurrentResumeExists {
  my ($self,%args) = @_;
  if (defined $self->CurrentResume) {
    return 1;
  } else {
    Message(Message => "No resume selected");
    return 0;
  }
}

1;
