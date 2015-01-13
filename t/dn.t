#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa ':constants';

# -----------

my($count)  = 0;
my($parser) = X500::DN::Marpa -> new;
my(@text)   =
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
	q|SN=Lu\C4\8Di\C4\87|,		# 'Lui'.
);

my($result);

for my $text (@text)
{
	$count++;

	$result = $parser -> parse($text);

	ok($result == 0, "Parsed: |$text|");

	if ($result == 0)
	{
		for my $item ($parser -> stack -> print)
		{
			#diag "$$item{type} = $$item{value}.";
		}

	}
}

print "# Internal test count: $count\n";

done_testing($count);
