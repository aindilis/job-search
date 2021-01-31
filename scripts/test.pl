#!/usr/bin/perl -w

use WWW::Search;
my $oSearch = new WWW::Search('Dice');
my $sQuery = WWW::Search::escape_query("unix and (c++ or java)");
$oSearch->native_query($sQuery,
		       {'method' => 'bool',
			'state' => 'CA',
			'daysback' => 14});
while (my $res = $oSearch->next_result()) {
  if (isHitGood($res->url)) {
    my ($company,$title,$date,$location) =
      $oSearch->getMoreInfo($res->url);
    print "$company $title $date $location " . $res->url . "\n";
  }
}

sub isHitGood {return 1;}
