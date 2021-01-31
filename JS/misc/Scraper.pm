package JS::Scraper;

use Manager::Dialog qw (Message Choose);
use PerlLib::Collection;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw /  /
  ];

# system responsible for scraping jobs and resumes off online sites

sub init {
  my ($self,%args) = (shift,@_);
  $self->DataDir($args{DataDir} || "data");

  $self->MyCategorizer(AI::Categorizer->new());
  $self->LoadActionDependencies();
}

sub ExtractRecentJobsFromCraigsList {
  my ($self,%args) = (shift,@_);
  my $city = QueryUser($self->Cities
}

sub LoadPositions {
  my ($self,%args) = (shift,@_);
  Message(Message => "Loading positions...");
  my $datadir = $self->DataDir;
  $self->Positions(PerlLib::Collection->new(Type => "JS::Position"));
  $self->Positions->Load;
  my $cnt = 0;
  foreach my $p (split /\n/,`find $datadir/positions`) {
    if (-f $p) {
      my $pos = JS::Position->new(ID => $cnt,
				  StorageFile => $p);
      $self->Positions->Add($pos->ID => $pos);
      $pos->Parse;
      ++$cnt;
    }
  }
  Message(Message => "$cnt positions loaded...");
}

sub LoadProfiles {
  my ($self,%args) = (shift,@_);
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
  my ($self,%args) = (shift,@_);
  $self->Depends
    ({
      "GenerateResume" => ["ProfileInterview"],
      "RecommendedReading" => ["LoadPositions", "CreateProfile"],
     });
}

sub CreateNewProfile {
  my ($self,%args) = (shift,@_);
  my $p = JS::Profile->new();
  $self->Profiles->Add($p->Name => $p);
  $self->CurrentProfile($p);
}

sub SelectProfile {
  my ($self,%args) = (shift,@_);
  $self->CurrentProfile
    ($self->Profiles->Contents->
     {Choose($self->Profiles->Keys)});
}

sub CheckCurrentProfileExists {
  my ($self,%args) = (shift,@_);
  if (defined $self->CurrentProfile) {
    return 1;
  } else {
    Message(Message => "No profile selected");
    return 0;
  }
}

1;
