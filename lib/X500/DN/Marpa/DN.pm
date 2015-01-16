package X500::DN::Marpa::DN;

use parent 'X500::DN::Marpa';
use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use X500::DN::Marpa::RDN;

our $VERSION = '0.80';

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
	my($rdn)      = X500::DN::Marpa::RDN -> new;

	$rdn -> parse($self -> rdn($n + 1) );

	return $rdn;

} # End of getRDN.

# ------------------------------------------------

sub getRDNs
{
	my($self) = @_;

	return $self -> rdn_number;

} # End of getRDNs.

# ------------------------------------------------

sub getX500String
{
	my($self) = @_;

	return '{' . $self -> openssl_dn . '}';

} # End of getX500String.

# ------------------------------------------------

sub hasMultivaluedRDNs
{
	my($self)   = @_;
	my($result) = 0;

	for my $rdn ($self -> stack -> print)
	{
		$result = 1 if ($$rdn{count} > 1);
	}

	return $result;

} # End of hasMultivaluedRDNs.

# ------------------------------------------------

sub ParseRFC2253
{
	my($self, $text) = @_;

	$self -> parse($text);

	return $self; # sic. See docs.

} # End of ParseRFC2253.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<X500::DN::Marpa::DN> - Backcompat module to emulate DN part of X500::DN

=head1 Synopsis

This is scripts/back.compat.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use X500::DN::Marpa::DN;
	use X500::DN::Marpa::RDN;

	# -----------------------

	print "Part 1:\n";

	my($dn)   = X500::DN::Marpa::DN -> new;
	my($text) = 'foo=FOO + bar=BAR + frob=FROB, baz=BAZ';

	$dn -> ParseRFC2253($text);

	print "Parsing:     $text\n";
	print 'RDN count:   ', $dn -> getRDNs, " (Expected: 2)\n";
	print 'DN:          ', $dn -> getRFC2253String, " (Expected: baz=BAZ,foo=FOO+bar=BAR+frob=FROB)\n";
	print 'X500 string: ', $dn -> getX500String, " (Expected: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ})\n";
	print '-' x 50, "\n";
	print "Part 2:\n";

	my($rdn)       = $dn -> getRDN(0);
	my $type_count = $rdn -> getAttributeTypes;
	my(@types)     = $rdn -> getAttributeTypes;

	print 'RDN(0):      ', $rdn -> dn, "\n";
	print "Type count:  $type_count (Expected: 3)\n";
	print "Type [0]:    $types[0] (Expected: foo)\n";
	print "Type [1]:    $types[1] (Expected: bar)\n";

	my(@values) = $rdn -> getAttributeValue('foo');

	print "Value [0]:   $values[0] (Expected: FOO+bar=BAR+frob=FROB)\n";

	my($has_multi) = $dn -> hasMultivaluedRDNs;

	print "hasMulti:    $has_multi (Expected: 1)\n";
	print '-' x 50, "\n";
	print "Part 2:\n";

	$rdn = $dn -> getRDN(1);

	@values = $rdn -> getAttributeValue('baz');

	print 'RDN(1):      ', $rdn -> dn, "\n";
	print "Value [0]:   $values[0] (Expected: BAZ)\n";
	print '-' x 50, "\n";

Output of scripts/back.compat.pl:

	Part 1:
	Parsing:     foo=FOO + bar=BAR + frob=FROB, baz=BAZ
	RDN count:   2 (Expected: 2)
	DN:          baz=BAZ,foo=FOO+bar=BAR+frob=FROB (Expected: baz=BAZ,foo=FOO+bar=BAR+frob=FROB)
	X500 string: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ} (Expected: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ})
	--------------------------------------------------
	Part 2:
	RDN(0):      foo=FOO+bar=BAR+frob=FROB
	Type count:  3 (Expected: 3)
	Type [0]:    foo (Expected: foo)
	Type [1]:    bar (Expected: bar)
	Value [0]:   FOO+bar=BAR+frob=FROB (Expected: FOO+bar=BAR+frob=FROB)
	hasMulti:    1 (Expected: 1)
	--------------------------------------------------
	Part 2:
	RDN(1):      baz=BAZ
	Value [0]:   BAZ (Expected: BAZ)
	--------------------------------------------------

See scripts/synopsis.pl.

