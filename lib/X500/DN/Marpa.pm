package X500::DN::Marpa;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	nothing_is_fatal    =>  0, # The default.
	debug               =>  1,
	print_warnings      =>  2,
	ambiguity_is_fatal  =>  4,
	exhaustion_is_fatal =>  8,
];

use Data::Dumper::Concise; # For Dumper().

use Marpa::R2;

use Moo;

use Set::Array;

use Tree;

use Types::Standard qw/Any Int Str/;

use Try::Tiny;

use X500::DN::Marpa::Actions;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has error_message =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has error_number =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has options =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has stack =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has text =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Policy: Event names are always the same as the name of the corresponding lexeme.
	#
	# References:
	# o https://www.ietf.org/rfc/rfc4512.txt (secondary)
	#	- Lightweight Directory Access Protocol (LDAP): Directory Information Models
	# o https://www.ietf.org/rfc/rfc4514.txt (primary)
	#   - Lightweight Directory Access Protocol (LDAP): String Representation of Distinguished Names
	# o https://www.ietf.org/rfc/rfc4517.txt
	#	- Lightweight Directory Access Protocol (LDAP): Syntaxes and Matching Rules
	# o https://www.ietf.org/rfc/rfc4234.txt
	#	- Augmented BNF for Syntax Specifications: ABNF
	# o https://www.ietf.org/rfc/rfc3629.txt
	#	- UTF-8, a transformation format of ISO 10646

	my($bnf) = <<'END_OF_GRAMMAR';

:default			::= action => [values]

lexeme default		= latm => 1

:start				::= dn

# dn.

dn					::=
dn					::= rdn
						| rdn comma dn

rdn					::= attribute_pair				# rank => 1
						| attribute_pair plus rdn	# rank => 2

attribute_pair		::= attribute_type equals attribute_value

# attribute_type.

attribute_type		::= description				action => attribute_type
						| numeric_oid			action => attribute_type

description			::= description_prefix description_suffix

description_prefix	::= alpha

description_suffix	::= description_tail*

description_tail	::= alpha
						| digit
						| hyphen

numeric_oid			::= number oid_suffix

number				::= digit
						| digit_sequence

digit_sequence		::= non_zero_digit digit_suffix

digit_suffix		::= digit+

oid_suffix			::= oid_sequence+

oid_sequence		::= dot number

# attribute_value.

attribute_value		::= string					action => attribute_value
						| hex_string			action => attribute_value

string				::=
string				::= string_prefix string_suffix

string_prefix		::= lutf1
						| utfmb
						| pair

utfmb				::= utf2
						| utf3
						| utf4

utf2				::= utf2_prefix utf2_suffix

utf3				::= utf3_prefix_1 utf3_suffix_1
						| utf3_prefix_2 utf3_suffix_2
						| utf3_prefix_3 utf3_suffix_3
						| utf3_prefix_4 utf3_suffix_4

utf4				::= utf4_prefix_1 utf4_suffix_1
						| utf4_prefix_2 utf4_suffix_2
						| utf4_prefix_3 utf4_suffix_3

pair				::= escape_char escaped_char

escaped_char		::= escape_char
						| special_char
						| hex_pair

string_suffix		::=
string_suffix		::= string_suffix_1 string_suffix_2

string_suffix_1		::= string_suffix_1_1*

string_suffix_1_1	::= sutf1
						| utfmb
						| pair

string_suffix_2		::= tutf1
						| utfmb
						| pair

hex_string			::= sharp hex_suffix

hex_suffix			::= hex_pair+

hex_pair			::= hex_digit hex_digit

# Lexemes in alphabetical order.

alpha				~ [A-Za-z]		# [\x41-\x5a\x61-\x7a].

comma				~ ','			# [\x2c].

digit				~ [0-9]			# [\x30-\x39].

dot					~ '.'			# [\x2e].

equals				~ '='			# [\x3d].

escape_char			~ '\'			# [\x5c]. Use ' in comment for UltraEdit syntax hiliter.

hex_digit			~ [0-9A-Fa-f]	# [\x30-\x39\x41-\x46\x61-\x66].

hyphen				~ '-'

