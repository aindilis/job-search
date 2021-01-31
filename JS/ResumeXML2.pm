package JS::ResumeXML2;

# this is a package for parsing resumexml

use Manager::Dialog qw (Approve ApproveCommands Message Choose);

use Data::Dumper;
use Lingua::EN::Sentence qw (get_sentences);
use XML::DOM;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / ID MyProfile XML Parsed StorageFile TargetDir
   ApplicablePositions MyTwig /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->ID($args{ID});
  $self->MyProfile($args{Profile});
  $self->StorageFile($args{StorageFile});
  $self->TargetDir($args{TargetDir});
  $self->ApplicablePositions($args{ApplicablePositions});
}

sub ParseAnyFormat {
  my ($self,%args) = (shift,@_);
  # use the converter to convert the document, then use an information
  # extraction tool to extract the various resume information
}

sub ParseResumeXML {
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
    my $parser = new XML::DOM::Parser;
    my $doc = $parser->parse($self->XML);
    $self->Parsed($doc);
  }
  Message(Message => "Finished Parsing Resume.");
}

sub Capabilities {
  my ($self,%args) = (shift,@_);
  my @cap;
  my @jobs = @{$self->Parsed->{history}->{job}};
  foreach my $j (@jobs) {
    # print Dumper($j);
    my $sents = get_sentences(join ("\n", values %{$j->{description}}));
    foreach my $sent (@$sents) {
      $sent =~ s/\n/ /g;
      $sent =~ s/\s+/ /g;
      push @cap, $sent;
      # print "$sent\n\n";
    }
  }
  return \@cap;
}

sub GenerateSubResume {
  my ($self,%args) = (shift,@_);

  # select the different  parts to edit and simply  select a subset of
  # the existing  resume (save which  items are not included,  so that
  # changes to the master resume don't adversely affect things)

  foreach my $area (qw(header objective skillarea history academics references)) {

  }
}

sub Edit {
  my ($self,%args) = (shift,@_);
}

sub SPrint {
  my ($self,%args) = (shift,@_);
  return $self->Parsed->toString;
}

sub Render {
  my ($self,%args) = (shift,@_);
  if (Approve("Generates PDF/HTML/TXT versions of this resume?")) {
    $self->WriteResumeToBuildLocation;
    $self->BuildResume(TargetDir => $self->TargetDir);
  }
}

sub WriteResumeToBuildLocation {
  my ($self,%args) = (shift,@_);
  my $dir = "data/resume/src/xml";
  my $OUT;
  open (OUT,">$dir/resume.xml") or die "ouch\n";
  print OUT $self->SPrint;
  close (OUT);
  # system "cp \"".$self->StorageFile."\" \"$dir/resume.xml\"";
}

sub BuildResume {
  my ($self,%args) = (shift,@_);
  Message(Message => "Building resume... (this may take some time)");
  my $results = `cd data/resume && ant`;
  print $results;
  if (defined $self->TargetDir) {
    my @files;
    foreach my $l (grep /generating \/tmp/, split /\n/, $results) {
      if ($l =~ /^\s*\[echo\] generating (.*)\s*$/) {
	if (-f $1) {
	  push @files, $1;
	}
      }
    }
    my @commands;
    if (! -d $self->TargetDir) {
      push @commands, "mkdirhier ".$self->TargetDir;
    }
    push @commands, "mv ".join(" ",@files)." ".$self->TargetDir;
    ApproveCommands
      (Commands => \@commands);
  }
}

1;