This is part of the printout of synopsis.pl:

	# 3. Parsing |cn=Nemo,c=US|.
	Parse result: 0 (0 is success)
	commonName = Nemo. count = 1.
	countryName = US. count = 1.
	DN:         countryName=US,commonName=Nemo.
	OpenSSL DN: commonName=Nemo+countryName=US.
	--------------------------------------------------
	...
	--------------------------------------------------
	# 13. Parsing |x=#616263|.
	Parse result: 0 (0 is success)
	x = #616263. count = 1.
	DN:         x=#616263.
	OpenSSL DN: x=#616263.
	--------------------------------------------------
	...
	--------------------------------------------------
	# 15. Parsing |foo=FOO + bar=BAR + frob=FROB, baz=BAZ|.
	Parse result: 0 (0 is success)
	foo = FOO+bar=BAR+frob=FROB. count = 3.
	baz = BAZ. count = 1.
	DN:         baz=BAZ,foo=FOO+bar=BAR+frob=FROB.
	OpenSSL DN: foo=FOO+bar=BAR+frob=FROB+baz=BAZ.

If you set the option C<return_hex_as_chars>, as discussed in the L</FAQ>, then case 13 will print:

	# 13. Parsing |x=#616263|.
	Parse result: 0 (0 is success)
	x = abc. count = 1.
	DN:         x=abc.
	OpenSSL DN: x=abc.

=head1 Description

C<X500::DN::Marpa> provides a L<Marpa::R2>-based parser for parsing X.500 Distinguished Names.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<X500::DN::Marpa> as you would any C<Perl> module:

Run:

	cpanm X500::DN::Marpa

or run:

	sudo cpan X500::DN::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = X500::DN::Marpa -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<X500::DN::Marpa>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</options([$bit_string])>]):

=over 4

=item o options => $bit_string

This allows you to turn on various options.

Default: 0 (nothing is fatal).

See the L</FAQ> for details.

=item o text => $a_string_to_be_parsed

Default: ''.

=back

=head1 Methods

=head2 bnf()

Returns a string containing the grammar used by this module.

=head2 dn()

Returns the RDNs, separated by commas, as a single string in the reverse order compared with the
order of the RNDs in the input text.

The order reversal is discussed in section 2.1 of L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>.

Hence 'cn=Nemo, c=US' is returned as 'countryName=US,commonName=Nemo' (when the
C<long_descriptors> option is used), and as 'c=US,cn=Nemo' by default.

See also L</openssl_dn()>.

=head2 error_message()

Returns the last error or warning message set.

Error messages always start with 'Error: '. Messages never end with "\n".

Parsing error strings is not a good idea, ever though this module's format for them is fixed.

See L</error_number()>.

=head2 error_number()

Returns the last error or warning number set.

Warnings have values < 0, and errors have values > 0.

If the value is > 0, the message has the prefix 'Error: ', and if the value is < 0, it has the
prefix 'Warning: '. If this is not the case, it's a reportable bug.

Possible values for error_number() and error_message():

=over 4

=item o 0 => ""

This is the default value.

=item o 1/-1 => "Parse exhausted"

If L</error_number()> returns 1, it's an error, and if it returns -1 it's a warning.

You can set the option C<exhaustion_is_fatal> to make it fatal.

=item o 2/-2 => "Ambiguous parse. Status: $status. Terminals expected: a, b, ..."

This message is only produced when the parse is ambiguous.

If L</error_number()> returns 2, it's an error, and if it returns -2 it's a warning.

You can set the option C<ambiguity_is_fatal> to make it fatal.

=back

See L</error_message()>.

=head2 get_openssl_dn()

Returns the RDNs, separated by pluses, as a single string in the same order compared with the
order of the RNDs in the input text.

Hence 'cn=Nemo, c=US' is returned as 'commonName=Nemo+countryName=US' (when the
C<long_descriptors> option is used), and as 'cn=Nemo+c=US' by default.

See also L</dn()>.

=head2 get_rdn($n)

Returns a string containing the $n-th RDN, or returns '' if $n is out of range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<get_rdn(1)> returns
'uid=nobody@example.com'. Note the lower-case 'uid'.

See t/dn.t.

=head2 get_rdn_count($n)

Returns a string containing the $n-th RDN's count (multivalue indicator), or returns 0 if $n is out
of range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<get_rdn_count(1)> returns 1.

If the input is 'foo=FOO+bar=BAR+frob=FROB, baz=BAZ', C<get_rdn_count(1)> returns 3.

