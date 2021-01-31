package JS::SourceManager;

use Manager::Dialog qw(Message SubsetSelect);
use PerlLib::Collection;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw { ListOfSources MySources }

  ];

sub init {
  my ($self,%args) = (shift,@_);
  Message(Message => "Initializing sources...");
  my $dir = "$UNIVERSAL::systemdir/JS/Source";
  my @names = sort map {$_ =~ s/.pm$//; $_} grep(/\.pm$/,split /\n/,`ls $dir`);
  # my @names = qw(AptCache);
  $self->ListOfSources(\@names);
  $self->MySources
    (PerlLib::Collection->new
     (Type => "JS::Source"));
  $self->MySources->Contents({});
  foreach my $name (@{$self->ListOfSources}) {
    Message(Message => "Initializing JS/Source/$name.pm...");
    require "$dir/$name.pm";
    my $s = "JS::Source::$name"->new();
    $self->MySources->Add
      ($name => $s);
  }
}

sub UpdateSources {
  my ($self,%args) = (shift,@_);
  Message(Message => "Updating sources...");
  my @keys;
  if (defined $args{Sources} and ref $args{Sources} eq "ARRAY") {
    @keys = @{$args{Sources}};
  }
  if (!@keys) {
    @keys = $self->MySources->Keys;
  }
  foreach my $key (@keys) {
    Message(Message => "Updating $key...");
    $self->MySources->Contents->{$key}->UpdateSource;
  }
}

sub LoadSources {
  my ($self,%args) = (shift,@_);
  Message(Message => "Loading sources...");
  my @keys;
  if (defined $args{Sources} and ref $args{Sources} eq "ARRAY") {
    @keys = @{$args{Sources}};
  }
  if (!@keys) {
    @keys = $self->MySources->Keys;
  }
  foreach my $key (@keys) {
    Message(Message => "Loading $key...");
    $self->MySources->Contents->{$key}->LoadSource;
  }
}

sub Search {
  my ($self,%args) = (shift,@_);
  my @ret;
  foreach my $pos (sort @{$self->SearchSources
			    (Criteria => ($args{Criteria} or
			     $args{Search} ? {Any => $args{Search}} : $self->GetSearchCriteria),
			     Search => $args{Search},
			     Sources => $args{Sources})}) {
    push @ret, $pos;
  }
  @ret = sort {$a->ID cmp $b->ID} @ret;
  return \@ret;
}

sub Choose {
  my ($self,%args) = (shift,@_);
  $positionmapping = {};
  foreach my $pos
    (sort @{$self->SearchSources
	      (Criteria => $self->GetSearchCriteria,
	       Sources => $args{Sources})}) {
      $positionmapping->{$pos->SPrint} = $pos;
    }
  my @chosen = SubsetSelect
    (Set => \@set,
     Selection => {});
  my @ret;
  foreach my $name (@chosen) {
    push @ret, $positionmapping->{$name};
  }
  return \@ret;
}

sub SearchSources {
  my ($self,%args) = (shift,@_);
  Message(Message => "Searching sources...");
  my @keys;
  if (defined $args{Sources} and ref $args{Sources} eq "ARRAY") {
    @keys = @{$args{Sources}};
  }
  if (!@keys) {
    @keys = $self->MySources->Keys;
  }
  my @matches;
  foreach my $key (@keys) {
    my $source = $self->MySources->Contents->{$key};
    if (! $source->Loaded) {
      Message(Message => "Loading $key...");
      $source->MyPositions->Load;
      Message(Message => "Loaded ".$source->MyPositions->Count." positions.");
      $source->Loaded(1);
    }
    if (! $source->MyPositions->IsEmpty) {
      Message(Message => "Searching $key...");
      foreach my $position ($source->MyPositions->Values) {
	if ($position->Matches(Criteria => $args{Criteria})) {
	  push @matches, $position;
	}
      }
    }
  }
  return \@matches;
}

sub GetSearchCriteria {
  my ($self,%args) = (shift,@_);
  my %criteria;
  my $conf = $UNIVERSAL::js->Config->CLIConfig;
  if (exists $conf->{-a}) {
    $criteria{Any} = $conf->{-a};
  }
  if (exists $conf->{-n}) {
    $criteria{ID} = $conf->{-n};
  }
  if (exists $conf->{-d}) {
    $criteria{Description} = $conf->{-d};
  }
  if (exists $args{Search}) {
    $criteria{ID} = $args{Search};
  }
  if (! %criteria) {
    foreach my $field
      # (qw (Name ShortDesc LongDesc Tags Dependencies Categories Source)) {
      (qw (ID Description)) {
	Message(Message => "$field?: ");
	my $res = <STDIN>;
	chomp $res;
	if ($res) {
	  $criteria{$field} = $res;
	}
      }
  }
  return \%criteria;
}

1;
