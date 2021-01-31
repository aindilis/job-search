package JS::MatchMaker;

# module to  plan various job search  activities out for the  user - a
# module for PSE and Verber

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / / ];

sub init {
  my ($self,%args) = (shift,@_);
}

sub LoadMatchmakingRules {
  my ($self,%args) = (shift,@_);

}

1;