Not to be confused with L</get_rdn_number()>.

See t/dn.t.

=head2 get_rdn_number()

Returns the number of RDNs, which may be 0.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<get_rdn_number()> returns 3.

Not to be confused with L</get_rdn_count($n)>.

See t/dn.t.

=head2 get_rdn_type($n)

Returns a string containing the $n-th RDN's attribute type, or returns '' if $n is out of range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<get_rdn_type(1)> returns 'uid'.

See t/dn.t.

=head2 get_rdn_value($n)

Returns a string containing the $n-th RDN's attribute value, or returns '' if $n is out of
range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<get_rdn_type(1)> returns
'nobody@example.com'.

See t/dn.t.

=head2 get_rdn_values($type)

Returns an arrayref containing the RDN attribute values for the attribute type $type, or [].

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<get_rdn_type('DC')> returns
['example', 'com'].

See t/dn.t.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 options([$bit_string])

Here, the [] indicate an optional parameter.

Get or set the option flags.

For typical usage, see scripts/synopsis.pl.

See the L</FAQ> for details.

'options' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 parse([$string])

Here, the [] indicate an optional parameter.

This is the only method the user needs to call. All data can be supplied when calling L</new()>.

You can of course call other methods (e.g. L</text([$string])> ) after calling L</new()> but
before calling C<parse()>.

