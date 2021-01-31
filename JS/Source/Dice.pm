package JS::Source::Dice;

use Manager::Dialog qw (Message Choose);
use PerlLib::Collection;

use Data::Dumper;
use WWW::Mechanize;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw / MyPositions Loaded DiceURL Mech Cities Categories /
  ];

# system responsible for scraping jobs and resumes off online sites

sub init {
  my ($self,%args) = (shift,@_);
  $self->Mech(WWW::Mechanize->new);
  $self->DiceURL("http://www.craigslist.org/");
  $self->MyPositions
    (PerlLib::Collection->new
     (StorageFile => $args{StorageFile} || "$UNIVERSAL::systemdir/data/source/Dice/.sorcerer",
      Type => "JS::Position"));
  $self->MyPositions->Contents({});
  $self->Loaded(0);
}

sub UpdateSource {
  my ($self,%args) = (shift,@_);
  Message(Message => "Updating source: Dice");
}

sub LoadSource {
  my ($self,%args) = (shift,@_);
  while (0) {
    # $self->MyPositions->Add($s->ID => $s);
  }
  $self->MyPositions->Save;
}

1;
