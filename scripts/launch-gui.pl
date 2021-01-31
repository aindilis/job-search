#!/usr/bin/perl -w

use Data::Dumper;

$ENV{MINORTHIRD} = "/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611";
# $ENV{CLASSPATH}=".:$ENV{MINORTHIRD}/class:$ENV{MINORTHIRD}/lib:$ENV{MINORTHIRD}/lib/minorThirdIncludes.jar";
# $ENV{CLASSPATH}="$ENV{CLASSPATH}:$ENV{MINORTHIRD}/lib/mixup:$ENV{MINORTHIRD}/config:$ENV{MINORTHIRD}/dist/m3rd_20080722.jar";
$ENV{MONTYLINGUA}="$ENV{MINORTHIRD}/lib/montylingua";
$ENV{CLASSPATH} = ':.:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/class:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/lib:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/lib/minorThirdIncludes.jar:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/lib/mixup:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/config:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/dist/m3rd_20080722.jar:.:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/class:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/lib:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/lib/minorThirdIncludes.jar:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/lib/mixup:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/config:/var/lib/myfrdcsa/sandbox/minorthird-20080611/minorthird-20080611/dist/m3rd_20080722.jar';
# print Dumper(\%ENV);
# my $c = "java edu.cmu.minorthird.ui.TrainExtractor -help –gui";
my $c = "java edu.cmu.minorthird.ui.TrainExtractor -labels /var/lib/myfrdcsa/codebases/internal/job-search/data/ie/jobs-small -gui";
system $c;
