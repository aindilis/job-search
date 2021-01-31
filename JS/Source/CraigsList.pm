package JS::Source::CraigsList;

use Manager::Dialog qw (ApproveCommands Choose Message SubsetSelect QueryUser);
use PerlLib::Collection;

use Cache::FileCache;
use Data::Dumper;
use IO::File;
use WWW::Mechanize::Cached;
use WWW::Mechanize::Link;
use URI::http;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw / Loaded CraigsListURL Cities Categories CacheObj Cacher Log /
  ];

# system responsible for scraping jobs and resumes off online sites

sub init {
  my ($self,%args) = @_;
  $self->CraigsListURL("http://www.craigslist.org/");
  $self->Cities({});
  $self->Categories({});
  $self->Loaded(0);
}

sub UpdateSource {
  my ($self,%args) = @_;
  if (! exists $UNIVERSAL::js->Config->CLIConfig->{'--resume'}) {
    ApproveCommands
      (
       Commands => ["rm -rf $UNIVERSAL::systemdir/data/FileCache/job-search"],
       AutoApprove => exists $UNIVERSAL::js->Config->CLIConfig->{'--cron'},
      );
  }
  $self->CacheObj
    (Cache::FileCache->new
     ({
       namespace => 'job-search',
       default_expires_in => "1 month",
       cache_root => "$UNIVERSAL::systemdir/data/FileCache",
      }));
  $self->Cacher
    (WWW::Mechanize::Cached->new
     (
      cache => $self->CacheObj,
      timeout => 15,
     ));
  my $fh = IO::File->new;
  $fh->open(">>".$UNIVERSAL::systemdir."/data/source/CraigsList-metadata/spider.log") or die "Cannot open log file\n";
  print $fh "NEW RUN\n";
  $self->Log($fh);
  Message(Message => "Updating source: CraigsList");
  $args{Cities} = {
		   pittsburgh => 1,
		   chicago => 1,
		   bellingham => 1,
		   sfbay => 1,
		   newyork => 1,
		  };
  $args{AllCategories} = 1;
  $self->ExtractJobs(%args);
}

sub LoadSource {
  my ($self,%args) = @_;
}

sub ExtractJobs {
  my ($self,%args) = @_;
  $self->MyGet("http://geo.craigslist.org/iso/us"); # $self->CraigsListURL);
  $self->LoadCityNames;

  if ($args{Cities}) {
    @cities = keys %{$args{Cities}};
  } else {
    @cities = SubsetSelect
      (
       Set => ["Other", sort keys %{$self->Cities}],
       Selection => {},
       NoAllowWrap => 1,
      );
  }

  my @entries;
  foreach my $city (@cities) {
    $self->MyGet($self->Cities->{$city});
    $self->LoadCategories
      (City => $city);

    my @categories;
    if ($args{Categories}) {
      @categories = @{$args{Categories}->{$city}};
    } elsif ($args{AllCategories}) {
      @categories = sort keys %{$self->Categories->{$city}},
    } else {
      @categories = SubsetSelect
	(Set => [sort keys %{$self->Categories->{$city}}],
	 Selection => {});
    }

    foreach my $category (@categories) {
      my $catloc = $self->Categories->{$city}->{$category};
      push @entries, {
		      URL => "http://$city.craigslist.org/$catloc/",
		      City => $city,
		     };
    }
  }
  print Dumper(\@entries);

  $items = {};
  foreach my $entry (@entries) {
    my $url = $entry->{URL};
    my $namedcity = $entry->{City};

    $self->MyGet($url);
    my $dir = "$UNIVERSAL::systemdir/data/source/CraigsList/";
    my @links = $self->Cacher->find_all_links(url_regex => qr/\/\w{3}\/[0-9]{5,}.html/);
    # we want to cache this information in case of a failure of the
    # spider, nevermind, just rerun since we're caching web hits
    foreach my $link (@links) {
      my $url = $link->URI->abs->as_string;
      my ($city,$location,$category,$number,$outputfile,$skip);
      if ($url =~ /^http:\/\/(.+?).craigslist.org\/(\w{3})\/(\w{3})\/([0-9]{5,}).html/) {
	$city = $1;
	$location = $2;
	$category = $3;
	$number = $4;
      } elsif ($url =~ /^http:\/\/(.+?).craigslist.org\/(\w{3})\/([0-9]{5,}).html/) {
	$city = $1;
	$location = "default";
	$category = $2;
	$number = $3;
      } else {
	print "ERROR: $url\n";
	$skip = 1;
      }
      if (! $skip) {
	# 	print Dumper({
	# 		      City => $city,
	# 		      Loc => $location,
	# 		      Cat => $category,
	# 		      Num => $number,
	# 		     });
	# 	next;

	if ($url =~ /http:\/\/(.+)$/) {
	  $outputfile = "$UNIVERSAL::systemdir/data/source/CraigsList/$1";
	}
	$items->{$city}->{$location}->{$category}->{$number} = 1;

	if (! -f $outputfile) {
	  my $c = "wget -N -P \"$dir\" -xN \"$url\"";
	  `$c`;
	  $self->Delay;
	}
      }
    }
  }

  # print Dumper($items);

  # now do a moving

  # moving works by looking at the CraigsList directory

  # foreach file there, if it is already in the system, i.e. it was in
  # the list of positions taken from the scraping, then we don't have
  # to move it, otherwise move it

  foreach my $file (split /\n/, `find $UNIVERSAL::systemdir/data/source/CraigsList`) {
    if ($file =~ /\.html$/) {
      my ($city,$location,$category,$number,$outputfile,$skip);
      if ($file =~ /.*\/(.+?).craigslist.org\/(\w{3})\/(\w{3})\/([0-9]{5,}).html/) {
	$city = $1;
	$location = $2;
	$category = $3;
	$number = $4;
      } elsif ($file =~ /.*\/(.+?).craigslist.org\/(\w{3})\/([0-9]{5,}).html/) {
	$city = $1;
	$location = "default";
	$category = $2;
	$number = $3;
      } else {
	print "ERROR: $file\n";
	$skip = 1;
      }
      if (! $skip) {
	if (exists $items->{$city} and
	    exists $items->{$city}->{$location} and
	    exists $items->{$city}->{$location}->{$category} and
	    exists $items->{$city}->{$location}->{$category}->{$number}) {
	  # then it's in the system we can preserve it
	} else {
	  # we must move it to the archive
	  my @dir;
	  push @dir, $city.".craigslist.org";
	  if ($location ne "default") {
	    push @dir, $location;
	  }
	  push @dir, $category;
	  push @dir, $number;
	  my $htmlfile = "$UNIVERSAL::systemdir/data/source/CraigsList/".
	    join("/",@dir).
	      ".html";
	  my $txtfile = $htmlfile.".txt";
	  pop @dir;
	  my $backupdir = "$UNIVERSAL::systemdir/data/source/CraigsList-backup/".
	    join("/",@dir);
	  if (! -d $backupdir) {
	    system "mkdirhier \"$backupdir\"";
	  }
	  my @tomove;
	  push @tomove, $htmlfile if -f $htmlfile;
	  push @tomove, $txtfile if -f $txtfile;
	  if (scalar @tomove) {
	    my $command = "mv ".join(" ",map{"\"$_\""} @tomove)." \"$backupdir\"";
	    print $command."\n";
	    system $command;
	  }
	}
      }
    }
  }
  # now update the items if need be
  if (! $UNIVERSAL::js->MyResumeMatcher) {
    use JS::ResumeMatcher;
    $UNIVERSAL::js->MyResumeMatcher
      (JS::ResumeMatcher->new());
  }
  $UNIVERSAL::js->MyResumeMatcher->LoadCities
    (
     Cities => [sort keys %{$args{Cities}}],
    );
}

