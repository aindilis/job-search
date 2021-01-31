#!/usr/bin/perl -w

use JS;
use JS::MinorThird;

$UNIVERSAL::js = JS->new();

my $minorthird = JS::MinorThird->new;
$UNIVERSAL::js->MyManager->LoadPositions;
$minorthird->ExtractPositionInformation;
