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
	[0, undef, q|x|],	# Deliberate error.
	[1, undef, q|x= |],	# Deliberate error.
	[0, undef, q||],
	[1, q|1.4.9=2001|, q|1.4.9=2001|],
	[2, q|cn=Nemo|, q|cn=Nemo,c=US|],
	[2, q|cn=Nemo|, q|cn=Nemo, c=US|],
	[2, q|cn=Nemo|, q|cn = Nemo, c = US|],
	[3, q|cn=John Doe|, q|cn=John Doe, o=Acme, c=US|],
	[3, q|cn=John Doe|, q|cn=John Doe, o=Acme\\, Inc., c=US|],
	[1, q|x=\ |, q|x=\\ |],
	[1, q|x=\ |, q|x = \\ |],
	[1, q|x=\ \ |, q|x=\\ \\ |],
	[1, q|x=\#\"\41|, q|x=\\#\"\\41|],
	[1, q|x=abc|, q|x=#616263|],
	[1, q|sn=Lu\C4\8Di\C4\87|, q|SN=Lu\C4\8Di\C4\87|],			# 'Lučić'.
	[2, q|foo=1|, q|foo=1 + bar=2, baz=3|],
	[3, q|uid=jsmith|, q|UID=jsmith,DC=example,DC=net|],
	[3, q|ou=Sales|, q|OU=Sales+CN=J. Smith,DC=example,DC=net|],
	[3, q|cn=James \"Jim\" Smith\, III|, q|CN=James \"Jim\" Smith\, III,DC=example,DC=net|],
	[3, q|cn=Before\0dAfter|, q|CN=Before\0dAfter,DC=example,DC=net|],
	[3, q|uid=nobody@example.com|, q|UID=nobody@example.com,DC=example,DC=com|],
	[6, q|cn=John Smith|, q|CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US|], # Must be last.
);

$parser -> options(return_hex_as_chars);

my($first);
my($result, $rdn_count, $rdn);
my($type, $text, $temp);
my($value);

for my $item (@text)
{
	$count++;

	$rdn_count = $$item[0];
	$first     = $$item[1];
	$type      = defined($first) ? (split(/=/, $first) )[0] : undef;
	$value     = defined($first) ? (split(/=/, $first) )[1] : undef;
	$text      = $$item[2];
	$result    = $parser -> parse($text);

	if ( ($count == 1) || ($count == 2) )
	{
		ok($result == 1, "Failed deliberate error: |$text|");
	}
	else
	{
		ok($result == 0, "Parsed: |$text|");
	}

	if ($result == 0)
	{
		ok($rdn_count == $parser -> get_rdn_count, 'get_rdn_count() works');   $count++;

		$rdn = $parser -> get_rdn(1);

		ok(! defined($rdn) || ($first eq $rdn),    'get_rdn($n) works');       $count++;

		$temp = $parser -> get_rdn_type(1);

		ok(! defined($type) || ($type eq $temp),   'get_rdn_type($n) works');  $count++;

		# This will return undef for an RDN of 'x='.

		$temp = $parser -> get_rdn_value(1);

		ok(! defined($value) || ($value eq $temp),  'get_rdn_value($n) works'); $count++;
	}
}

$text    = 'CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US';
$result  = $parser -> parse($text);
my(@rdn) = split(/,/, $text);

for $rdn (@rdn)
{
	($type, $value) = split(/=/, $rdn);

	ok($value eq ${$parser -> get_rdn_value($type)}[0], "get_rdn_value($type) works"); $count++;
}

$text   = 'UID=nobody@example.com,DC=example,DC=com';
$result = $parser -> parse($text);
@rdn    = @{$parser -> get_rdn_value('DC')};

ok($rdn[0] eq 'example', "get_rdn_value('DC') works"); $count++;
ok($rdn[1] eq 'com',     "get_rdn_value('DC') works"); $count++;

print "# Internal test count: $count\n";

done_testing($count);
