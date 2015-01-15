package X500::DN::Marpa::BackCompat;

use parent 'X500::DN::Marpa';
use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Types::Standard qw/Any Int Str/;

has x =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub getRFC2253String
{
	my($self) = @_;

	return $self -> dn;

} # End of getRFC2253String.

# ------------------------------------------------

sub getRDN
{
	my($self, $n) = @_;

	return $self -> get_rdn($n + 1);

} # End of getRDN.

# ------------------------------------------------

sub getRDNs
{
	my($self) = @_;

	return $self -> get_rdn_number;

} # End of getRDNs.

# ------------------------------------------------

sub getX500String
{
	my($self) = @_;

	return '{' . $self -> openssl_dn . '}';

} # End of getX500String.

# ------------------------------------------------

sub ParseRFC2253
{
	my($self, $text) = @_;

	return $self -> parse($text);

} # End of ParseRFC2253.

# ------------------------------------------------

1;
