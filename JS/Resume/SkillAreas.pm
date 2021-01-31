package JS::SkillAreas;

use Manager::Dialog qw (Message Choose);

use Data::Dumper;
use Lingua::EN::Keywords;
use Lingua::EN::Sentence qw (get_sentences);
use Lingua::EN::Tagger;
use XML::Simple;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Contents SkillAreas StorageFile / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->StorageFile($args{StorageFile});
}

sub ExtractSkillAreas {
  my ($self,%args) = (shift,@_);
  my $f = $self->StorageFile;
  if (-e $f) {
    my $c = `cat $f`;
    $self->Contents($f);
  }
  $tagger = Lingua::EN::Tagger->new(stem => 0);
  my $d = $tagger->add_tags( $c );
  my %noun_phrases = $tagger->get_max_noun_phrases($d);
  $self->SkillAreas(\%noun_phrases);
}

sub Print {
  my ($self,%args) = (shift,@_);
  print Dumper($self->Phrases);
}

1;

#   <skillarea>
#     <title>Skills Summary</title>

#     <!-- Computer Languages -->
#     <skillset>
#       <title><emphasis>Programming Languages</emphasis></title>
#       <skill>Java</skill>
#       <skill>C/C++</skill>
#       <skill>OO Perl</skill>
#       <skill>Unix scripting</skill>
#       <skill>Emacs Lisp</skill>
#       <skill>Tcl/Tk</skill>
#     </skillset>

#     <!-- Architecture and Design -->
#     <skillset>
#       <title><emphasis>Software Architecture and Design</emphasis></title>
#       <skill>UML</skill>
#       <skill>Umbrello</skill>
#     </skillset>

#     <!-- OS -->
#     <skillset>
#       <title><emphasis>Operating Systems</emphasis></title>
#       <skill>Linux (Debian, Redhat)</skill>
#     </skillset>

#     <!-- Project Management and Documentation -->
#     <skillset>
#       <title><emphasis>Project Management and Documentation</emphasis></title>
#       <skill>DocBook</skill>
#       <skill>POD</skill>
#     </skillset>

#     <!-- Databases -->
#     <skillset>
#       <title><emphasis>Databases</emphasis></title>
#       <skill>MySQL</skill>
#     </skillset>

#     <!-- Project Management and Documentation -->
#     <skillset>
#       <title><emphasis>Software Tools and Utilities</emphasis></title>
#       <skill>Subversion</skill>
#       <skill>CVS</skill>
#       <skill>Bugzilla</skill>
#       <skill>Make</skill>
#       <skill>DocBook</skill>
#       <skill>LaTeX</skill>
#     </skillset>

#     <!-- Natural Languages
#     <skillset>
#       <title><emphasis>Languages</emphasis></title>
#       <skill>English</skill>
#       <skill>German</skill>
#     </skillset>
#     -->

#   </skillarea>
