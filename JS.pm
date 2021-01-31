package JS;

use BOSS::Config;
use JS::Manager;
use JS::Profile;
use JS::ResumeMatcher;
use Manager::Dialog qw (Message);
use MyFRDCSA;
use PerlLib::UI;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Config MainMenu MyManager MyResumeMatcher / ];

sub init {
  my ($self,%args) = (shift,@_);
  $specification = "
	-U [<sources>...]	Update sources
	-l [<sources>...]	Load sources
	-s [<sources>...]	Search sources
	-c [<sources>...]	Choose sources

	--resume		Resume a spidering that was interrupted
	--cron			This is a cron script

	-m			Main Menu

	-i			Interview training
	-r			Maintain resumes

	-w			Require user input before exiting

	-u [<host> <port>]	Run as a UniLang agent
";
  $UNIVERSAL::agent->DoNotDaemonize(1);
  $UNIVERSAL::systemdir = ConcatDir(Dir("internal codebases"),"job-search");
  $self->Config(BOSS::Config->new
	      (Spec => $specification,
	       ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-u'}) {
    $UNIVERSAL::agent->Register
      (Host => defined $conf->{-u}->{'<host>'} ?
       $conf->{-u}->{'<host>'} : "localhost",
       Port => defined $conf->{-u}->{'<port>'} ?
       $conf->{-u}->{'<port>'} : "9000");
  }
  $self->MyManager(JS::Manager->new);
}

sub Execute {
  my ($self,%args) = (shift,@_);
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-U'}) {
    $self->MyManager->MySourceManager->UpdateSources
      (Sources => $conf->{'-U'});
  }
  if (exists $conf->{'-l'}) {
    $self->MyManager->MySourceManager->LoadSources
      (Sources => $conf->{'-l'});
  }
  if (exists $conf->{'-s'}) {
    $self->MyManager->MySourceManager->Search
      (Sources => $conf->{-s});
  }
  if (exists $conf->{'-c'}) {
    $self->MyManager->MySourceManager->Choose
      (Sources => $conf->{-c});
  }
  if (exists $conf->{'-u'}) {
    # enter in to a listening loop
    while (1) {
      $UNIVERSAL::agent->Listen(TimeOut => 10);
    }
  }
  if (exists $conf->{'-m'}) {
    $self->MyManager->Execute;
    $self->LoadMenu;
  }
  if (exists $conf->{'-w'}) {
    Message(Message => "Press any key to quit...");
    my $t = <STDIN>;
  }
}

sub LoadMenu {
  my ($self,%args) = (shift,@_);
  $self->MainMenu
    (PerlLib::UI->new
     (Menu => [
	       "Main Menu", [
			     "Profiles", "Profiles",
			     "Positions", "Positions",
			     "Cover Letters", "Cover Letters",
			     "Correspondences", "Correspondences",
			     "Interviews", "Interviews",
			    ],
	       "Profiles", [
			    "List Profiles",
			    sub {$self->MyManager->Profiles->PrintKeys},

			    "Create New Profile",
			    sub {$self->MyManager->CreateNewProfile},

			    "Select Profile",
			    sub {
			      $self->MyManager->SelectProfile;
			      my $menu = $UNIVERSAL::js->MainMenu;
			      push @{$menu->Stack},
				$menu->Menu->{"Profile"};
			    },
			   ],
	       "Profile", [
			   "Resumes",
			   sub {
			     my $menu = $UNIVERSAL::js->MainMenu;
			     push @{$menu->Stack},
			       $menu->Menu->{"Resumes"};
			   },

			   "Select Positions",
			   sub {
			     $self->MyManager->CurrentProfile->SelectPositions;
			   },

			   "Generate Custom Resumes For Positions",
			   sub {Message(Message => "Not implemented")},

			   "Recommend Reading",
			   sub {
			     $self->MyManager->CurrentProfile->
			       RecommendReading;
			   },
			  ],
	       "Positions", [
			     "Update Positions",
			     sub {
			       $self->MyManager->MySourceManager->
				 UpdateSources;
			     },

			     "List Positions",
			     sub {$self->MyManager->Positions->Map->
				    Description},
			    ],
	       "Resumes", [
			   "List Resumes",
			   sub {
			     $self->MyManager->CurrentProfile->MyResumes->
			       PrintKeys;
			   },

			   "Create New Resume",
			   sub {
			     $self->MyManager->CurrentProfile->
			       CreateNewResume;
			   },

			   "Critique Resume",
			   sub {Message(Message => "Not implemented")},

			   "Select Resume",
			   sub {
			     $self->MyManager->CurrentProfile->
			       SelectResume;
			   },

			   "Render Resume",
			   sub {
			     $self->MyManager->CurrentProfile->
			       CurrentResume->Render if
				 $self->MyManager->CurrentProfile->
				   CheckCurrentResumeExists;
			   },
			  ],
	       "Cover Letters", [
				 "List Cover Letters",
				 sub {
				   Message(Message => "Not implemented")
				 },

				 "Edit Cover Letters",
				 sub {
				   Message(Message => "Not implemented")
				 },

				 "Create New Cover Letter",
				 sub {
				   Message(Message => "Not implemented")
				 },
				],
	       "Correspondence", [
				  "List Correspondences",
				  sub {
				    Message(Message => "Not implemented")
				  },

				  "Edit Correspondences",
				  sub {
				    Message(Message => "Not implemented")
				  },

				  "Create New Correspondence",
				  sub {
				    Message(Message => "Not implemented")
				  },
				 ],
	       "Interviews", [
			      "List Interviews",
			      sub {
				Message(Message => "Not implemented")
			      },

			      "Edit Interviews",
			      sub {
				Message(Message => "Not implemented")
			      },

			      "Create New Interview",
			      sub {
				Message(Message => "Not implemented")
			      },
			     ],
	      ],
      CurrentMenu => "Main Menu"));
  Message(Message => "Starting Event Loop...");
  $self->MainMenu->BeginEventLoop;
  $self->Save;
}

sub Save {
  my ($self, @files) = @_;
}

sub ProcessMessage {
  my ($self, %args) = @_;
  # this is mainly designed to handle resume matching requests from job-search.cgi
  print Dumper(\%args);
  if ($args{Message}->{Contents} eq "resume-match") {
    my $data = $args{Message}->Data;
    if (! $self->MyResumeMatcher) {
      $self->MyResumeMatcher
	(JS::ResumeMatcher->new());
    }
    my $results = $self->MyResumeMatcher->MatchResumes
      (
       User => $data->{User},
       Cities => $data->{Cities},
       Resumes => $data->{Resumes},
      );
    $UNIVERSAL::agent->SendContents
      (
       Receiver => $args{Message}->Sender,
       Data => {
		_DoNotLog => 1,
		Results => $results,
	       },
      );
  }
}

1;