# \x01-\x1f: All control chars except the first (^@). Skip [ ] = [\x20].
# \x21:      !. Skip ["#] = [\x22\x23].
# \x24-\x2a: $%&'()*. Skip: [+,] = [\x2b\x2c].
# \x2d-\x3a: -./0123456789:. Skip [;<] = [\x3b\x3c].
# \x3d:      =.
# \x3f-\x5b: ?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[.
# \x5d-\x7f: ]^_`abcdefghijklmnopqrstuvwxyz{|}~ and DEL.

lutf1				~ [\x01-\x1f\x21\x24-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]

non_zero_digit		~ [1-9]			# [\x31-\x39].

plus				~ '+'			# [\x2b].

sharp				~ '#'			# [\x23].

special_char		~ ["+,;<> #=]	# Use " in comment for UltraEdit syntax hiliter.

sutf1				~ [\x01-\x21\x23-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]

tutf1				~ [\x01-\x1f\x21\x23-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]

utf0				~ [\x80-\xbf]

utf2_prefix			~ [\xc2-\xdf]

utf2_suffix			~ utf0

utf3_prefix_1		~ [\xe0\xa0-\xbf]

utf3_suffix_1		~ utf0

utf3_prefix_2		~ [\xe1-\xec]

utf3_suffix_2		~ utf0 utf0

utf3_prefix_3		~ [\xed\x80-\x9f]

utf3_suffix_3		~ utf0

utf3_prefix_4		~ [\xee-\xef]

utf3_suffix_4		~ utf0 utf0

utf4_prefix_1		~ [\xf0\x90-\xbf]

utf4_suffix_1		~ utf0 utf0

utf4_prefix_2		~ [\xf1-\xf3]

utf4_suffix_2		~ utf0 utf0 utf0

utf4_prefix_3		~ [\xf4\x80-\x8f]

utf4_suffix_3		~ utf0 utf0

:discard			~ whitespace
whitespace			~ [\s]+

END_OF_GRAMMAR

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

} # End of BUILD.

# ------------------------------------------------

sub decode_result
{
	my($self, $result) = @_;
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

	return [@stack];

} # End of decode_result.

# ------------------------------------------------

sub parse
{
	my($self, $string) = @_;
	$self -> text($string) if (defined $string);

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			exhaustion        => 'event',
			grammar           => $self -> grammar,
			#ranking_method    => 'high_rule_only',
			semantics_package => 'X500::DN::Marpa::Actions',
		})
	);

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		my($text)        = $self -> text;
		my($text_length) = length($text);
		my($read_length) = $self -> recce -> read(\$text);

		if ($text_length != $read_length)
		{
			die "Text is $text_length characters, but read() only read $read_length characters. \n";
		}

		if ($self -> recce -> exhausted)
		{
			$message = 'Parse exhausted';

			$self -> error_message($message);
			$self -> error_number(6);

			if ($self -> options & exhaustion_is_fatal)
			{
				# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

				die "$message\n";
			}
			else
			{
				$self -> error_number(-6);

				print "Warning: $message\n" if ($self -> options & print_warnings);
			}
		}
		elsif (my $ambiguous_status = $self -> recce -> ambiguous)
		{
			chomp $ambiguous_status;

			die "Parse is ambiguous. Status: $ambiguous_status. \n";
		}

		my($value_ref) = $self -> recce -> value;

		if (defined $value_ref)
		{
			$self -> stack(Set::Array -> new);

			my($count) = 0;

			my($type);
			my($value);

			for my $item (@{$self -> decode_result($$value_ref)})
			{
				next if (! defined($item) || ($item =~ /^[=,;+]$/) );

				$count++;

				if ( ($count % 2) == 1)
				{
					# This line uses $$item{value}, not $$item{type}!

					$type  = join('', @{$self -> decode_result($$item{value})});
				}
				else
				{
					$value = join('', @{$self -> decode_result($$item{value})});

					$self -> stack -> push({type => $type, value => $value});
				}
			}
		}
		else
		{
			$result = 1;

			print "Error: Parse failed\n";
		}
	}
	catch
	{
		$result = 1;

		print "Error: Parse failed. ${_}";
	};

	# Return 0 for success and 1 for failure.

	return $result;

} # End of parse.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Text::Balanced::Marpa> - Extract delimited text sequences from strings

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Text::Balanced::Marpa ':constants';

	# -----------

	my($count)  = 0;
	my($parser) = Text::Balanced::Marpa -> new
	(
		open    => ['<:' ,'[%'],
		close   => [':>', '%]'],
		options => nesting_is_fatal | print_warnings,
	);
	my(@text) =
	(
		q|<: a :>|,
		q|a [% b <: c :> d %] e|,
		q|a <: b <: c :> d :> e|, # nesting_is_fatal triggers an error here.
	);

	my($result);

	for my $text (@text)
	{
		$count++;

		print "Parsing |$text|\n";

		$result = $parser -> parse(\$text);

		print join("\n", @{$parser -> tree -> tree2string}), "\n";
		print "Parse result: $result (0 is success)\n";

		if ($count == 3)
		{
			print "Deliberate error: Failed to parse |$text|\n";
			print 'Error number: ', $parser -> error_number, '. Error message: ',
					$parser -> error_message, "\n";
		}

		print '-' x 50, "\n";
	}

