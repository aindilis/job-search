#!/usr/bin/perl -w

use JS::ResumeMatcher;

$UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/internal/job-search";

my $matcher = JS::ResumeMatcher->new;

$matcher->LoadCities
  (
   Cities => [
	      "chicago",
	     ],
  );

$matcher->MatchResumes
  (
   # Tiny => 1,
   Resumes => [
	       "/var/lib/myfrdcsa/codebases/internal/job-search/data/resumecache/resume___10_1_10_110_resume_pdf.job-search.txt",
	      ],
  );
