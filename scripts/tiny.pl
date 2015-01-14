#!/usr/bin/env perl

use strict;
use warnings;

use X500::DN::Marpa ':constants';

# -----------

my(%count)  = (fail => 0, success => 0, total => 0);
my($parser) = X500::DN::Marpa -> new
(
	options => long_descriptors,
);
my(@text) =
(
	q|cn=Nemo, c=US|,
	q|commonName=Nemo, countryName=US|,
);

my($result);

for my $text (@text)
{
	$count{total}++;

	print sprintf('(# %3d) | ', $count{total});
	printf '%10d', $_ for (1 .. 9);
	print "\n";
	print '        |';
	print '0123456789' for (0 .. 8);
	print "0\n";
	print "Parsing |$text|. \n";

	$result = $parser -> parse($text);

	print "Parse result: $result (0 is success)\n";

	if ($result == 0)
	{
		$count{success}++;

		for my $item ($parser -> stack -> print)
		{
			print "$$item{type} = $$item{value}. \n";
		}

		print 'DN: ', $parser -> dn, ". \n";
	}
}

$count{fail} = $count{total} - $count{success};

print "\n";
print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
