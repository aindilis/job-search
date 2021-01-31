#!/usr/bin/perl -w

my $priceindex = {};
foreach my $line (split /\n/, `cat pay2`) {
  my ($file,$pay) = split /\t/, $line;
  if ($pay =~ /\b(hr|hour)\b/i) {
    print "$pay\n";
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

