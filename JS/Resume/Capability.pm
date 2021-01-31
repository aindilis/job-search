package JS::Capability;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [ qw / Description / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Description($args{Description});
}

1;
