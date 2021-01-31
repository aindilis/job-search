package JS::Source::Tagged;

use Manager::Dialog qw (Message Choose SubsetSelect);
use PerlLib::Collection;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw / MyPositions Loaded TaggedURI /
  ];

# system responsible for scraping jobs and resumes off online sites

sub init {
  my ($self,%args) = (shift,@_);
  $self->MyPositions
    (PerlLib::Collection->new
     (StorageFile => $args{StorageFile}
      || "$UNIVERSAL::systemdir/data/source/Tagged/.jobsearch",
      Type => "JS::Position"));
  $self->MyPositions->Contents({});
  $self->Loaded(0);
}

sub UpdateSource {
  my ($self,%args) = (shift,@_);
  Message(Message => "Updating source: Tagged");
  $self->TaggedURI("$UNIVERSAL::systemdir/data/ie/jobs");
  my $id = 0;
  my $td = $self->TaggedURI;
  foreach my $file (split /\n/, `ls $td`) {
    my $sf = "$UNIVERSAL::systemdir/data/source/Tagged/$file.pl";
    my $p = JS::Position->new
      (
       ID => "jobs-tag-".$id++,
       Description => $file,
       ContentsFile => "$td/$file",
       StorageFile => $sf,
      );
    $self->MyPositions->Add($p->ID => $p);
  }
  $self->MyPositions->Save;
}

sub LoadSource {
  my ($self,%args) = (shift,@_);
}

1;
