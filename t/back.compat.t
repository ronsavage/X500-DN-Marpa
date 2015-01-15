#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use X500::DN::Marpa::BackCompat;

# -----------

my($test_count)  = 0;
my($parser)      = X500::DN::Marpa::BackCompat -> new;

isa_ok($parser, 'X500::DN::Marpa::BackCompat', 'new() returns correct object'); $test_count++;

# Test set 1.

my($text) = '';

diag "Parsing: $text.";

my($dn) = $parser -> ParseRFC2253($text);

ok($dn -> getRDNs          == 0,         'getRDNs() works');          $test_count++;
ok($dn -> getRFC2253String eq $text,     'getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq "{$text}", 'getX500String() works');    $test_count++;

# Test set 2.

$text = '1.4.9=2001';

diag "Parsing: $text.";

$dn = $parser -> ParseRFC2253($text);

ok($dn -> getRDNs          == 1,         'getRDNs() works');          $test_count++;
ok($dn -> getRFC2253String eq $text,     'getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq "{$text}", 'getX500String() works');    $test_count++;

my($rdn)       = $dn -> getRDN(0);
my $type_count = $rdn -> getAttributeTypes;
my(@types)     = $rdn -> getAttributeTypes;
my $value      = $rdn -> getAttributeValue('1.4.9');
my(@values)    = $rdn -> getAttributeValue('1.4.9');

ok($type_count == 1,       'getAttributeTypes() works'); $test_count++;
ok($types[0]   eq '1.4.9', 'getAttributeTypes() works'); $test_count++;
ok($value      eq '2001',  'getAttributeValue() works'); $test_count++;
ok($values[0]  eq '2001',  'getAttributeValue() works'); $test_count++;

# Test set 3.

$text = 'foo=FOO + bar=BAR + frob=FROB, baz=BAZ';

diag "Parsing: $text.";

$dn = $parser -> ParseRFC2253($text);

ok($dn -> getRDNs          == 2,                                     'getRDNs() works');         $test_count++;
ok($dn -> getRFC2253String eq "baz=BAZ,foo=FOO+bar=BAR+frob=FROB",   'getRFC2253String() works'); $test_count++;
ok($dn -> getX500String    eq "{foo=FOO+bar=BAR+frob=FROB+baz=BAZ}", 'getX500String() works');    $test_count++;

$rdn        = $dn -> getRDN(0);
$type_count = $rdn -> getAttributeTypes;
@types      = $rdn -> getAttributeTypes;
@values     = $rdn -> getAttributeValue('foo');

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
