package X500::DN::Marpa::BackCompat;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use X500::DN::Marpa;

use Want;

my($dn);
my($rdn);

our $VERSION = '0.80';

# ------------------------------------------------

sub getAttributeTypes
{
	my($self, $n) = @_;
	$n        = 1 if (! defined $n);
	my(@type) = @{$rdn -> get_rdn_types($n)};

	return want('LIST') ? @type : scalar @type;

} # End of getAttributeTypes.

# ------------------------------------------------

sub getAttributeValue
{
	my($self, $key) = @_;
	my(@value) = @{$rdn -> get_rdn_values($key)};

	return want('LIST') ? @value : $value[0];

} # End of getAttributeValue.

# ------------------------------------------------

sub getRFC2253String
{
	my($self) = @_;

	return $dn -> dn;

} # End of getRFC2253String.

# ------------------------------------------------

sub getRDN
{
	my($self, $n) = @_;
	$rdn = X500::DN::Marpa -> new;

	$rdn -> parse($dn -> get_rdn($n + 1) );

	return $self;

} # End of getRDN.

# ------------------------------------------------

sub getRDNs
{
	my($self) = @_;

	return $dn -> get_rdn_number;

} # End of getRDNs.

# ------------------------------------------------

sub getX500String
{
	my($self) = @_;

	return '{' . $dn -> openssl_dn . '}';

} # End of getX500String.

# ------------------------------------------------

sub hasMultivaluedRDNs
{
	my($self)   = @_;
	my($result) = 0;

	for my $rdn ($dn -> stack -> print)
	{
		$result = 1 if ($$rdn{count} > 1);
	}

	return $result;

} # End of hasMultivaluedRDNs.

# ------------------------------------------------

sub new
{
	my($class) = @_;

	$dn = X500::DN::Marpa -> new;

	return bless({}, $class);

} # End of new.

# ------------------------------------------------

sub ParseRFC2253
{
	my($self, $text) = @_;

	$dn -> parse($text);

	return $self;

} # End of ParseRFC2253.

# ------------------------------------------------

1;
