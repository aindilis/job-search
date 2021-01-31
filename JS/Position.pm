package JS::Position;

# use JS::SkillAreas;
use Manager::Dialog qw (Message Choose);

use Data::Dumper;
use Lingua::EN::Keywords;
use Lingua::EN::Sentence qw (get_sentences);
use Lingua::EN::Tagger;
use XML::Simple;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / ID Contents StorageFile ContentsFile Title Employer Location
   Description Requirements MySkillAreas Tags Parsed /

  ];

sub init {
  my ($self,%args) = @_;
  $self->ID($args{ID});
  $self->StorageFile($args{StorageFile});
  $self->ContentsFile($args{ContentsFile});
  $self->Description($args{Description});
}

sub Print {
  my ($self,%args) = @_;
  print Dumper($self->Phrases);
}

sub Matches {
  my ($self,%args) = (shift,@_);
  if ($args{Criteria}) {
    if ($args{Criteria}->{Any}) {
      foreach my $key (qw(ID Description)) {
	if ($self->$key) {
	  if ($self->$key =~ /$args{Criteria}->{Any}/) {
	    return 1;
	  }
	}
      }
    } else {
      foreach my $key (keys %{$args{Criteria}}) {
	if ($self->$key) {
	  if ($self->$key =~ /$args{Criteria}->{$key}/i) {
	    return 1;
	  }
	}
      }
    }
  }
}

sub Parse {
  my ($self,%args) = @_;
  $self->ParseTwo(%args);
}

sub ParseOne {
  my ($self,%args) = @_;
  if (! $self->Parsed or $args{Force}) {
#     $self->MySkillAreas
#       (JS::SkillAreas->new
#        ());

    # get contents
    my $f = $self->ContentsFile;
    my $cf = $UNIVERSAL::js->MyManager->MyConverter->Convert(File => $f);
    my $c = `cat "$cf"`;
    $self->Contents($c);

    # extract job requirements
    # extract minimum versus desired requirements
    my $r = get_sentences($c);
    foreach my $sent (@$r) {
      $sent =~ s/\n/ /g;
      $sent =~ s/\s+/ /g;
    }
    $self->Requirements($r);
    $self->Parsed(1);
  }
}

# (maybe during resume generation, list known LOC for languages, etc.)

# GENERAL THINGS TO EXTRACT

# location
# employer
# email addresses to send applications to
# job title
# description
# technical skill requirements
# technical skills desired
# degree required?
# degree type
# desired years of experience
# compensation

# GENERAL THINGS TO INFER

# commute time
# what type of work is it? (military, non-military)
# morals
# whether position is some kind of scam and shouldn't be applied to

sub ParseTwo {
  my ($self,%args) = @_;
  if (! $self->Parsed or $args{Force}) {
    # get contents
    my $f = $self->ContentsFile;
    # my $cf = $UNIVERSAL::js->MyManager->MyConverter->Convert(File => $f);
    # my $c = `cat "$cf"`;
    my $c = `cat "$f"`;
    $self->Contents($c);

    # extract job requirements
    # extract minimum versus desired requirements
    my $r = get_sentences($c);
    foreach my $sent (@$r) {
      $sent =~ s/\n/ /g;
      $sent =~ s/\s+/ /g;
    }
    $self->Requirements($r);
    $self->Tags({});
    my @matches = @{$self->ExtractTags(Contents => $c)};
    while (@matches) {
      my ($key,$value) = (shift @matches,shift @matches);
      $self->Tags->{$key}->{$value} = 1;
    }
    $self->Parsed(1);
  }
}

sub ExtractTags {
  my ($self,%args) = @_;
  my $c = $args{Contents};
  my @m1 = $c =~ /<([^\>]+)>(.*?)<\/\1>/g;
  my @f;
  while (@m1) {
    my ($k,$v) = (shift @m1,shift @m1);
    $v =~ s/<[^\>]+>//g;
    push @f, $k;
    push @f, $v;
    my @m2 = $v =~ /<([^\>]+)>(.*?)<\/\1>/g;
    push @m1, @m2;
  }
  return \@f;
}

1;
