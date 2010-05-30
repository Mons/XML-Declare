#!/usr/bin/env perl -w

use uni::perl;
use lib::abs '../lib';
use Test::More tests => 20;
use Test::NoWarnings ();
use XML::Declare;

my $doc;my $back;
{
	local $SIG{__WARN__} = sub { pass 'have warn'; };
	is + ($doc = doc {}), qq{<?xml version="1.0" encoding="utf-8"?>\n}, 'empty doc';
	is + ($doc = doc {} '1.1'), qq{<?xml version="1.1" encoding="utf-8"?>\n}, 'empty doc 1.1';
	is + ($doc = doc {} undef,'cp1251'), qq{<?xml version="1.0" encoding="cp1251"?>\n}, 'empty doc cp1251';
	is + ($doc = doc {} '1.1','cp1251'), qq{<?xml version="1.1" encoding="cp1251"?>\n}, 'empty doc 1.1 cp1251';
}

is 
	$doc = doc { element 'test'; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test/>\n},
	'doc + element'
	or diag $doc;

XML::LibXML->new->parse_string($doc);

eval { $doc = doc { element '<'; } };
ok $@, 'bad node name' or diag "No error: $doc";
eval { $doc = doc { element t => sub { attr '<' => 'attrval'; }; } };
ok $@, 'bad attr name' or diag "No error: $doc";


is 
	$doc = doc { element 'test', 'text', a => 'attrval'; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text</test>\n},
	'doc + element + attrs'
	or diag $doc;

XML::LibXML->new->parse_string($doc);

is 
	$doc = doc { element test => a => 'attrval', sub { text 'text'; }; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text</test>\n},
	'doc + element-sub'
	or diag $doc;

XML::LibXML->new->parse_string($doc);

is 
	$doc = doc { element test => sub { text 'text'; attr a => 'attrval'; }; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text</test>\n},
	'doc + element-sub + attr'
	or diag $doc;

XML::LibXML->new->parse_string($doc);

is 
	$doc = doc { element test => sub { text 'text'; attr a => 'attrval'; comment 'zzzz'; cdata 'something <![CDATA[:)]]>'; }; },
	qq{<?xml version="1.0" encoding="utf-8"?>\n<test a="attrval">text<!--zzzz--><![CDATA[something <![CDATA[:)]]]]><![CDATA[>]]></test>\n},
	'doc + element-sub + attr,comm,cdata';

XML::LibXML->new->parse_string($doc);

eval { $doc = doc { element test => sub { comment '--'; } } };
like $@, qr/double-hyphen.* MUST NOT occur within/i, 'comment with --' or diag "No error: $doc";

eval { $doc = doc { element test => sub { comment 'test-'; } } };
like $@, qr/MUST NOT end with .*hyphen/i, 'comment with -' or diag "No error: $doc";

$doc = doc { element test => sub { comment '-B, B+, B, or B- '; }; };
$back = XML::LibXML->new->parse_string($doc);
is $back->documentElement->firstChild->textContent, "-B, B+, B, or B- ", 'comment parsed back';

$doc = doc { element test => sub { cdata '<![CDATA[:)]]>'; } };
$back = XML::LibXML->new->parse_string($doc);
is $back->documentElement->firstChild->textContent, '<![CDATA[:)]]>', 'cdata parsed back';

Test::NoWarnings::had_no_warnings();

exit;
require Test::NoWarnings; # Stupid hack for cpants::kwalitee
