package X500::DN::Marpa::Actions;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

# ------------------------------------------------

sub attribute_type
{
	my($self, $t) = @_;

	return
	{
		type  => 'type',
		value => $t || '',
	};

} # End of attribute_type.

# ------------------------------------------------

sub attribute_value
{
	my($self, $t) = @_;

	return
	{
		type  => 'value',
		value => $t || '',
	};

} # End of attribute_value.

# ------------------------------------------------

1;
