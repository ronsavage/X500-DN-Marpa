#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa ':constants';

# -----------

my($test_count)  = 0;
my($parser)      = X500::DN::Marpa -> new;
my(@text)        =
(
	[0, 1, '', q|x|],	# Deliberate error.
	[0, 0, '', q||],
	[1, 1, 'x=', q|x=|],	# No error.
	[1, 1, 'x=', q|x= |],	# No error.
	[1, 1, q|1.4.9=2001|, q|1.4.9=2001|],
	[2, 1, q|cn=Nemo|, q|cn=Nemo,c=US|],
	[2, 1, q|cn=Nemo|, q|cn=Nemo, c=US|],
	[2, 1, q|cn=Nemo|, q|cn = Nemo, c = US|],
	[3, 1, q|cn=John Doe|, q|cn=John Doe, o=Acme, c=US|],
	[3, 1, q|cn=John Doe|, q|cn=John Doe, o=Acme\\, Inc., c=US|],
	[1, 1, q|x=\ |, q|x=\\ |],
	[1, 1, q|x=\ |, q|x = \\ |],
	[1, 1, q|x=\ \ |, q|x=\\ \\ |],
	[1, 1, q|x=\#\"\41|, q|x=\\#\"\\41|],
	[1, 1, q|x=abc|, q|x=#616263|],
	[1, 1, q|sn=Lu\C4\8Di\C4\87|, q|SN=Lu\C4\8Di\C4\87|],			# 'Lučić'.
	[2, 3, q|foo=FOO+bar=BAR+frob=FROB|, q|foo=FOO + bar=BAR + frob=FROB, baz=BAZ|],
	[3, 1, q|uid=jsmith|, q|UID=jsmith,DC=example,DC=net|],
	[3, 2, q|ou=Sales+cn=J. Smith|, q|OU=Sales+CN=J. Smith,DC=example,DC=net|],
	[3, 1, q|cn=James \"Jim\" Smith\, III|, q|CN=James \"Jim\" Smith\, III,DC=example,DC=net|],
	[3, 1, q|cn=Before\0dAfter|, q|CN=Before\0dAfter,DC=example,DC=net|],
	[3, 1, q|uid=nobody@example.com|, q|UID=nobody@example.com,DC=example,DC=com|],
	[6, 1, q|cn=John Smith|, q|CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US|], # Must be last.
);

$parser -> options(return_hex_as_chars);

my($first);
my($get_count, $get_length, $get_rdn, $get_type, $get_value);
my($result, $rdn_count, $rdn_length);
my($text, $type);
my($value);

for my $item (@text)
{
	$test_count++;

	$rdn_length     = $$item[0];
	$rdn_count      = $$item[1];
	$first          = $$item[2];
	($type, $value) = split(/=/, $first, 2);
	$type           = '' if (! defined $type);
	$value          = '' if (! defined $value);
	$text           = $$item[3];
	$result         = $parser -> parse($text);

	if ($test_count == 1)
	{
		ok($result == 1, "Failed deliberate error: |$text|");
	}
	else
	{
		ok($result == 0, "Parsed: |$text|");
	}

	if ($result == 0)
	{
		$get_count  = $parser -> get_rdn_count(1);
		$get_length = $parser -> get_rdn_length;
		$get_rdn    = $parser -> get_rdn(1);
		$get_type   = $parser -> get_rdn_type(1)  || '';
		$get_value  = $parser -> get_rdn_value(1) || '';

		ok($rdn_count  == $get_count,  'get_rdn_count(1) works'); $test_count++;
		ok($rdn_length == $get_length, 'get_rdn_length() works'); $test_count++;
		ok($first      eq $get_rdn,    'get_rdn(1) works');       $test_count++;
		ok($type       eq $get_type,   'get_rdn_type(1) works');  $test_count++;
		ok($value      eq $get_value,  'get_rdn_value(1) works'); $test_count++;
	}
}

$text    = 'CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US';
$result  = $parser -> parse($text);
my(@rdn) = split(/,/, $text);

for my $rdn (@rdn)
{
	($type, $value) = split(/=/, $rdn);

	ok($value eq ${$parser -> get_rdn_values($type)}[0], "get_rdn_value($type) works"); $test_count++;
}

$text   = 'UID=nobody@example.com,DC=example,DC=com';
$result = $parser -> parse($text);
@rdn    = @{$parser -> get_rdn_values('DC')};

ok($rdn[0] eq 'example', "get_rdn_values('DC') works"); $test_count++;
ok($rdn[1] eq 'com',     "get_rdn_values('DC') works"); $test_count++;

print "# Internal test count: $test_count\n";

done_testing($test_count);