See scripts/synopsis.pl.

This is the printout of synopsis.pl:

	Parsing |<: a :>|
	Parsed text:
	root. Attributes: {}
	   |--- open. Attributes: {text => "<:"}
	   |   |--- string. Attributes: {text => " a "}
	   |--- close. Attributes: {text => ":>"}
	Parse result: 0 (0 is success)
	--------------------------------------------------
	Parsing |a [% b <: c :> d %] e|
	Parsed text:
	root. Attributes: {}
	   |--- string. Attributes: {text => "a "}
	   |--- open. Attributes: {text => "[%"}
	   |   |--- string. Attributes: {text => " b "}
	   |   |--- open. Attributes: {text => "<:"}
	   |   |   |--- string. Attributes: {text => " c "}
	   |   |--- close. Attributes: {text => ":>"}
	   |   |--- string. Attributes: {text => " d "}
	   |--- close. Attributes: {text => "%]"}
	   |--- string. Attributes: {text => " e"}
	Parse result: 0 (0 is success)
	--------------------------------------------------
	Parsing |a <: b <: c :> d :> e|
	Error: Parse failed. Opened delimiter <: again before closing previous one
	Text parsed so far:
	root. Attributes: {}
	   |--- string. Attributes: {text => "a "}
	   |--- open. Attributes: {text => "<:"}
	       |--- string. Attributes: {text => " b "}
	Parse result: 1 (0 is success)
	Deliberate error: Failed to parse |a <: b <: c :> d :> e|
	Error number: 2. Error message: Opened delimiter <: again before closing previous one
	--------------------------------------------------

=head1 Description

L<Text::Balanced::Marpa> provides a L<Marpa::R2>-based parser for extracting delimited text
sequences from strings.

See the L</FAQ> for various topics, including:

=over 4

=item o UFT8 handling

See t/utf8.t.

=item o Escaping delimiters within the text

See t/escapes.t.

=item o Options to make nested and/or overlapped delimiters fatal errors

See t/colons.t.

=item o Using delimiters which are part of another delimiter

See t/escapes.t and t/perl.delimiters.

=item o Processing the tree-structured output

See scripts/traverse.pl.

=item o Emulating L<Text::Xslate>'s use of '<:' and ':>

See t/colons.t and t/percents.t.

=item o Implementing a really trivial HTML parser

See scripts/traverse.pl and t/html.t.

In the same vein, see t/angle.brackets.t, for code where the delimiters are just '<' and '>'.

=item o Handling multiple sets of delimiters

See t/multiple.delimiters.t.

=item o Skipping (leading) characters in the input string

See t/skip.prefix.t.

=item o Implementing hard-to-read text strings as delimiters

See t/silly.delimiters.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Text::Balanced::Marpa> as you would any C<Perl> module:

Run:

	cpanm Text::Balanced::Marpa

or run:

	sudo cpan Text::Balanced::Marpa

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

C<new()> is called as C<< my($parser) = Text::Balanced::Marpa -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Text::Balanced::Marpa>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</text([$string])>]):

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

Returns a string containing the grammar constructed based on user input.

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

=item o 1/-1 => "Last open delimiter: $lexeme_1. Unexpected closing delimiter: $lexeme_2"

