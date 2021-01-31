#!/usr/bin/perl -w

use Data::Dumper;
use URI::http;
use WWW::Mechanize;
use WWW::Mechanize::Link;

my $mech = WWW::Mechanize->new;
my $dir = "/var/lib/myfrdcsa/codebases/internal/job-search/scripts/match-resume-to-position/resumes/data";

$mech->get("http://chicago.craigslist.org/res/");
my @links = $mech->find_all_links(url_regex => qr/\/res\/[0-9]{5,}.html/);
foreach my $link (@links) {
  my $url = $link->URI->abs->as_string;
  my $c = "wget -N -P \"$dir\" -xN \"$url\"";
  `$c`;
}
