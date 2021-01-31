package JS::MinorThird;

# program to extract various items using minorthird wrapper

use System::MinorThird;
use System::MinorThird::Entry;

use Data::Dumper;
use File::Basename;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyMinorThird TrainingDir TestingDir  /

  ];

sub init {
  my ($self,%args) = @_;
  # $ENV{CLASSPATH} ||= "";
  $ENV{MINORTHIRD} = "/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611";
  $ENV{CLASSPATH}="$ENV{CLASSPATH}:.:$ENV{MINORTHIRD}/class:$ENV{MINORTHIRD}/lib:$ENV{MINORTHIRD}/lib/minorThirdIncludes.jar";
  $ENV{CLASSPATH}="$ENV{CLASSPATH}:$ENV{MINORTHIRD}/lib/mixup:$ENV{MINORTHIRD}/config:$ENV{MINORTHIRD}/dist/m3rd_20080722.jar";
  $ENV{MONTYLINGUA}="$ENV{MINORTHIRD}/lib/montylingua";
}

sub ExtractPositionInformation {
  my ($self,%args) = @_;

  # create a minorthird instance
  $self->MyMinorThird
    (System::MinorThird->new
     (TrainingDir => $self->TrainingDir,
      TestingDir => $self->TestingDir));

  # set up training and testing dirs
  my $options = "-small";
  $self->TrainingDir
    ("/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs$options");
  $self->TestingDir
    ("/var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-testing$options");

  # export positions
#   foreach my $p ($UNIVERSAL::js->MyManager->Positions->Values) {
#     my $f = $self->TestingDir."/".basename($p->StorageFile);
#     my $e = System::MinorThird::Entry->new
#       (
#        ID => $p->ID,
#        StorageFile => $f,
#        Contents => $p->Contents,
#       );
#     $e->SaveContentsToStorageFile;
#     $self->MyMinorThird->TestingSet->Add($e->ID => $e);
#   }

  # learn extractor and run it
  my $mtdd = "/var/lib/myfrdcsa/codebases/internal/job-search/data/minorthird";
  # my $extractorf = "$mtdd/area.ann";
  my $extractorf = "$mtdd/java-model.serialized";
  my $resultf = "$mtdd/result.labels";
  if (0) {
    $self->MyMinorThird->TrainTestExtractor
      (LabelledDir => $self->TrainingDir,
       Span => "application");
  } else {
    if (! -f $extractorf) {
      $self->MyMinorThird->LearnExtractor
	(LabelledDir => $self->TrainingDir,
	 Extractor => $extractorf,
	 Span => "application");
    }
    print "hello\n";
    $self->MyMinorThird->RunExtractorOnUnlabelledData
      (UnlabelledDir => $self->TestingDir,
       Extractor => $extractorf,
       Result => $resultf);
  }
  exit(0);
}

1;
