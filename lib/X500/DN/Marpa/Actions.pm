package X500::DN::Marpa::Actions;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

# ------------------------------------------------

sub attribute_type
{
	my($self, $t)    = @_;
	$t               = lc decode_result($t || '');
	my(%descriptors) =
	(
		commonname             => 'cn',
		countryname            => 'c',
		domaincomponent        => 'dc',
		localityname           => 'l',
		organizationalunitname => 'ou',
		organizationname       => 'o',
		stateorprovincename    => 'st',
		streetaddress          => 'street',
		userid                 => 'uid',
	);
	$t = $descriptors{$t} ? $descriptors{$t} : $t;

	return
	{
		type  => 'type',
		value => $t,
	};

} # End of attribute_type.

# ------------------------------------------------

sub attribute_value
{
	my($self, $t) = @_;

	return
	{
		type  => 'value',
		value => decode_result($t || ''),
	};

} # End of attribute_value.

# ------------------------------------------------

sub decode_result
{
	my($result)   = @_;
	my(@worklist) = $result;

	my($obj);
	my($ref_type);
	my(@stack);

	do
	{
		$obj      = shift @worklist;
		$ref_type = ref $obj;

		if ($ref_type eq 'ARRAY')
		{
			unshift @worklist, @$obj;
		}
		elsif ($ref_type eq 'HASH')
		{
			push @stack, {%$obj};
		}
		elsif ($ref_type)
		{
			die "Unsupported object type $ref_type\n";
		}
		else
		{
			push @stack, $obj;
		}

	} while (@worklist);

	return join('', @stack);

} # End of decode_result.

# ------------------------------------------------

1;
