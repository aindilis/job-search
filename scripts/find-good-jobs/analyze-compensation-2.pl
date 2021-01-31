#!/usr/bin/perl -w

use Data::Dumper;

my @items = qw(cpg crg cwg dmg lbg wrg tlg);

my $priceindex = {};
my $dir = `pwd`;
foreach my $item (split /\n/, `find /var/lib/myfrdcsa/codebases/internal/job-search/data/source/CraigsList`) {
  if (-d $item) {
    chdir $item;
    $c = `grep "Compensation:" *`;
    # print Dumper($c);
    foreach my $line (split /\n/, $c) {
      if ($line =~ /^(\d+\.html):\s*<li>\s*Compensation:\s+(.+)\s*(<ul>)?$/s) {
	# print "<$1><$2>\n";
	my $file = $item."/".$1;
	my $pay = $2;
	if ($pay =~ /\b(hr|hour)\b/i) {
	  if ($pay =~ /(\$?\s*[\d\.]+)(\s*(to|\-)\s*(\$?\s*[\d\.]+))?/i) {
	    if ($3) {
	      my $pricea = CleanPrice($1);
	      my $priceb = CleanPrice($4);
	      print "Pay: ".'$'."$pricea-".'$'."$priceb/hr\n";
	      $priceindex->{$file} = $priceb;
	    } else {
	      my $price = CleanPrice($1);
	      print "Pay: ".'$'."$price/hr\n";
	      $priceindex->{$file} = $price;
	    }
	  }
	}
      }
    }
  }
}
chdir $dir;

foreach my $key (sort {$priceindex->{$b} <=> $priceindex->{$a}} keys %$priceindex) {
  print '$'.$priceindex->{$key}."\t".GetTitle($key)."\t".$key."\n";
}

sub CleanPrice {
  my $price = shift;
  $price =~ s/^\$\s*//;
  if ($price !~ /\./) {
    $price .= ".00";
  }
  return $price;
}

sub GetTitle {
  my $file = shift;
  my $result = `grep '<title>' $file`;
  if ($result =~ /<title>(.+)<\/title>/s) {
    return $1;
  } else {
    return "unknown";
  }
}