sub LoadCityNames {
  my ($self,%args) = @_;
  #   my $c = $self->Cacher->content();
  #   foreach my $city ($c =~ /.*?(\w+).craigslist.org/g) {
  #     $self->Cities->{$city} = "http://$city.craigslist.org";
  #   }
  foreach my $link ($self->Cacher->links) {
    my $url = $link->[0];
    if ($url =~ /http:\/\/(\w+).craigslist.org/g) {
      # print Dumper([$1,$url]);
      $self->Cities->{$1} = $url;
    }
  }
}

sub LoadCategories {
  my ($self,%args) = @_;
  my $c = $self->Cacher->content();
  if ($c =~ /.*jobs\<\/a\>(.*?)\<\/td\><\/tr>/s) {
    foreach my $l (grep /href/, split /\n/, $1) {
      if ($l =~ /\<a href=\"([^\"]+)\"\>([^<]+)\</) {
	my $name = $2;
	my $url = $1;
	next if $url =~ /cgi-bin/;
	$name =~ s/\&nbsp;/ /g;
	$name =~ s/\s+/ /g;
	$url =~ s/\/$//;
	$self->Categories->{$args{City}}->{$name} = $url;
      }
    }
  }
  if ($c =~ /.*gigs\<\/a\>(.*?)\<\/td\><\/tr>/s) {
    foreach my $l (grep /href/, split /\n/, $1) {
      if ($l =~ /\<a href=\"([^\"]+)\"\>([^<]+)\</) {
	my $name = $2;
	my $url = $1;
	next if $url =~ /cgi-bin/;
	$name =~ s/\&nbsp;/ /g;
	$name =~ s/\s+/ /g;
	$url =~ s/\/$//;
	$self->Categories->{$args{City}}->{$name} = $url;
      }
    }
  }
}

sub Delay {
  my ($self,%args) = @_;
  sleep 10;
}

sub MyGet {
  my ($self,$url) = @_;
  $self->Cacher->get($url);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $iscached = "yes";
  if (! $self->Cacher->is_cached()) {
    $iscached = "no ";
    $self->Delay;
  }
  my $fh = $self->Log;
  my $date = sprintf("%4d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
  print $fh "$date $iscached $url\n",
}

1;
