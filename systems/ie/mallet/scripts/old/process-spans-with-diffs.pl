#!/usr/bin/perl -w

use NLU::Util::AnnotationStyle;
use PerlLib::SwissArmyKnife;

use Algorithm::Diff qw(diff);

# see File: elisp,  Node: Sticky Properties,  Next: Saving Properties,  Prev: Format Properties,  Up: Text Properties

# note can use the text character 7 to point to the right side of the
# above character in some equispaced fonts

# have ascii art understanding system eventually, part of a diagram understanding system

# "tagged 's text"
# "tagged's text" ->
# spans would go from 0,7 to 0,7, 8,10, 7,9, and 11,15 to 10,14

my $spans = [
	     ["tag1",0,3],
	     ["tag2",5,7],
	    ];
my @a = qw(a b c e h j l m n p);
my @b = qw(b c d e f j k l m r s t);

PrintSpans
  (
   Text => join("", @a),
   Spans => $spans,
  );

# <tag1>abc</tag1>ehjlmnp
#    <tag2>bc</tag2>defjklmrst
# or <tag2>bcd</tag2>efjklmrst

# now compute the diff

my $res = ComputeDiffOnSpans
  (
   StartingText => join("",@a),
   EndingText => join("",@b),
   Spans => $spans,
  );

if ($res->{Success}) {
  PrintSpans
    (
     Text => join("",@b),
     Spans => $res->{Spans},
    );
}

sub ComputeDiffOnSpans {
  my %args = @_;
  my @a = split //, $args{StartingText};
  my @b = split //, $args{EndingText};
  my $diff = [diff(\@a,\@b)];
  foreach my $changesequence (@$diff) {
    foreach my $change (@$changesequence) {
      if ($change->[0] eq "+") {
	# it's adding, now increment all the spans greater than the current location
	foreach my $span (@{$args{Spans}}) {
	  my $loc = $change->[1] + 0;
	  if ($span->[1] > $loc) {
	    ++$span->[1];	# increment it
	    ++$span->[2];
	  } elsif ($span->[1] == $loc) {
	    # depending on sticky
	    # increment it for now or not?

	    if ($span->[2] > $loc) {
	      ++$span->[2];
	    } else {
	      # it must be equal
	      # depending on sticky
	      # increment it for now or not?
	    }
	  } elsif ($span->[1] < $loc) {
	    # try span 2, just in case
	    if ($span->[2] > $loc) {
	      ++$span->[2];	# increment it
	    } elsif ($span->[2] == $loc) {
	      # depending on sticky
	      # increment it for now or not?

	    } elsif ($span->[2] < $loc) {
	      # they're both less, ignore
	    }
	  }
	}
      } elsif ($change->[0] eq "-") {
	# it's adding, now increment all the spans greater than the current location
	foreach my $span (@{$args{Spans}}) {
	  my $loc = $change->[1] + 0;
	  if ($span->[1] >= $loc) {
	    # they must both be greater than or equal, in which case both are decremented
	    if ($span->[1] > 0) {
	      --$span->[1];	# decrement it
	    }
	    if ($span->[2] > 0) {
	      --$span->[2];
	    }
	  } elsif ($span->[1] < $loc) {
	    # nothing happens for 1, check 2
	    # try span 2, just in case
	    if ($span->[2] >= $loc) {
	      --$span->[2];	# decrement it
	    }
	  }
	}
      }
    }
  }
  return {
	  Success => 1,
	  Spans => $args{Spans},
	 };
  # take the first list
}
