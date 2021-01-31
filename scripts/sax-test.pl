#!/usr/bin/perl -w

use Data::Dumper;
use XML::SAX::ParserFactory;

my $p = XML::SAX::ParserFactory->parser();
$p->parse_string("<foo/>");

print Dumper($p);