If L</error_number()> returns 1, it's an error, and if it returns -1 it's a warning.

You can set the option C<overlap_is_fatal> to make it fatal.

=item o 2/-2 => "Opened delimiter $lexeme again before closing previous one"

If L</error_number()> returns 2, it's an error, and if it returns -2 it's a warning.

You can set the option C<nesting_is_fatal> to make it fatal.

=item o 3/-3 => "Ambiguous parse. Status: $status. Terminals expected: a, b, ..."

This message is only produced when the parse is ambiguous.

If L</error_number()> returns 3, it's an error, and if it returns -3 it's a warning.

You can set the option C<ambiguity_is_fatal> to make it fatal.

=item o 4 => "Backslash is forbidden as a delimiter character"

This preempts some types of sabotage.

This message can never be just a warning message.

=item o 5 => "Single-quotes are forbidden in multi-character delimiters"

This limitation is due to the syntax of
L<Marpa's DSL|https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod>.

This message can never be just a warning message.

=item o 6/-6 => "Parse exhausted"

If L</error_number()> returns 6, it's an error, and if it returns -6 it's a warning.

You can set the option C<exhaustion_is_fatal> to make it fatal.

=item o 7 => 'Single-quote is forbidden as an escape character'

This limitation is due to the syntax of
L<Marpa's DSL|https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod>.

This message can never be just a warning message.

=item o 8 => "There must be at least 1 pair of open/close delimiters"

This message can never be just a warning message.

=item o 9 => "The # of open delimiters must match the # of close delimiters"

This message can never be just a warning message.

=item o 10 => "Unexpected event name 'xyz'"

Marpa has trigged an event and it's name is not in the hash of event names derived from the BNF.

This message can never be just a warning message.

=item o 11 => "The code does not handle these events simultaneously: a, b, ..."

The code is written to handle single events at a time, or in rare cases, 2 events at the same time.
But here, multiple events have been triggered and the code cannot handle the given combination.

This message can never be just a warning message.

=back

See L</error_message()>.

=head2 escape_char()

Get the escape char.

=head2 known_events()

Returns a hashref where the keys are event names and the values are 1.

=head2 length([$integer])

Here, the [] indicate an optional parameter.

Get or set the length of the input string to process.

See also the L</FAQ> and L</pos([$integer])>.

'length' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 matching_delimiter()

Returns a hashref where the keys are opening delimiters and the values are the corresponding closing
delimiters.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 open()

Get the arrayref of opening delimiters.

See also L</close()>.

See the L</FAQ> for details and warnings.

'open' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

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

See scripts/samples.pl.

Returns 0 for success and 1 for failure.

If the value is 1, you should call L</error_number()> to find out what happened.

=head2 pos([$integer])

Here, the [] indicate an optional parameter.

Get or set the offset within the input string at which to start processing.

See also the L</FAQ> and L</length([$integer])>.

'pos' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 text([$string])

Here, the [] indicate an optional parameter.

Get or set a string to be parsed.

'text' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 tree()

Returns an object of type L<Tree>, which holds the parsed data.

Obviously, it only makes sense to call C<tree()> after calling C<parse()>.

See scripts/traverse.pl for sample code which processes this tree's nodes.

=head1 FAQ

=head2 Where are the error messages and numbers described?

See L</error_message()> and L</error_number()>.

=head2 How do I escape delimiters?

By backslash-escaping the first character of all open and close delimiters which appear in the
text.

As an example, if the delimiters are '<:' and ':>', this means you have to escape I<all> the '<'
chars and I<all> the colons in the text.

The backslash is preserved in the output.

If you don't want to use backslash for escaping, or can't, you can pass a different escape character
to L</new()>.

See t/escapes.t.

=head2 Does this package support Unicode/UTF8?

Yes. See t/escapes.t, t/multiple.quotes.t and t/utf8.t.

=head2 Does this package handler Perl delimiters (e.g. q|..|, qq|..|, qr/../, qw/../)?

See t/perl.delimiters.t.

=head2 What are the possible values for the 'options' parameter to new()?

Firstly, to make these constants available, you must say:

	use Text::Balanced::Marpa ':constants';

Secondly, more detail on errors and warnings can be found at L</error_number()>.