Note: If a string is passed to C<parse()>, it takes precedence over any string passed to
C<< new(text => $string) >>, and over any string passed to L</text([$string])>. Further,
the string passed to C<parse()> is passed to L</text([$string)>, meaning any subsequent
call to C<text()> returns the string passed to C<parse()>.

See scripts/synopsis.pl.

Returns 0 for success and 1 for failure.

If the value is 1, you should call L</error_number()> to find out what happened.

=head2 stack()

Returns an object of type L<Set::Array>, which holds the parsed data.

Obviously, it only makes sense to call C<stack()> after calling L</parse([$string])>.

The structure of elements in this stack is documented in the L</FAQ>.

See scripts/tiny.pl for sample code.

=head2 text([$string])

Here, the [] indicate an optional parameter.

Get or set a string to be parsed.

'text' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head1 FAQ

=head2 Where are the error messages and numbers described?

See L</error_message()> and L</error_number()>.

See also L</What are the possible values for the 'options' parameter to new()?> below.

=head2 What is the structure in RAM of the parsed data?

The module outputs a stack, which is an object of type L<Set::Array>. See L</stack()>.

Elements in this stack are in the same order as the RDNs are in the input string.

The L</dn()> method returns the RDNs, separated by commas, as a single string in the reverse order,
whereas L</openssl_dn()> separates them by pluses and uses the original order.

Each element of this stack is a hashref, with these (key => value) pairs:

=over 4

=item o count => $number

The number of attribute types and values in a (possibly multivalued) RDN.

$number counts from 1.

=item o type => $type

The attribute type.

=item o value => $value

The attribute value.

=back

Sample DNs:

Note: These examples assume the default case of the option C<long_descriptors> (discussed below)
I<not> being used.

If the input is 'UID=nobody@example.com,DC=example,DC=com', the stack will contain:

=over 4

=item o [0]: {count => 1, type => 'uid', value => 'nobody@example.com'}

=item o [1]: {count => 1, type => 'dc', value => 'example'}

=item o [2]: {count => 1, type => 'dc', value => 'com'}

=back

If the input is 'foo=FOO+bar=BAR+frob=FROB, baz=BAZ', the stack will contain:

=over 4

=item o [0]: {count => 3, type => 'foo', value => 'FOO+bar=BAR+frob=FROB'}

=item o [1]: {count => 1, type => 'baz', value => 'BAZ'}

=back

Sample Code:

A typical script uses code like this (copied from scripts/tiny.pl):

	$result = $parser -> parse($text);

	print "Parse result: $result (0 is success)\n";

	if ($result == 0)
	{
		for my $item ($parser -> stack -> print)
		{
			print "$$item{type} = $$item{value}. count = $$item{count}. \n";
		}
	}

If the option C<long_descriptors> is I<not> used in the call to L</new()>, then $$item{type}
defaults to lower-case. L<RFC4512|https://www.ietf.org/rfc/rfc4512.txt> says 'Short names are case
insensitive....'. I've chosen to use lower-case as the canonical form output by my code.

If that option I<is> used, then some types are output in mixed case. The list of such types is given
in section 3 (at the top of page 6) in L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>. This
document is one of those listed in L</References>, below.

For a discussion of the mixed-case descriptors, see
L</What are the possible values for the 'options' parameter to new()?> below.

An extended list of such long descriptors is given in section 4 (page 25) in
L<RFC4519|https://www.ietf.org/rfc/rfc4519.txt>. Note that 'streetAddress' is missing from this
list.

=head2 What are the possible values for the 'options' parameter to new()?

Firstly, to make these constants available, you must say:

	use X500::DN::Marpa ':constants';

Secondly, more detail on errors and warnings can be found at L</error_number()>.

Thirdly, for usage of these option flags, see scripts/synopsis.pl and scripts/tiny.pl.

Now the flags themselves:

=over 4

=item o nothing_is_fatal

This is the default.

C<nothing_is_fatal> has the value of 0.

=item o print_errors

Print error messages if this flag is set.

C<print_errors> has the value of 1.

=item o print_warnings

Print various warnings if this flag is set:

=over 4

=item o The ambiguity status and terminals expected, if the parse is ambiguous

=item o See L</error_number()> for other warnings which might be printed

Ambiguity is not, in and of itself, an error. But see the C<ambiguity_is_fatal> option, below.

=back

It's tempting to call this option C<warnings>, but Perl already has C<use warnings>, so I didn't.

C<print_warnings> has the value of 2.

=item o print_debugs

Print extra stuff if this flag is set.

C<print_debugs> has the value of 4.

=item o ambiguity_is_fatal

This makes L</error_number()> return 2 rather than -2.

C<ambiguity_is_fatal> has the value of 8.

=item o exhaustion_is_fatal

This makes L</error_number()> return 1 rather than -1.

C<exhaustion_is_fatal> has the value of 16.

=item o long_descriptors

This makes the C<type> key in the output stack's elements contain long descriptor names rather than
abbreviations.

For example, if the input was 'cn=Nemo,c=US', the output stack would contain, I<by default>, i.e.
without setting this option:

=over 4

=item o [0]: {count => 1, type => 'cn', value => 'Nemo'}

=item o [1]: {count => 1, type => 'c', value => 'US'}

=back

However, if this option is set, the output will contain:

=over 4

=item o [0]: {count => 1, type => 'commonName', value => 'Nemo'}

=item o [1]: {count => 1, type => 'countryName', value => 'US'}

=back

C<long_descriptors> has the value of 32.

=item o return_hex_as_chars

This triggers extra processing of attribute values which start with '#':

=over 4

=item o The value is assumed to consist entirely of hex digits (after the '#' is discarded)

=item o The digits are converted 2 at-a-time into a string of (presumably ASCII) characters

=item o These characters are concatenated into a single string, which becomes the new value

=back

So, if this option is I<not> used, 'x=#616263' is parsed as {type => 'x', value => '#616263'},
but if the option I<is> used, you get {type => 'x', value => 'abc'}.

C<return_hex_as_chars> has the value of 64.

=back

=head2 Does this package support Unicode/UTF8?

Handling of UTF8 is discussed in one of the RFCs listed in L</References>, below.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 References

I found RFCs 4514 and 4512 to be the most directly relevant ones.

L<RFC Index|https://www.ietf.org/rfc/rfc-index.txt>: The Index. Just search for 'LDAP'.

L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>:
Lightweight Directory Access Protocol (LDAP): String Representation of Distinguished Names.

L<RFC4512|https://www.ietf.org/rfc/rfc4512.txt>:
Lightweight Directory Access Protocol (LDAP): Directory Information Models.

L<RFC4517|https://www.ietf.org/rfc/rfc4517.txt>:
Lightweight Directory Access Protocol (LDAP): Syntaxes and Matching Rules.

L<RFC4234|https://www.ietf.org/rfc/rfc4234.txt>:
Augmented BNF for Syntax Specifications: ABNF.

L<RFC3629|https://www.ietf.org/rfc/rfc3629.txt>: UTF-8, a transformation format of ISO 10646.

RFC4514 also discusses UTF8. Search it using the string 'UTF-8'.

=head1 See Also

L<X500::DN>. Note: This module is based on the obsolete
L<RFC2253|https://www.ietf.org/rfc/rfc2253.txt>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/X500-DN-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=X500::DN::Marpa>.

=head1 Author

L<X500::DN::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
