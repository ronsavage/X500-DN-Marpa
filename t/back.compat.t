#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa::BackCompat;

# -----------

my($test_count)  = 0;
my($parser)      = X500::DN::Marpa::BackCompat -> new;
my(@text)        =
(
	[0, q||, q|{}|, q||, q||],
	[1, q|1.4.9=2001|, q|{1.4.9=2001}|, q|1.4.9=2001|, q|1.4.9=2001|],
	[2, q|c=US,cn=Nemo|, q|{cn=Nemo+c=US}|, q|cn=Nemo|, q|cn=Nemo,c=US|],
);

my($dn);
my($get_dn, $get_length, $get_x500_dn, $get_rdn);
my($result, $rdn_length, $rdn);
my($text);
my($x500_dn);

for my $item (@text)
{
	$rdn_length = $$item[0];
	$dn         = $$item[1];
	$x500_dn    = $$item[2];
	$rdn        = $$item[3];
	$text       = $$item[4];
	$result     = $parser -> ParseRFC2253($text);

	ok($result == 0, "ParseRFC2253($text) works"); $test_count++;

	if ($result == 0)
	{
		$get_dn      = $parser -> getRFC2253String;
		$get_length  = $parser -> getRDNs;
		$get_x500_dn = $parser -> getX500String;
		$get_rdn     = $parser -> getRDN(0);

		diag 'get_rdn: <' . $get_rdn . '>';

		ok($dn         eq $get_dn,      'getRFC2253String() works'); $test_count++;
		ok($rdn_length == $get_length,  'getRDNs() works');          $test_count++;
		ok($x500_dn    eq $get_x500_dn, 'getX500String() works');    $test_count++;
	}

}

print "# Internal test count: $test_count\n";

done_testing($test_count);
