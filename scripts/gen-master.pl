#!/usr/bin/perl -w

# program to generate a master resume automatically from many different resumes

# in the future, this program  could operate on any resume source that
# the user wanted,  by using IE on a resume corpus,  but for now, it's
# only for resumexml.

use JS::ResumeXML2;
use XML::DOM;

use Data::Dumper;

my $parser = new XML::DOM::Parser;
my $doc = $parser->parse("<resume/>");

sub GenerateMasterResume {


  my $mr = JS::ResumeXML2->new
    (
     ID => "Master resume",
     Profile => undef,
     StorageFile => "data/hand-crafted/master.xml",
     TargetDir => undef,
     ApplicablePositions => undef,
    );

  $mr->ParseResumeXML;
  my $md = $mr->Parsed;

  my @resumes = split /\n/,`ls data/hand-crafted/[0-9]*.xml`;
  foreach my $f (@resumes) {
    my $c = `cat "$f"`;
    my $r = JS::ResumeXML2->new
      (
       ID => $f,
       Profile => undef,
       StorageFile => $f,
       TargetDir => undef,
       ApplicablePositions => undef,
      );
    $r->ParseResumeXML;
    # merge the node into the existing master resume
    my $node = nodeMerge
      (A => $r->Parsed->getDocumentElement,
       B => $md->getDocumentElement);
    $node->setOwnerDocument($md);
    $md->setDocumentElement($node);
  }
  # save
  $md->printToFile ("/tmp/master.xml");
  # $mr->Render;
}

sub nodeMerge {
  my (%args) = @_;
  my $a = $args{A};
  my $b = $args{B};
  my $na = $a->getNodeName;
  my $nb = $b->getNodeName;
  if ($na eq $nb and $na !~ /^\#/) {
    # create a new node to represent these two, then return it
    my $node = $doc->createElement("resume");

    my $ca = $a->cloneNode(1);
    my $cb = $b->cloneNode(1);

    my $sa = {};
    my $sb = {};
    foreach my $n ($ca->getChildNodes) {
      if ($n->getNodeName !~ /^\#/) {
	$sa->{$n->getNodeName} = $n;
      }
    }

    foreach my $n ($cb->getChildNodes) {
      if ($n->getNodeName !~ /^\#/) {
	$sb->{$n->getNodeName} = $n;
      }
    }

    print Dumper(keys %$sa);

    # print $ca->toString;
    # print $cb->toString;

    my $i = <STDIN>;

    return $node;
  }
}

GenerateMasterResume();
