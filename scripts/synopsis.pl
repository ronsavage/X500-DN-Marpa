#!/usr/bin/env perl

use strict;
use warnings;

use X500::DN::Marpa ':constants';

# -----------

my(%count)  = (fail => 0, success => 0, total => 0);
my($parser) = X500::DN::Marpa -> new
(
	options => debug,
);
my(@text) =
(
	q||,
	q|1.4.9=2001|,
	q|cn=Nemo,c=US|,
	q|cn=Nemo, c=US|,
	q|cn = Nemo, c = US|,
	q|cn=John Doe, o=Acme, c=US|,
	q|cn=John Doe, o=Acme\\, Inc., c=US|,
	q|x= |,
	q|x=\\ |,
	q|x = \\ |,
	q|x=\\ \\ |,
	q|x=\\#\"\\41|,
	q|x=#616263|,
	q|SN=Lu\C4\8Di\C4\87|,		# 'Lučić'.
);

my($result);

for my $text (@text)
{
	$count{total}++;

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
	}

	print '-' x 50, "\n";
}

$count{fail} = $count{total} - $count{success};

print "\n";
print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
