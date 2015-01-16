package X500::DN::Marpa::RDN;

use parent 'X500::DN::Marpa';
use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Want;

our $VERSION = '0.80';

# ------------------------------------------------

sub getAttributeTypes
{
	my($self, $n) = @_;
	$n        = 1 if (! defined $n);
	my(@type) = @{$self -> get_rdn_types($n)};

	return want('LIST') ? @type : scalar @type;

} # End of getAttributeTypes.

# ------------------------------------------------

sub getAttributeValue
{
	my($self, $key) = @_;
	my(@value) = @{$self -> get_rdn_values($key)};

	return want('LIST') ? @value : $value[0];

} # End of getAttributeValue.

# ------------------------------------------------

1;
