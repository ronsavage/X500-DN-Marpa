#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa::BackCompat;

# -----------

my($test_count)  = 0;
my($parser)      = X500::DN::Marpa::BackCompat -> new;

isa_ok($parser, 'X500::DN::Marpa::BackCompat', 'new() returns correct object'); $test_count++;

# Tests 2-4: empty DN
my($dn) = $parser -> ParseRFC2253('');

ok($dn -> getRDNs          == 0,    'getRDNs() works');          $test_count++;
ok($dn -> getRFC2253String eq '',   'getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq '{}', 'getX500String() works');    $test_count++;

# Test 5-9: one RDN, RDN type is oid

$dn = $parser -> ParseRFC2253('foo=FOO + bar=BAR + frob=FROB, baz=BAZ');

ok($dn -> getRDNs() == 2, 'getRDNs() works'); $test_count++;

my($rdn)       = $dn -> getRDN(0);
my $type_count = $rdn -> getAttributeTypes;
my(@types)     = $rdn -> getAttributeTypes;
my(@values)    = $rdn -> getAttributeValue('foo');

diag 'getAttributeValue: ', join(', ', @values);

ok($type_count == 3,    'getAttributeTypes() works'); $test_count++;
ok($types[0] eq 'foo',  'getAttributeTypes() works'); $test_count++;
ok($types[1] eq 'bar',  'getAttributeTypes() works'); $test_count++;

ok($values[0] eq 'FOO+bar=BAR+frob=FROB', 'getAttributeValue() works'); $test_count++;

$rdn    = $dn -> getRDN(1);
@values = $rdn -> getAttributeValue('baz');

ok($values[0] eq 'BAZ', 'getAttributeValue() works'); $test_count++;

=pod

ok($rdn && $rdn->getAttributeValue ('1.4.9'), '2001');
ok($dn && $dn->getRFC2253String, '1.4.9=2001');

=cut

print "# Internal test count: $test_count\n";

done_testing($test_count);
