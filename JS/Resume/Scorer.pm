package JS::Scorer;

# this system scores resumes using a variety of methods

# use  the  modules for  reading  complexity  -  essay scoring,  spell
# checking, etc.

use Manager::Dialog qw (Message Choose);

use Data::Dumper;
use Lingua::EN::Sentence qw (get_sentences);
use XML::Simple;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / XML Parsed StorageFile / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->StorageFile($args{StorageFile});
}

sub Parse {
  my ($self,%args) = (shift,@_);
  Message(Message => "Parsing Resume...");
  $self->XML(undef);
  $self->Parsed(undef);
  if (! $self->XML) {
    my $file = $self->StorageFile;
    my $contents = `cat $file`;
    my @i = split /\n/,$contents;
    my @tmp = splice (@i,0,3);
    $contents = join("\n",@i);
    $self->XML($contents);
  }
  if (! $self->Parsed) {
    $self->Parsed(XMLin($self->XML));
  }
  Message(Message => "Finished Parsing Resume.");
}

sub Print {
  my ($self,%args) = (shift,@_);
  print Dumper($self->Parsed);
}

1;
