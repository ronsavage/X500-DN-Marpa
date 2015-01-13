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
	q|SN=Lu\C4\8Di\C4\87|,			# 'Lučić'.
	q|foo=1 + bar=2, baz=3|,
	q|UID=jsmith,DC=example,DC=net|,
	q|OU=Sales+CN=J.  Smith,DC=example,DC=net|,
	q|CN=James \"Jim\" Smith\, III,DC=example,DC=net|,
	q|CN=Before\0dAfter,DC=example,DC=net|,
	q|1.3.6.1.4.1.1466.0=#04024869|,
	q|UID=nobody@example.com,DC=example,DC=com|,
	q|CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US|,
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
