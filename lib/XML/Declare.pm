package # hide
	XML::LibXML::Node;
	use overload '""' => 'toString',
	fallback => 1;

package XML::Declare;

use 5.008008;
use strict;
use warnings;
use Carp;

=head1 NAME

XML::Declare - Create XML documents with declaration style

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	my $doc = doc {
		element feed => sub {
			attr xmlns => 'http://www.w3.org/2005/Atom';
			comment "generated using XML::Declare v$XML::Declare::VERSION";
			for (1..3) {
				element entry => sub {
					element title     => 'Title', type => 'text';
					element content   => sub {
						attr type => 'text';
						cdata 'Desc';
					};
					element published => '123123-1231-123-123';
					element author => sub {
						element name => 'Mons';
					}
				};
			}
		};
	} '1.0','utf-8';

	print $doc;

	doc { DEFINITIONS } < args to XML::LibXML::Document->new >

	Where DEFINITIONS are
	
	element name => sub { DEFINITIONS }
	or
	element
		name => 'TextContent',
		attr => value,
		attr1 => [qw(more values)];
	
	attr name => values;
	
	text $content;
	
	cdata $content;
	
	comment $content;

=head1 EXPORT

=head2 doc BLOCK [ $version, $charset ];

Create L<XML::LibXML::Document>;

=head2 element $name, sub { ... };

Create L<XML::LibXML::Element> with name C<$name>; everything, called within C<sub { ... }> will be appended as children to this element

=head2 element $name, ATTRS

Create L<XML::LibXML::Element> with name C<$name> and set it's attributes. C<ATTRS> is a pairs of C<key => "value">

=head2 attr $name, $value

Create L<XML::LibXML::Attribute> with name C<$name> and value C<$value>

=head2 text $content

Create L<XML::LibXML::Text> node with content C<$content>

=head2 cdata $content

Create L<XML::LibXML::CDATASection> node with content C<$content>

=head2 comment $content

Create L<XML::LibXML::Comment> node with content C<$content>

=cut


use strict;
use XML::LibXML;

sub import {
	my $caller = caller;
	no strict 'refs';
	*{ $caller . '::doc' }     = \&doc;
	*{ $caller . '::element' } = \&element;
	*{ $caller . '::attr' }    = \&attr;
	*{ $caller . '::text' }    = \&text;
	*{ $caller . '::cdata' }   = \&cdata;
	*{ $caller . '::comment' } = \&comment;
}

{
	our $document;
	our $element;
	our @EL;
	sub element ($;$@);
	sub attr (@);
	sub text ($);
	sub cdata ($);
	sub comment ($);
	
	sub doc (&;$$) {
		my $code = shift;
		my $caller = caller;
		my $version = shift || '1.0';
		my $encoding = shift || 'utf-8';
		my $doc = XML::LibXML::Document->new($version, $encoding);
		local @EL = ();
		#local $document = $doc;
		local $element = $doc;
		no strict 'refs';
		local *{$caller.'::element'} = sub ($;$@) {
			my $name = shift;
			my ($code,$text);
			if (@_) {
				if (ref $_[-1] eq 'CODE') {
					$code = pop;
				} else {
					$text = shift;
				}
			}
			{
				#local $element = $doc->createElement($name);
				local $element;
				eval {
					$element = XML::LibXML::Element->new($name);
					$element->setNodeName($name); # Will invoke checks
					1;
				} or do {
					( my $e = $@ ) =~ s{ at \S+? line \d+\.\s*$}{};
					croak $e;
				};
				$element->appendText($text) if defined $text;
				while (my( $attr,$val ) = splice @_, 0, 2) {
					$element->setAttribute($attr, ref $val eq 'ARRAY' ? @$val : $val);
				}
				if ($code) {
					local @EL = ();
					$code->() if $code;
					$element->appendChild($_) for @EL;
				}
				push @EL,$element;
				return $element;
			}
		};
		local *{$caller.'::attr'} = sub (@) {
			eval {
				$element->setAttribute(@_);
				1;
			} or do {
				( my $e = $@ ) =~ s{ at \S+? line \d+\.\s*$}{};
				croak $e;
			};
		};
		local *{$caller.'::text'} = sub ($) {
			my $n = XML::LibXML::Text->new(shift);
			#my $tn = $doc->createTextNode(shift);
			$element->appendChild($n);
		};
		local *{$caller.'::cdata'} = sub ($) {
			my $n = XML::LibXML::CDATASection->new(shift);
			$element->appendChild($n);
		};
		local *{$caller.'::comment'} = sub ($) {
			local $_ = shift;
			m{--}s and croak "'--' (double-hyphen) MUST NOT occur within comments";
			substr($_,-1,1) eq '-' and croak "comment MUST NOT end with a '-' (hyphen)";
			my $n = XML::LibXML::Comment->new($_);
			$element->appendChild($n);
		};
		$code->();
		if (@EL == 0) {
			Carp::carp "Empty document";
		}
		elsif (@EL == 1) {
			$doc->setDocumentElement(shift @EL);
		} else {
			Carp::carp "More than one root element. All except first are ignored";
			$doc->setDocumentElement(shift @EL);
		}
		
		$doc;
	}
}


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2010 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1; # End of XML::Declare
