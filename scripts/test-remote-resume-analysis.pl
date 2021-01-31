#!/usr/bin/perl -w

use UniLang::Util::TempAgent;

use Data::Dumper;

my $filename = "/var/lib/myfrdcsa/codebases/data/job-search/resumecache/resume___10_1_10_110_resume_pdf.job-search.txt";

my $tempagent = UniLang::Util::TempAgent->new();
my $message = $tempagent->MyAgent->QueryAgent
  (
   Receiver => "Job-Search",
   Contents => "resume-match",
   Data => {
	    Cities => [
		       "chicago",
		      ],
	    Resumes => [
			$filename,
		       ],
	   },
  );

print Dumper($message);