Thirdly, for usage of these option flags, see t/angle.brackets.t, t/colons.t, t/escapes.t,
t/multiple.quotes.t, t/percents.t and scripts/samples.pl.

Now the flags themselves:

=over 4

=item o nothing_is_fatal

This is the default.

It's value is 0.

=item o debug

Print extra stuff if this flag is set.

It's value is 1.

=item o print_warnings

Print various warnings if this flag is set:

=over 4

=item o The ambiguity status and terminals expected, if the parse is ambiguous

=item o See L</error_number()> for other warnings which might be printed

Ambiguity is not, in and of itself, an error. But see the C<ambiguity_is_fatal> option, below.

=back

It's tempting to call this option C<warnings>, but Perl already has C<use warnings>, so I didn't.

It's value is 2.

=item o overlap_is_fatal

This means overlapping delimiters cause a fatal error.

So, setting C<overlap_is_fatal> means '{Bold [Italic}]' would be a fatal error.

I use this example since it gives me the opportunity to warn you, this will I<not> do what you want
if you try to use the delimiters of '<' and '>' for HTML. That is, '<i><b>Bold Italic</i></b>' is
not an error because what overlap are '<b>' and '</i>' BUT THEY ARE NOT TAGS. The tags are '<' and
'>', ok? See also t/html.t.

It's value is 4.

=item o nesting_is_fatal

This means nesting of identical opening delimiters is fatal.

So, using C<nesting_is_fatal> means 'a <: b <: c :> d :> e' would be a fatal error.

It's value is 8.

=item o ambiguity_is_fatal

This makes L</error_number()> return 3 rather than -3.

It's value is 16.

=item o exhaustion_is_fatal

This makes L</error_number()> return 6 rather than -6.

It's value is 32.

=back

=head2 How do I print the tree built by the parser?

See L</Synopsis>.

=head2 How do I make use of the tree built by the parser?

See scripts/traverse.pl. It is a copy of t/html.t with tree-walking code instead of test code.

=head2 How is the parsed data held in RAM?

The parsed output is held in a tree managed by L<Tree>.

The tree always has a root node, which has nothing to do with the input data. So, even an empty
imput string will produce a tree with 1 node. This root has an empty hashref associated with it.

Nodes have a name and a hashref of attributes.

The name indicates the type of node. Names are one of these literals:

=over 4

=item o close

=item o open

=item o root

=item o text

=back

For 'open' and 'close', the delimiter is given by the value of the 'text' key in the hashref.

The (key => value) pairs in the hashref are:

=over 4

=item o text => $string

If the node name is 'open' or 'close', $string is the delimiter.

If the node name is 'text', $string is the verbatim text from the document.

Verbatim means, for example, that backslashes in the input are preserved.

=back

Try:

	perl -Ilib scripts/samples.pl info

=head2 How is HTML/XML handled?

The tree does not preserve the nested nature of HTML/XML.

Post-processing (valid) HTML could easily generate another view of the data.

But anyway, to get perfect HTML you'd be grabbing the output of L<Marpa::R2::HTML>, right?

See scripts/traverse.pl and t/html.t for a trivial HTML parser.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o Advanced error reporting

See L<https://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2014/11/delimiter.html>.

Perhaps this could be a sub-class?

=item o I8N support for error messages

=item o An explicit test program for parse exhaustion

=back

=head1 See Also

L<Text::Balanced>.

L<Tree> and L<Tree::Persist>.

L<MarpaX::Demo::SampleScripts> - for various usages of L<Marpa::R2>, but not of this module.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Thanks to Jeffrey Kegler, who wrote Marpa and L<Marpa::R2>.

And thanks to rns (Ruslan Shvedov) for writing the grammar for double-quoted strings used in
L<MarpaX::Demo::SampleScripts>'s scripts/quoted.strings.02.pl. I adapted it to HTML (see
scripts/quoted.strings.05.pl in that module), and then incorporated the grammar into
L<GraphViz2::Marpa>, and - after more extensions - into this module.

Lastly, thanks to Robert Rothenberg for L<Const::Exporter>, a module which works the same way
Perl does.

=head1 Repository

L<https://github.com/ronsavage/Text-Balanced-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text::Balanced::Marpa>.

=head1 Author

L<Text::Balanced::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
