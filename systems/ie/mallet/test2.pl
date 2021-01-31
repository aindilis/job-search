#!/usr/bin/perl -w

use NLU::Util::SpanDiff;
use NLU::Util::AnnotationStyle;
use PerlLib::SwissArmyKnife;

use Algorithm::Diff qw(diff);

my $a = "<nn>Path</nn> <pps>:</pps> <nn>cs.utexas.edu</nn> <pp>!</pp> <jj>news-relay.us.dell.com</jj> <pp>!</pp> <nn>jump.net</nn>";
my $b = "<nn>Path</nn><pps>:</pps> <nn>cs.utexas.edu</nn><pp>!</pp><jj>news-relay.us.dell.com</jj><pp>!</pp><nn>jump.net</nn>";

my $ares = InlineToStandoff(Contents => $a);
my $bres = InlineToStandoff(Contents => $b);

print Dumper($ares);

# my $res = ComputeDiffOnSpans
#   (
#    StartingText => $ares->{Text},
#    EndingText => $bres->{Text},
#    Spans => $ares->{Spans},
#   );

# my $res2 = StandoffToInline
#   (
#    Spans => $res->{Spans},
#    Text => $ares->{Text},
#   );

# if ($res2->{Success}) {
#   print "<doc>".$b."</doc>\n";
#   print $res2->{Result}."\n";
# }

# $a = "abcdefghijklmnopqrstuvwxyz";
# $b = "abcwxyzghijklmnoabcstuvwxyz";

# print Dumper();

# my $moves = diff([split //, $a],[split //, $b]);

# now compute the final sequence from the first

my @list = map {[[$_,{}]]} split //, $ares->{Text};
my $i = 0;
my $spans = {};
foreach my $span (@{$ares->{Spans}}) {
  $spans->{$i} = $span->[0];
  if ($span->[0] eq "pps") {
    print Dumper($span);
  }
  for (my $j = $span->[1]; $j < $span->[2]; ++$j) {
    $list[$j]->[0]->[1]->{$i} = 1;
  }
  ++$i;
}

# now compute the diff and then execute it
my $sequences = diff([split //, $ares->{Text}],[split //, $bres->{Text}]);
print Dumper($sequences);
foreach my $sequence (@$sequences) {
  foreach my $change (@$sequence) {
    my $op = $change->[0];
    my $pos = $change->[1];
    if ($op eq "-") {
      # delete the item
      shift @{$list[$pos]};
    } elsif ($op eq "+") {
      # if there is already an item here
      push @{$list[$pos]}, [$change->[2],{}];
    }
  }
}

# now reassemble
my @answer;
my @spans;
my $i = 0;
my $currentspans = {};
foreach my $elt (@list) {
  foreach my $item (@$elt) {
    push @answer, $item->[0];
    foreach my $id (keys %$currentspans) {
      if (! exists $item->[1]->{$id}) {
	# close the tag
	$currentspans->{$id}->[2] = $i;
	push @spans, $currentspans->{$id};
	delete $currentspans->{$id};
      }
    }
    foreach my $id (keys %{$item->[1]}) {
      if (! exists $currentspans->{$id}) {
	# start
	$currentspans->{$id} = [$spans->{$id},$i,undef];
	if ($spans->{$id} eq "pps") {
	  print Dumper($currentspans);
	}
      }
    }
    ++$i;
  }
}
my $text = join("", @answer);
my $res = StandoffToInline
   (
    Spans => \@spans,
    Text => $text,
   );

if ($res->{Success}) {
  print "<doc>".$a."</doc>\n";
  print "<doc>".$b."</doc>\n";
  print $res->{Result}."\n";
}
