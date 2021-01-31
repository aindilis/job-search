package JS::Manager;

use JS::MinorThird;
use JS::Position;
use JS::Profile;
use JS::Resume;
use JS::SourceManager;
use Manager::Dialog qw (Message Choose);
use PerlLib::Collection;
use PerlLib::Converter;

use AI::Categorizer;
use Data::Dumper;
# use Math::PartialOrder;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Positions Profiles Resumes CoverLetters Correspondences
        Interviews MyCategorizer MyConverter MySourceManager Depends
        DataDir CurrentProfile MyMinorThird /

  ];

sub init {
  my ($self,%args) = @_;
  $self->DataDir($args{DataDir} || "data");
  $self->MySourceManager
    (JS::SourceManager->new
     ());
  $self->MyCategorizer(AI::Categorizer->new());
  $self->MyConverter(PerlLib::Converter->new());
  $self->MyMinorThird(JS::MinorThird->new);
  $self->LoadActionDependencies();
}

sub Execute {
  my ($self,%args) = @_;
  # now we  must ask the person  to select the relevant  items, and then
  # interview them  about each position they  have had in  the past, and
  # try to ensure  that all these items, especially  the important ones,
  # are addressed at least once.

  # $self->LoadPositions;
  $self->LoadProfiles;

  $self->Resumes(PerlLib::Collection->new(Type => "JS::Resume"));
  $self->CoverLetters(PerlLib::Collection->new(Type => "JS::CoverLetter"));
  $self->Correspondences(PerlLib::Collection->new(Type => "JS::Correspondence"));
  $self->Interviews(PerlLib::Collection->new(Type => "JS::Interview"));
}

sub UpdatePositions {
  my ($self,%args) = @_;
  my $positions = $self->MySourceManager->Search(Search => ".");
  foreach my $pos (@$positions) {
    $self->Positions->Add($pos->ID => $pos);
  }
  $self->ParsePositions;
  $self->Positions->Save;
}

sub ParsePositions {
  my ($self,%args) = @_;
  foreach my $p ($self->Positions->Values) {
    my $id = $p->ID;
    Message(Message => "Parsing ".$p->ID);
    $p->Parse(%args);
  }
}

sub LoadPositions {
  my ($self,%args) = @_;
  Message(Message => "Loading positions...");

  # nothing to be done here for technical reasons, sources are loaded when searched
  $self->Positions
    (PerlLib::Collection->new
     (Type => "JS::Position",
      StorageFile => "$UNIVERSAL::systemdir/data/positions.pl"));

  $self->Positions->Load;

  my $positions = $self->MySourceManager->Search(Search => ".");
  if ($self->Positions->IsEmpty or $self->Positions->Count != scalar @$positions) {
    $self->UpdatePositions;
  }
}

sub LoadProfiles {
  my ($self,%args) = @_;
  my $datadir = $self->DataDir;
  Message(Message => "Loading profiles...");
  $self->Profiles(PerlLib::Collection->new(Type => "JS::Profile"));
  $self->Profiles->Load;
  my $cnt = 0;
  foreach my $p (map "$datadir/profiles/$_", split /\n/,`ls $datadir/profiles`) {
    my $pro = JS::Profile->new(ProfileDir => $p);
    $self->Profiles->Add($pro->Name => $pro);
    $pro->LoadResumes;
    ++$cnt;
  }
  Message(Message => "$cnt profiles loaded...");
}

sub LoadActionDependencies {
  my ($self,%args) = @_;
  $self->Depends
    ({
      "GenerateResume" => ["ProfileInterview"],
      "RecommendedReading" => ["LoadPositions", "CreateProfile"],
     });
}

sub CreateNewProfile {
  my ($self,%args) = @_;
  my $p = JS::Profile->new();
  $self->Profiles->Add($p->Name => $p);
  $self->CurrentProfile($p);
}

sub SelectProfile {
  my ($self,%args) = @_;
  $self->CurrentProfile
    ($self->Profiles->Contents->
     {Choose($self->Profiles->Keys)});
}

sub CheckCurrentProfileExists {
  my ($self,%args) = @_;
  if (defined $self->CurrentProfile) {
    return 1;
  } else {
    Message(Message => "No profile selected");
    return 0;
  }
}

1;
