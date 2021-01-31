package JS::Source::JobsPerlOrg;

use Manager::Dialog qw (ApproveCommands Choose Message SubsetSelect QueryUser);

use Data::Dumper;
use IO::File;
use WWW::Mechanize;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw / Mech /
  ];

# system responsible for scraping jobs and resumes off online sites

sub init {
  my ($self,%args) = @_;
}

sub UpdateSource {
  my ($self,%args) = @_;
  $self->Mech(WWW::Mechanize->new);
  $self->Mech->get("http://jobs.perl.org");
  my $dir = "/var/lib/myfrdcsa/codebases/internal/job-search/data/source/JobsPerlOrg/jobs";
  foreach my $link ($self->Mech->links) {
    if ($link->[0] =~ /^http:\/\/jobs.perl.org\/job\/(\d+)$/) {
      # this is our link, wget it
      my $url = $link->[0];
      my $outputfile = "/var/lib/myfrdcsa/codebases/internal/job-search/data/source/JobsPerlOrg/jobs/jobs.perl.org/job/$1";
      if (! -f $outputfile) {
	my $c = "wget -N -P \"$dir\" -xN \"$url\"";
	`$c`;
	$self->Delay;
      }
    }
  }
}

sub Delay {
  my ($self,%args) = @_;
  sleep 10;
}

1;
