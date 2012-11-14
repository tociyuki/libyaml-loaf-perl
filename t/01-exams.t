use 5.008001;
use strict;
use warnings;
use Test::Base;
use YAML::Loaf;
use MIME::Base64;

delimiters('###', '===');

plan tests => 1 * blocks;

filters {
    'input' => [qw(chomp yaml_stream)],
    'expected' => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

sub yaml_stream {
    my($input) = @_;
    # YAML::Loaf::Load returns all documents on array contexts.
    return [YAML::Loaf::Load($input)];
}

sub skiptest { return [] }

# examples from L<http://yaml.org/spec/1.2/spec.html>

__END__

### Example 2.1
Sequence of Scalars (ball players)
=== input
- Mark McGwire
- Sammy Sosa
- Ken Griffey
=== expected
[
    [
        qq(Mark McGwire),
        qq(Sammy Sosa),
        qq(Ken Griffey),
    ],
]

### Example 2.2
Mapping Scalars to Scalars (player statistics)
=== input
hr:  65    # Home runs
avg: 0.278 # Batting average
rbi: 147   # Runs Batted In
=== expected
[
    {
        'hr' => '65',
        'avg' => '0.278',
        'rbi' => '147',
    },
]

### Example 2.3
Mapping Scalars to Sequences (ball clubs in each league)
=== input
american:
  - Boston Red Sox
  - Detroit Tigers
  - New York Yankees
national:
  - New York Mets
  - Chicago Cubs
  - Atlanta Braves
=== expected
[
    {
        'american' => [
            qq(Boston Red Sox),
            qq(Detroit Tigers),
            qq(New York Yankees),
        ],
        'national' => [
            qq(New York Mets),
            qq(Chicago Cubs),
            qq(Atlanta Braves),
        ],
    },
]

### Example 2.4
Sequence of Mappings (players’statistics)
=== input
-
  name: Mark McGwire
  hr:   65
  avg:  0.278
-
  name: Sammy Sosa
  hr:   63
  avg:  0.288
=== expected
[
    [
        {
            'name' => qq(Mark McGwire),
            'hr' => qq(65),
            'avg' => qq(0.278),
        },
        {
            'name' => qq(Sammy Sosa),
            'hr' => qq(63),
            'avg' => qq(0.288),
        },
    ],
]

### Example 2.5
Sequence of Sequences
=== input
- [name        , hr, avg  ]
- [Mark McGwire, 65, 0.278]
- [Sammy Sosa  , 63, 0.288]
=== expected
[
    [
        [qq(name),         qq(hr), qq(avg)],
        [qq(Mark McGwire), qq(65), qq(0.278)],
        [qq(Sammy Sosa),   qq(63), qq(0.288)],
    ],
]

### Example 2.6
Mapping of Mappings 
=== input
Mark McGwire: {hr: 65, avg: 0.278}
Sammy Sosa: {
    hr: 63,
    avg: 0.288
  }
=== expected
[
    {
        'Mark McGwire' => {'hr' => '65', 'avg' => '0.278'},
        'Sammy Sosa' => {
            'hr' => '63',
            'avg' => '0.288',
        },
    },
]

### Example 2.7
Two Documents in a Stream (each with a leading comment)
=== input
# Ranking of 1998 home runs
---
- Mark McGwire
- Sammy Sosa
- Ken Griffey

# Team ranking
---
- Chicago Cubs
- St Louis Cardinals
=== expected
[
    [
        qq(Mark McGwire),
        qq(Sammy Sosa),
        qq(Ken Griffey),
    ],
    [
        qq(Chicago Cubs),
        qq(St Louis Cardinals),
    ],
]

### Example 2.8
Play by Play Feed from a Game
=== input
---
time: 20:03:20
player: Sammy Sosa
action: strike (miss)
...
---
time: 20:03:47
player: Sammy Sosa
action: grand slam
...
=== expected
[
    {
        'time' => qq(20:03:20),
        'player' => qq(Sammy Sosa),
        'action' => qq[strike (miss)],
    },
    {
        'time' => qq(20:03:47),
        'player' => qq(Sammy Sosa),
        'action' => qq(grand slam),
    },
]

### Example 2.9
Single Document with Two Comments
=== input
---
hr: # 1998 hr ranking
  - Mark McGwire
  - Sammy Sosa
rbi:
  # 1998 rbi ranking
  - Sammy Sosa
  - Ken Griffey
=== expected
[
    {
        'hr' => [
            qq(Mark McGwire),
            qq(Sammy Sosa),
        ],
        'rbi' => [
            qq(Sammy Sosa),
            qq(Ken Griffey),
        ],
    },
]

### Example 2.10
Node for "Sammy Sosa" appears twice in this document
=== input
---
hr:
  - Mark McGwire
  # Following node labeled SS
  - &SS Sammy Sosa
rbi:
  - *SS # Subsequent occurrence
  - Ken Griffey
=== expected
[
    {
        'hr' => [
            qq(Mark McGwire),
            qq(Sammy Sosa),
        ],
        'rbi' => [
            qq(Sammy Sosa),
            qq(Ken Griffey),
        ],
    },
]

### Example 2.11
Mapping between Sequences
SKIP due to keys of perl's HASH restrictions. 
=== input skiptest
? - Detroit Tigers
  - Chicago cubs
:
  - 2001-07-23

? [ New York Yankees,
    Atlanta Braves ]
: [ 2001-07-02, 2001-08-12,
    2001-08-14 ]
=== expected skiptest
[
    {
        [
            qq(Detroit Tigers),
            qq(Chicago cubs),
        ] => [
            qq(2001-07-23),
        ],
        [
            qq(New York Yankees),
            qq(Atlanta Braves),
        ] => [
            qq(2001-07-02), qq(2001-08-12),
            qq(2001-08-14),
        ],
    },
]

### Example 2.11 Modified
Mapping between Sequences
=== input
--- !!perl/array
? - Detroit Tigers
  - Chicago cubs
:
  - 2001-07-23

? [ New York Yankees,
    Atlanta Braves ]
: [ 2001-07-02, 2001-08-12,
    2001-08-14 ]
=== expected
[
    [
        [
            qq(Detroit Tigers),
            qq(Chicago cubs),
        ] => [
            qq(2001-07-23),
        ],
        [
            qq(New York Yankees),
            qq(Atlanta Braves),
        ] => [
            qq(2001-07-02), qq(2001-08-12),
            qq(2001-08-14),
        ],
    ],
]

### Example 2.12
Compact Nested Mapping
=== input
---
# Products purchased
- item    : Super Hoop
  quantity: 1
- item    : Basketball
  quantity: 4
- item    : Big Shoes
  quantity: 1
=== expected
[
    [
        {
            'item' => qq(Super Hoop),
            'quantity' => qq(1),
        },
        {
            'item' => qq(Basketball),
            'quantity' => qq(4),
        },
        {
            'item' => qq(Big Shoes),
            'quantity' => qq(1),
        },
    ],
]

### Example 2.13
In literals, newlines are preserved
=== input
# ASCII Art
--- |
  \//||\/||
  // ||  ||__
=== expected
[
      qq(\\//||\\/||\n)
    . qq(// ||  ||__\n),
]

### Example 2.14
In the folded scalars, newlines become spaces
=== input
--- >
  Mark McGwire's
  year was crippled
  by a knee injury.
=== expected
[
      qq(Mark McGwire's )
    . qq(year was crippled )
    . qq(by a knee injury.\n),
]

### Example 2.15
Folded newlines are preservedfor "more indented" and blank lines
=== input
>
 Sammy Sosa completed another
 fine season with great stats.

   63 Home Runs
   0.288 Batting Average

 What a year!
=== expected
[
      qq(Sammy Sosa completed another )
    . qq(fine season with great stats.\n)
    . qq(\n)
    . qq(  63 Home Runs\n)
    . qq(  0.288 Batting Average\n)
    . qq(\n)
    . qq(What a year!\n),
]

### Example 2.16
Indentation determines scope
=== input
name: Mark McGwire
accomplishment: >
  Mark set a major league
  home run record in 1998.
stats: |
  65 Home Runs
  0.278 Batting Average
=== expected
[
    {
        'name' => qq(Mark McGwire),
        'accomplishment' =>
              qq(Mark set a major league )
            . qq(home run record in 1998.\n),
        'stats' =>
              qq(65 Home Runs\n)
            . qq(0.278 Batting Average\n),
    },
]

### Example 2.17
Quoted Scalars
=== input
unicode: "Sosa did fine.\u263A"
control: "\b1998\t1999\t2000\n"
hex esc: "\x0d\x0a is \r\n"

single: '"Howdy!" he cried.'
quoted: ' # Not a ''comment''.'
tie-fighter: '|\-*-/|'
=== expected
[
    {
        'unicode' => qq(Sosa did fine.\x{263a}),
        'control' => qq(\b1998\t1999\t2000\n),
        'hex esc' => qq(\x0d\x0a is \r\n),
        'single'  => qq("Howdy!" he cried.),
        'quoted'  => qq( # Not a 'comment'.),
        'tie-fighter' => qq(|\\-*-/|),
    },
]

### Example 2.18
Multi-line Flow Scalars
=== input
plain:
  This unquoted scalar
  spans many lines.

quoted: "So does this
  quoted scalar.\n"
=== expected
[
    {
        'plain' => qq(This unquoted scalar spans many lines.),
        'quoted' => qq(So does this quoted scalar.\n),
    },
]

### Example 2.19
Integers
=== input
canonical: 12345
decimal: +12345
octal: 0o14
hexadecimal: 0xC
=== expected
[
    {
        'canonical' => '12345',
        'decimal' => '+12345',
        'octal' => 014,
        'hexadecimal' => 0xc,
    },
]

### Example 2.20
Floating Point
=== input
canonical: 1.23015e+3
exponential: 12.3015e+02
fixed: 1230.15
negative infinity: -.inf
not a number: .NaN
=== expected
[
    {
        'canonical' => '1.23015e+3',
        'exponential' => '12.3015e+02',
        'fixed' => '1230.15',
        'negative infinity' => '-.inf',
        'not a number' => '.NaN',
    },
]

### Example 2.21
Miscellaneous
=== input
null:
booleans: [ true, false ]
string: '012345'
=== expected
[
    {
        q() => undef,
        'booleans' => ['true', q()],
        'string' => '012345',
    },
]

### Example 2.22
Timestamps
=== input
canonical: 2001-12-15T02:59:43.1Z
iso8601: 2001-12-14t21:59:43.10-05:00
spaced: 2001-12-14 21:59:43.10 -5
date: 2002-12-14
=== expected
[
    {
        'canonical' => '2001-12-15T02:59:43.1Z',
        'iso8601' => '2001-12-14t21:59:43.10-05:00',
        'spaced' => '2001-12-14 21:59:43.10 -5',
        'date' => '2002-12-14',
    },
]

### Example 2.23
Various Explicit Tags
(YAML::Loaf::Load ignores all of application specific tags)
=== input
---
not-date: !!str 2002-04-28

picture: !!binary |
 R0lGODlhDAAMAIQAAP//9/X
 17unp5WZmZgAAAOfn515eXv
 Pz7Y6OjuDg4J+fn5OTk6enp
 56enmleECcgggoBADs=

application specific tag: !something |
 The semantics of the tag
 above may be different for
 different documents.
=== expected
[
    {
        'not-date' => '2002-04-28',
        'picture' => MIME::Base64::decode_base64(
              qq(R0lGODlhDAAMAIQAAP//9/X\n)
            . qq(17unp5WZmZgAAAOfn515eXv\n)
            . qq(Pz7Y6OjuDg4J+fn5OTk6enp\n)
            . qq(56enmleECcgggoBADs=\n),
        ),
        'application specific tag' =>
              qq(The semantics of the tag\n)
            . qq(above may be different for\n)
            . qq(different documents.\n),
    },
]

### Example 2.24
Global Tags
=== input
%TAG ! tag:clarkevans.com,2002:
--- !shape
  # Use the ! handle for presenting
  # tag:clarkevans.com,2002:circle
- !circle
  center: &ORIGIN {x: 73, y: 129}
  radius: 7
- !line
  start: *ORIGIN
  finish: { x: 89, y: 102 }
- !label
  start: *ORIGIN
  color: 0xFFEEBB
  text: Pretty vector drawing.
=== expected
my $origin = {'x' => '73', 'y' => '129'};
[
    [
        {
            'center' => $origin,
            'radius' => '7',
        },
        {
            'start' => $origin,
            'finish' => {'x' => '89', 'y' => '102'},
        },
        {
            'start' => $origin,
            'color' => 0xFFEEBB,
            'text' => 'Pretty vector drawing.',
        },
    ],
]

### Example 2.25
Unordered Sets
=== input
# Sets are represented as a
# Mapping where each key is
# associated with a null value
--- !!set
? Mark McGwire
? Sammy Sosa
? Ken Griff
=== expected
[
    {
        'Mark McGwire' => undef,
        'Sammy Sosa' => undef,
        'Ken Griff' => undef,
    },
]

### Example 2.26
Ordered Mappings
=== input
# Ordered maps are represented as
# A sequence of mappings, with
# each mapping having one key
--- !!omap
- Mark McGwire: 65
- Sammy Sosa: 63
- Ken Griffy: 58
=== expected
[
    [
        {'Mark McGwire' => 65},
        {'Sammy Sosa' => 63},
        {'Ken Griffy' => 58},
    ],
]

### Example 2.27
Invoice
=== input
--- !<tag:clarkevans.com,2002:invoice>
invoice: 34843
date   : 2001-01-23
bill-to: &id001
    given  : Chris
    family : Dumars
    address:
        lines: |
            458 Walkman Dr.
            Suite #292
        city    : Royal Oak
        state   : MI
        postal  : 48046
ship-to: *id001
product:
    - sku         : BL394D
      quantity    : 4
      description : Basketball
      price       : 450.00
    - sku         : BL4438H
      quantity    : 1
      description : Super Hoop
      price       : 2392.00
tax  : 251.42
total: 4443.52
comments:
    Late afternoon is best.
    Backup contact is Nancy
    Billsmer @ 338-4338.
=== expected
my $id001 = {
    'given' => 'Chris',
    'family' => 'Dumars',
    'address' => {
        'lines' => qq(458 Walkman Dr.\nSuite #292\n),
        'city' => 'Royal Oak',
        'state' => 'MI',
        'postal' => '48046',
    },
};
[
    {
        'invoice' => '34843',
        'date' => '2001-01-23',
        'bill-to' => $id001,
        'ship-to' => $id001,
        'product' => [
            {
                'sku' => 'BL394D',
                'quantity' => '4',
                'description' => 'Basketball',
                'price' => '450.00',
            },
            {
                'sku' => 'BL4438H',
                'quantity' => '1',
                'description' => 'Super Hoop',
                'price' => '2392.00',
            },
        ],
        'tax' => '251.42',
        'total' => '4443.52',
        'comments' =>
              qq(Late afternoon is best. )
            . qq(Backup contact is Nancy )
            . qq(Billsmer @ 338-4338.),
    },
]

### Example 2.28
Log File
=== input
---
Time: 2001-11-23 15:01:42 -5
User: ed
Warning:
  This is an error message
  for the log file
---
Time: 2001-11-23 15:02:31 -5
User: ed
Warning:
  A slightly different error
  message.
---
Date: 2001-11-23 15:03:17 -5
User: ed
Fatal:
  Unknown variable "bar"
Stack:
  - file: TopClass.py
    line: 23
    code: |
      x = MoreObject("345\n")
  - file: MoreClass.py
    line: 58
    code: |-
      foo = bar
=== expected
[
    {
        'Time' => '2001-11-23 15:01:42 -5',
        'User' => 'ed',
        'Warning' => 'This is an error message for the log file',
    },
    {
        'Time' => '2001-11-23 15:02:31 -5',
        'User' => 'ed',
        'Warning' => 'A slightly different error message.',
    },
    {
        'Date' => '2001-11-23 15:03:17 -5',
        'User' => 'ed',
        'Fatal' => 'Unknown variable "bar"',
        'Stack' => [
            {
                'file' => 'TopClass.py',
                'line' => '23',
                'code' => qq(x = MoreObject("345\\n")\n),
            },
            {
                'file' => 'MoreClass.py',
                'line' => '58',
                'code' => qq(foo = bar),
            },
        ],
    },
]

### Example 5.3
Block Structure Indicators
=== input
sequence:
- one
- two
mapping:
  ? sky
  : blue
  sea : green
...
%YAML 1.2
---
!!map {
  ? !!str "sequence"
  : !!seq [ !!str "one", !!str "two" ],
  ? !!str "mapping"
  : !!map {
    ? !!str "sky" : !!str "blue",
    ? !!str "sea" : !!str "green",
  },
}
=== expected
[
    {
        'sequence' => ['one', 'two'],
        'mapping' => {'sky' => 'blue', 'sea' => 'green'},
    },
    {
        'sequence' => ['one', 'two'],
        'mapping' => {'sky' => 'blue', 'sea' => 'green'},
    },
]

### Example 5.4
Flow Collection Indicators
=== input
sequence: [ one, two, ]
mapping: { sky: blue, sea: green }
=== expected
[
    {
        'sequence' => ['one', 'two'],
        'mapping' => {'sky' => 'blue', 'sea' => 'green'},
    },
]

### Example 5.6
Node Property Indicators
=== input
anchored: !local &anchor value
alias: *anchor
...
%YAML 1.2
---
!!map {
  ? !!str "anchored"
  : !local &A1 "value",
  ? !!str "alias"
  : *A1,
}
=== expected
my $anchor = 'value';
my $A1 = 'value';
[
    {
        'anchored' => $anchor,
        'alias' => $anchor,
    },
    {
        'anchored' => $A1,
        'alias' => $A1,
    },
]

### Example 5.7
Block Scalar Indicators
=== input
literal: |
  some
  text
folded: >
  some
  text
...
%YAML 1.2
---
!!map {
  ? !!str "literal"
  : !!str "some\ntext\n",
  ? !!str "folded"
  : !!str "some text\n",
}
=== expected
[
    {
        'literal' => qq(some\ntext\n),
        'folded' => qq(some text\n),
    },
    {
        'literal' => qq(some\ntext\n),
        'folded' => qq(some text\n),
    },
]

### Example 5.8
Quoted Scalar Indicators
=== input
single: 'text'
double: "text"
...
%YAML 1.2
---
!!map {
  ? !!str "single"
  : !!str "text",
  ? !!str "double"
  : !!str "text",
}
=== expected
[
    {
        'single' => 'text',
        'double' => 'text',
    },
    {
        'single' => 'text',
        'double' => 'text',
    },
]

### Example 5.9
Directive Indicator (ignored)
=== input
%YAML 1.2
--- text
...
%YAML 1.2
---
!!str "text"
=== expected
[
    'text',
    'text',
]

### Example 5.11
Line Break Characters
=== input
|
  Line break (no glyph)
  Line break (glyphed)
...
%YAML 1.2
---
!!str "line break (no glyph)\n\
      line break (glyphed)\n"
=== expected
[
      "Line break (no glyph)\n"
    . "Line break (glyphed)\n",
      "line break (no glyph)\n"
    . "line break (glyphed)\n",
]

### Example 5.12
Tabs and Spaces
=== input
# Tabs and spaces
quoted: "Quoted 	"
block:	|
  void main() {
  	printf("Hello, world!\n");
  }
...
%YAML 1.2
---
!!map {
  ? !!str "quoted"
  : "Quoted \t",
  ? !!str "block"
  : "void main() {\n\
    \tprintf(\"Hello, world!\\n\");\n\
    }\n",
}
=== expected
[
    {
        'quoted' => qq(Quoted \t),
        'block' =>
              qq(void main() {\n)
            . qq(\tprintf("Hello, world!\\n");\n)
            . qq(}\n),
    },
    {
        'quoted' => qq(Quoted \t),
        'block' =>
              qq(void main() {\n)
            . qq(\tprintf("Hello, world!\\n");\n)
            . qq(}\n),
    },
]

### Example 5.13
Escaped Characters
=== input
"Fun with \\
\" \a \b \e \f \
\n \r \t \v \0 \
\  \_ \N \L \P \
\x41 \u0041 \U00000041"
=== expected
[
      "Fun with \x5c "
    . "\x22 \x07 \x08 \x1b \x0c "
    . "\x0a \x0d \x09 \x0b \x00 "
    . "\x20 \x{a0} \x{85} \x{2028} \x{2029} "
    . "A A A",
]

### Example 6.1
Indentation Spaces
=== input
  # Leading comment line spaces are
   # neither content nor indentation.
    
Not indented:
 By one space: |
    By four
      spaces
 Flow style: [    # Leading spaces
   By two,        # in flow style
  Also by two,    # are neither
  	Still by two   # content nor
    ]             # indentation.
...
%YAML 1.2
---
!!map {
  ? !!str "Not indented"
  : !!map {
      ? !!str "By one space"
      : !!str "By four\n  spaces\n",
      ? !!str "Flow style"
      : !!seq [
          !!str "By two",
          !!str "Also by two",
          !!str "Still by two",
        ]
    }
}
=== expected
[
    {
        'Not indented' => {
            'By one space' => qq(By four\n) . qq(  spaces\n),
            'Flow style' => ['By two', 'Also by two', 'Still by two'],
        },
    },
    {
        'Not indented' => {
            'By one space' => qq(By four\n) . qq(  spaces\n),
            'Flow style' => ['By two', 'Also by two', 'Still by two'],
        },
    },
]

### Example 6.2
Indentation Indicators
=== input
? a
: -	b
  -  -	c
     - d
...
%YAML 1.2
---
!!map {
  ? !!str "a"
  : !!seq [
    !!str "b",
    !!seq [ !!str "c", !!str "d" ]
  ],
}
=== expected
[
    {
        'a' => [
            'b',
            ['c', 'd'],
        ],
    },
    {
        'a' => [
            'b',
            ['c', 'd'],
        ],
    },
]

### Example 6.3
Separation Spaces
=== input
- foo:	 bar
- - baz
  -	baz
...
%YAML 1.2
---
!!seq [
  !!map {
    ? !!str "foo" : !!str "bar",
  },
  !!seq [ !!str "baz", !!str "baz" ],
]
=== expected
[
	[
		{'foo' => 'bar'},
		['baz', 'baz'],
	],
	[
		{'foo' => 'bar'},
		['baz', 'baz'],
	],
]

### Example 6.4
Line Prefixes
=== input
plain: text
  lines
quoted: "text
  	lines"
block: |
  text
   	lines
...
%YAML 1.2
---
!!map {
  ? !!str "plain"
  : !!str "text lines",
  ? !!str "quoted"
  : !!str "text lines",
  ? !!str "block"
  : !!str "text\n \tlines\n",
}
=== expected
[
	{
		'plain' => 'text lines',
		'quoted' => 'text lines',
		'block' => qq(text\n \tlines\n),
	},
	{
		'plain' => 'text lines',
		'quoted' => 'text lines',
		'block' => qq(text\n \tlines\n),
	},
]

### Example 6.5
Empty Lines
=== input -chomp
Folding:
  "Empty line
   	
  as a line feed"
Chomping: |
  Clipped empty lines
 
...
%YAML 1.2
---
!!map {
  ? !!str "Folding"
  : !!str "Empty line\nas a line feed",
  ? !!str "Chomping"
  : !!str "Clipped empty lines\n",
}
=== expected
[
	{
		'Folding' => qq(Empty line\nas a line feed),
		'Chomping' => qq(Clipped empty lines\n),
	},
	{
		'Folding' => qq(Empty line\nas a line feed),
		'Chomping' => qq(Clipped empty lines\n),
	},
]

### Example 6.6
Line Folding
=== input
>-
  trimmed
  
 

  as
  space
...
%YAML 1.2
---
!!str "trimmed\n\n\nas space"
=== expected
[
	qq(trimmed\n\n\nas space),
	qq(trimmed\n\n\nas space),
]

### Example 6.7
Block Folding
=== input
>
  foo 
 
  	 bar

  baz
...
%YAML 1.2
--- !!str
"foo \n\n\t bar\n\nbaz\n"
=== expected
[
	qq(foo \n\n\t bar\n\nbaz\n),
	qq(foo \n\n\t bar\n\nbaz\n),
]

### Example 6.8
Flow Folding
=== input
"
  foo 
 
  	 bar

  baz
"
...
%YAML 1.2
--- !!str
" foo\nbar\nbaz "
=== expected
[
	qq( foo\nbar\nbaz ),
	qq( foo\nbar\nbaz ),
]

### Example 6.9
Separated Comment
=== input
key:    # Comment
  value
...
%YAML 1.2
---
!!map {
  ? !!str "key"
  : !!str "value",
}
=== expected
[
	{'key' => 'value'},
	{'key' => 'value'},
]

### Example 6.11
Multi-Line Comments
=== input
key:    # Comment
        # lines
  value

...
%YAML 1.2
---
!!map {
  ? !!str "key"
  : !!str "value",
}
=== expected
[
	{'key' => 'value'},
	{'key' => 'value'},
]

### Example 6.12
Separation Spaces
=== input skiptest
{ first: Sammy, last: Sosa }:
# Statistics:
  hr:  # Home runs
     65
  avg: # Average
   0.278
...
%YAML 1.2
---
!!map {
  ? !!map {
    ? !!str "first"
    : !!str "Sammy",
    ? !!str "last"
    : !!str "Sosa",
  }
  : !!map {
    ? !!str "hr"
    : !!int "65",
    ? !!str "avg"
    : !!float "0.278",
  },
}
=== expected skiptest
[
	{
		{'first' => 'Sammy', 'last' => 'Sosa'} => {'hr' => '65', 'avg' => '0.278'},
	},
	{
		{'first' => 'Sammy', 'last' => 'Sosa'} => {'hr' => '65', 'avg' => '0.278'},
	},
]

### Example 6.12 Modified
Separation Spaces
=== input
--- !!perl/array
{ first: Sammy, last: Sosa }:
# Statistics:
  hr:  # Home runs
     65
  avg: # Average
   0.278
...
%YAML 1.2
---
!!perl/array {
  ? !!map {
    ? !!str "first"
    : !!str "Sammy",
    ? !!str "last"
    : !!str "Sosa",
  }
  : !!map {
    ? !!str "hr"
    : !!int "65",
    ? !!str "avg"
    : !!float "0.278",
  },
}
=== expected
[
	[
		{'first' => 'Sammy', 'last' => 'Sosa'} => {'hr' => '65', 'avg' => '0.278'},
	],
	[
		{'first' => 'Sammy', 'last' => 'Sosa'} => {'hr' => '65', 'avg' => '0.278'},
	],
]

### Example 6.13
Reserved Directives
=== input
%FOO  bar baz # Should be ignored
               # with a warning.
--- "foo"
=== expected
[
	"foo",
]

### Example 6.14
"YAML" directive (ignored)
=== input
%YAML 1.3 # Attempt parsing
           # with a warning
---
"foo"
=== expected
[
	"foo",
]

### Example 6.16
"TAG" directive (ignored)
=== input
%TAG !yaml! tag:yaml.org,2002:
---
!yaml!str "foo"
=== expected
[
	"foo",
]

### Example 6.18
Primary Tag Handle (ignored)
=== input
# Private
!foo "bar"
...
# Global
%TAG ! tag:example.com,2000:app/
---
!foo "bar"
...
%YAML 1.2
---
!<!foo> "bar"
...
---
!<tag:example.com,2000:app/foo> "bar"
=== expected
[
	"bar",
	"bar",
	"bar",
	"bar",
]

### Example 6.19
Secondary Tag Handle (ignored)
=== input
%TAG !! tag:example.com,2000:app/
---
!!int 1 - 3 # Interval, not integer
...
%YAML 1.2
---
!<tag:example.com,2000:app/int> "1 - 3"
=== expected
[
	"1 - 3",
	"1 - 3",
]

### Example 6.20
Tag Handles (ignored)
=== input
%TAG !e! tag:example.com,2000:app/
---
!e!foo "bar"
...
%YAML 1.2
---
!<tag:example.com,2000:app/foo> "bar"
=== expected
[
	"bar",
	"bar",
]

### Example 6.21
Local Tag Prefix (ignored)
=== input
%TAG !m! !my-
--- # Bulb here
!m!light fluorescent
...
%TAG !m! !my-
--- # Color here
!m!light green
...
%YAML 1.2
---
!<!my-light> "fluorescent"
...
%YAML 1.2
---
!<!my-light> "green"
=== expected
[
	"fluorescent",
	"green",
	"fluorescent",
	"green",
]

### Example 6.22
Global Tag Prefix (ignored)
=== input
%TAG !e! tag:example.com,2000:app/
---
- !e!foo "bar"
...
%YAML 1.2
---
- !<tag:example.com,2000:app/foo> "bar"
=== expected
[
	["bar"],
	["bar"],
]

### Example 6.23
Node Properties
=== input
!!str &a1 "foo":
  !!str bar
&a2 baz : *a1
...
%YAML 1.2
---
!!map {
  ? &B1 !!str "foo"
  : !!str "bar",
  ? !!str "baz"
  : *B1,
}
=== expected
my $a1 = "foo";
my $B1 = "foo";
[
	{
		$a1 => 'bar',
		'baz' => $a1,
	},
	{
		$B1 => 'bar',
		'baz' => $B1,
	},
]

### Example 6.24
Verbatim Tags (ignored out of tag:yaml.org,2002)
=== input
!<tag:yaml.org,2002:str> foo :
  !<!bar> baz
...
%YAML 1.2
---
!!map {
  ? !<tag:yaml.org,2002:str> "foo"
  : !<!bar> "baz",
}
=== expected
[
	{'foo' => 'baz'},
	{'foo' => 'baz'},
]

### Example 6.26
Tag Shorthands (ignored)
=== input
%TAG !e! tag:example.com,2000:app/
---
- !local foo
- !!str bar
- !e!tag%21 baz
...
%YAML 1.2
---
!!seq [
  !<!local> "foo",
  !<tag:yaml.org,2002:str> "bar",
  !<tag:example.com,2000:app/tag!> "baz"
]
=== expected
[
	['foo', 'bar', 'baz'],
	['foo', 'bar', 'baz'],
]

### Example 6.28
Non-Specific Tags (ignored)
=== input
# Assuming conventional resolution:
- "12"
- 12
- ! 12
...
%YAML 1.2
---
!!seq [
  !<tag:yaml.org,2002:str> "12",
  !<tag:yaml.org,2002:int> "12",
  !<tag:yaml.org,2002:str> "12",
]
=== expected
[
	['12', '12', '12'],
	['12', '12', '12'],
]

### Example 6.29
Node Anchors
=== input
First occurrence: &anchor Value
Second occurrence: *anchor
...
%YAML 1.2
---
!!map {
  ? !!str "First occurrence"
  : &A !!str "Value",
  ? !!str "Second occurrence"
  : *A,
}
=== expected
my $anchor = 'Value';
my $A = 'Value';
[
	{'First occurrence' => $anchor, 'Second occurrence' => $anchor},
	{'First occurrence' => $A, 'Second occurrence' => $A},
]


### Example 7.1
Alias Nodes
=== input
First occurrence: &anchor Foo
Second occurrence: *anchor
Override anchor: &anchor Bar
Reuse anchor: *anchor
...
%YAML 1.2
---
!!map {
  ? !!str "First occurrence"
  : &A !!str "Foo",
  ? !!str "Override anchor"
  : &B !!str "Bar",
  ? !!str "Second occurrence"
  : *A,
  ? !!str "Reuse anchor"
  : *B,
}
=== expected
my $anchor = 'Foo';
my $anchor1 = 'Bar';
my $A = 'Foo';
my $A1 = 'Bar';
[
	{
		'First occurrence' => $anchor,
		'Second occurrence' => $anchor,
		'Override anchor' => $anchor1,
		'Reuse anchor' => $anchor1,
	},
	{
		'First occurrence' => $A,
		'Second occurrence' => $A,
		'Override anchor' => $A1,
		'Reuse anchor' => $A1,
	},
]

### Example 7.2
Empty Content
=== input
{
  foo : !!str,
  !!str : bar,
}
...
%YAML 1.2
---
!!map {
  ? !!str "foo" : !!str "",
  ? !!str ""    : !!str "bar",
}
=== expected
[
	{'foo' => '', '' => 'bar'},
	{'foo' => '', '' => 'bar'},
]

### Example 7.3
Completely Empty Flow Nodes
(From Perl's restrictions, empty strings for empty keys)
=== input
{
  ? foo :,
  : bar,
}
...
%YAML 1.2
---
!!map {
  ? !!str "foo" : !!null "",
  ? !!null ""   : !!str "bar",
}
=== expected
[
	{'foo' => undef, '' => 'bar'},
	{'foo' => undef, '' => 'bar'},
]

### Example 7.4
Double Quoted Implicit Keys
=== input
"implicit block key" : [
  "implicit flow key" : value,
 ]
...
%YAML 1.2
---
!!map {
  ? !!str "implicit block key"
  : !!seq [
    !!map {
      ? !!str "implicit flow key"
      : !!str "value",
    }
  ]
}
=== expected
[
	{
	    'implicit block key' => [
	        {'implicit flow key' => 'value'}
        ]
    },
	{
	    'implicit block key' => [
	        {'implicit flow key' => 'value'}
        ]
    },
]

### Example 7.5
Double Quoted Line Breaks
=== input
"folded 
to a space,	
 
to a line feed, or 	\
 \ 	non-content"
...
%YAML 1.2
---
!!str "folded to a space,\n\
      to a line feed, \
      or \t \tnon-content"
=== expected
[
	qq(folded to a space,\nto a line feed, or \t \tnon-content),
	qq(folded to a space,\nto a line feed, or \t \tnon-content),
]

### Example 7.6
Double Quoted Lines
=== input
" 1st non-empty

 2nd non-empty 
	3rd non-empty "
...
%YAML 1.2
---
!!str " 1st non-empty\n\
      2nd non-empty \
      3rd non-empty "
=== expected
[
	qq( 1st non-empty\n2nd non-empty 3rd non-empty ),
	qq( 1st non-empty\n2nd non-empty 3rd non-empty ),
]

### Example 7.7
Single Quoted Characters
=== input
 'here''s to "quotes"'
...
%YAML 1.2
---
!!str "here's to \"quotes\""
=== expected
[
	qq(here's to "quotes"),
	qq(here's to "quotes"),
]

### Example 7.8
Single Quoted Implicit Keys
=== input
'implicit block key' : [
  'implicit flow key' : value,
 ]
...
%YAML 1.2
---
!!map {
  ? !!str "implicit block key"
  : !!seq [
    !!map {
      ? !!str "implicit flow key"
      : !!str "value",
    }
  ]
}
=== expected
[
	{
	    'implicit block key' => [
	        {'implicit flow key' => 'value'},
	    ],
	},
	{
	    'implicit block key' => [
	        {'implicit flow key' => 'value'},
	    ],
	},
]

### Example 7.9
Single Quoted Lines
=== input
' 1st non-empty

 2nd non-empty 
	3rd non-empty '
...
%YAML 1.2
---
!!str " 1st non-empty\n\
      2nd non-empty \
      3rd non-empty "
=== expected
[
	qq( 1st non-empty\n2nd non-empty 3rd non-empty ),
	qq( 1st non-empty\n2nd non-empty 3rd non-empty ),
]

### Example 7.10
Plain Characters
=== input
# Outside flow collection:
- ::vector
- ": - ()"
- Up, up, and away!
- -123
- http://example.com/foo#bar
# Inside flow collection:
- [ ::vector,
  ": - ()",
  "Up, up and away!",
  -123,
  http://example.com/foo#bar ]
...
%YAML 1.2
---
!!seq [
  !!str "::vector",
  !!str ": - ()",
  !!str "Up, up, and away!",
  !!int "-123",
  !!str "http://example.com/foo#bar",
  !!seq [
    !!str "::vector",
    !!str ": - ()",
    !!str "Up, up, and away!",
    !!int "-123",
    !!str "http://example.com/foo#bar",
  ],
]
=== expected
[
	[
		qq(::vector),
		': - ()',
		qq(Up, up, and away!),
		'-123',
		'http://example.com/foo#bar',
		[
			qq(::vector),
			': - ()',
			qq(Up, up and away!),
			'-123',
			'http://example.com/foo#bar',
		],
	],
	[
		qq(::vector),
		': - ()',
		qq(Up, up, and away!),
		'-123',
		'http://example.com/foo#bar',
		[
			qq(::vector),
			': - ()',
			qq(Up, up, and away!),
			'-123',
			'http://example.com/foo#bar',
		],
	],
]

### Example 7.11
Plain Implicit Keys
=== input
implicit block key : [
  implicit flow key : value,
 ]
...
%YAML 1.2
---
!!map {
  ? !!str "implicit block key"
  : !!seq [
    !!map {
      ? !!str "implicit flow key"
      : !!str "value",
    }
  ]
}
=== expected
[
	{
	    'implicit block key' => [
	        {'implicit flow key' => 'value'},
	    ],
	},
	{
	    'implicit block key' => [
	        {'implicit flow key' => 'value'},
	    ],
	},
]

### Example 7.12
Plain Lines
=== input
1st non-empty

 2nd non-empty 
	3rd non-empty
...
%YAML 1.2
---
!!str "1st non-empty\n\
      2nd non-empty \
      3rd non-empty"
=== expected
[
	qq(1st non-empty\n2nd non-empty 3rd non-empty),
	qq(1st non-empty\n2nd non-empty 3rd non-empty),
]

### Example 7.13
Flow Sequence
=== input
- [ one, two, ]
- [three ,four]
...
%YAML 1.2
---
!!seq [
  !!seq [
    !!str "one",
    !!str "two",
  ],
  !!seq [
    !!str "three",
    !!str "four",
  ],
]
=== expected
[
	[
		['one', 'two'],
		['three', 'four'],
	],
	[
		['one', 'two'],
		['three', 'four'],
	],
]

### Example 7.14
Flow Sequence Entries
=== input
[
"double
 quoted", 'single
           quoted',
plain
 text, [ nested ],
single: pair,
]
...
%YAML 1.2
---
!!seq [
  !!str "double quoted",
  !!str "single quoted",
  !!str "plain text",
  !!seq [
    !!str "nested",
  ],
  !!map {
    ? !!str "single"
    : !!str "pair",
  },
]
=== expected
[
    [
        'double quoted',
        'single quoted',
        'plain text',
        [
            'nested',
        ],
        {
            'single' => 'pair',
        },
    ],
    [
        'double quoted',
        'single quoted',
        'plain text',
        [
            'nested',
        ],
        {
            'single' => 'pair',
        },
    ],
]

### Example 7.15
Flow Mappings
=== input
- { one : two , three: four , }
- {five: six,seven : eight}
...
%YAML 1.2
---
!!seq [
  !!map {
    ? !!str "one"   : !!str "two",
    ? !!str "three" : !!str "four",
  },
  !!map {
    ? !!str "five"  : !!str "six",
    ? !!str "seven" : !!str "eight",
  },
]
=== expected
[
    [
        {
            'one' => 'two',
            'three' => 'four',
        },
        {
            'five' => 'six',
            'seven' => 'eight',
        },
    ],
    [
        {
            'one' => 'two',
            'three' => 'four',
        },
        {
            'five' => 'six',
            'seven' => 'eight',
        },
    ],
]

### Example 7.16
Flow Mapping Entries
=== input
{
? explicit: entry,
implicit: entry,
?
}
...
%YAML 1.2
---
!!map {
  ? !!str "explicit" : !!str "entry",
  ? !!str "implicit" : !!str "entry",
  ? !!null "" : !!null "",
}
=== expected
[
    {
        'explicit' => 'entry',
        'implicit' => 'entry',
        q() => undef,
    },
    {
        'explicit' => 'entry',
        'implicit' => 'entry',
        q() => undef,
    },
]

### Example 7.17
Flow Mapping Separate Values
=== input
{
unquoted : "separate",
http://foo.com,
omitted value:,
: omitted key,
}
...
%YAML 1.2
---
!!map {
  ? !!str "unquoted" : !!str "separate",
  ? !!str "http://foo.com" : !!null "",
  ? !!str "omitted value" : !!null "",
  ? !!null "" : !!str "omitted key",
}
=== expected
[
    {
        'unquoted' => 'separate',
        'http://foo.com' => undef,
        'omitted value' => undef,
        q() => 'omitted key',
    },
    {
        'unquoted' => 'separate',
        'http://foo.com' => undef,
        'omitted value' => undef,
        q() => 'omitted key',
    },
]

### Example 7.18
Flow Mapping Adjacent Values
=== input
{
"adjacent":value,
"readable": value,
"empty":
}
...
%YAML 1.2
---
!!map {
  ? !!str "adjacent" : !!str "value",
  ? !!str "readable" : !!str "value",
  ? !!str "empty"    : !!null "",
}
=== expected
[
    {
        'adjacent' => 'value',
        'readable' => 'value',
        'empty' => undef,
    },
    {
        'adjacent' => 'value',
        'readable' => 'value',
        'empty' => undef,
    },
]

### Example 7.19
Single Pair Flow Mappings
=== input
[
foo: bar
]
...
%YAML 1.2
---
!!seq [
  !!map { ? !!str "foo" : !!str "bar" }
]
=== expected
[
    [
        {'foo' => 'bar'},
    ],
    [
        {'foo' => 'bar'},
    ],
]

### Example 7.20
Single Pair Explicit Entry
=== input
[
? foo
 bar : baz
]
...
%YAML 1.2
---
!!seq [
  !!map {
    ? !!str "foo bar"
    : !!str "baz",
  },
]
=== expected
[
    [
        {'foo bar' => 'baz'},
    ],
    [
        {'foo bar' => 'baz'},
    ],
]

### Example 7.21
Single Pair Implicit Entries
=== input skiptest
- [ YAML : separate ]
- [ : empty key entry ]
- [ {JSON: like}:adjacent ]
...
%YAML 1.2
---
!!seq [
  !!seq [
    !!map {
      ? !!str "YAML"
      : !!str "separate"
    },
  ],
  !!seq [
    !!map {
      ? !!null ""
      : !!str "empty key entry"
    },
  ],
  !!seq [
    !!map {
      ? !!map {
        ? !!str "JSON"
        : !!str "like"
      } : "adjacent",
    },
  ],
]
=== expected skiptest
[
    [
        [{'YAML' => 'separate'}],
        [{q() => 'empty key entry'}],
        [{{'JSON' => 'like'} => 'adjacent'}],
    ],
    [
        [{'YAML' => 'separate'}],
        [{q() => 'empty key entry'}],
        [{{'JSON' => 'like'} => 'adjacent'}],
    ],
]

### Example 7.21 Modified
Single Pair Implicit Entries
(There is no way overriding from single pair to !!perl/array) 
=== input
- [ YAML : separate ]
- [ : empty key entry ]
- [ 'JSON: like':adjacent ]
...
%YAML 1.2
---
!!seq [
  !!seq [
    !!map {
      ? !!str "YAML"
      : !!str "separate"
    },
  ],
  !!seq [
    !!map {
      ? !!null ""
      : !!str "empty key entry"
    },
  ],
  !!seq [
    !!map {
      ? !!str 'JSON: like' : !!str "adjacent",
    },
  ],
]
=== expected
[
    [
        [{'YAML' => 'separate'}],
        [{q() => 'empty key entry'}],
        [{'JSON: like' => 'adjacent'}],
    ],
    [
        [{'YAML' => 'separate'}],
        [{q() => 'empty key entry'}],
        [{'JSON: like' => 'adjacent'}],
    ],
]

### Example 7.23
Flow Content
=== input
- [ a, b ]
- { a: b }
- "a"
- 'b'
- c
...
%YAML 1.2
---
!!seq [
  !!seq [ !!str "a", !!str "b" ],
  !!map { ? !!str "a" : !!str "b" },
  !!str "a",
  !!str "b",
  !!str "c",
]
=== expected
[
    [
        ['a', 'b'],
        {'a' => 'b'},
        'a',
        'b',
        'c',
    ],
    [
        ['a', 'b'],
        {'a' => 'b'},
        'a',
        'b',
        'c',
    ],
]

### Example 7.24
Flow Nodes
=== input
- !!str "a"
- 'b'
- &anchor "c"
- *anchor
- !!str
...
%YAML 1.2
---
!!seq [
  !!str "a",
  !!str "b",
  &A !!str "c",
  *A,
  !!str "",
]
=== expected
my $anchor = 'c';
my $A = 'c';
[
    [
        'a',
        'b',
        $anchor,
        $anchor,
        q(),
    ],
    [
        'a',
        'b',
        $A,
        $A,
        q(),
    ],
]

### Example 8.1
Block Scalar Header
=== input
- | # Empty header
 literal
- >1 # Indentation indicator
  folded
- |+ # Chomping indicator
 keep

- >1- # Both indicators
  strip

...
%YAML 1.2
---
!!seq [
  !!str "literal\n",
  !!str " folded\n",
  !!str "keep\n\n",
  !!str " strip",
]
=== expected
[
    [
        "literal\n",
        " folded\n",
        "keep\n\n",
        " strip",
    ],
    [
        "literal\n",
        " folded\n",
        "keep\n\n",
        " strip",
    ],
]

### Example 8.2
Block Indentation Indicator
(There is a mistake in this example of specification.
 In 2nd folded, first line should be treated as the l-empty)
=== input
- |
 detected
- >
 
  
  # detected
- |1
  explicit
- >
 	
 detected
...
%YAML 1.2
---
!!seq [
  !!str "detected\n",
  !!str "\n\n# detected\n",
  !!str " explicit\n",
  !!str "\ndetected\n",
]
=== expected
[
    [
        "detected\n",
        "\n\n# detected\n",
        " explicit\n",
        "\ndetected\n",
    ],
    [
        "detected\n",
        "\n\n# detected\n",
        " explicit\n",
        "\ndetected\n",
    ],
]

### Example 8.4
Chomping Final Line Break
=== input
strip: |-
  text
clip: |
  text
keep: |+
  text
...
%YAML 1.2
---
!!map {
  ? !!str "strip"
  : !!str "text",
  ? !!str "clip"
  : !!str "text\n",
  ? !!str "keep"
  : !!str "text\n",
}
=== expected
[
    {
        'strip' => qq(text),
        'clip' => qq(text\n),
        'keep' => qq(text\n),
    },
    {
        'strip' => qq(text),
        'clip' => qq(text\n),
        'keep' => qq(text\n),
    },
]

### Example 8.5
Chomping Trailing Lines
(There is a mistake in this example of specification.
 In keep literal, we should get double line-feeds)
=== input
 # Strip
  # Comments:
strip: |-
  # text
  
 # Clip
  # comments:

clip: |
  # text
 
 # Keep
  # comments:

keep: |+
  # text

 # Trail
  # comments.
...
%YAML 1.2
---
!!map {
  ? !!str "strip"
  : !!str "# text",
  ? !!str "clip"
  : !!str "# text\n",
  ? !!str "keep"
  : !!str "# text\n\n",
}
=== expected
[
    {
        'strip' => qq(# text),
        'clip' => qq(# text\n),
        'keep' => qq(# text\n\n),
    },
    {
        'strip' => qq(# text),
        'clip' => qq(# text\n),
        'keep' => qq(# text\n\n),
    },
]

### Example 8.6.
Empty Scalar Chomping
=== input
strip: >-

clip: >

keep: |+

...
%YAML 1.2
---
!!map {
  ? !!str "strip"
  : !!str "",
  ? !!str "clip"
  : !!str "",
  ? !!str "keep"
  : !!str "\n",
}
=== expected
[
    {
        'strip' => q(),
        'clip' => q(),
        'keep' => qq(\n),
    },
    {
        'strip' => q(),
        'clip' => q(),
        'keep' => qq(\n),
    },
]

### Example 8.7
Literal Scalar
=== input
|
 literal
 	text

...
%YAML 1.2
---
!!str "literal\n\ttext\n"
=== expected
[
    qq(literal\n\ttext\n),
    qq(literal\n\ttext\n),
]

### Example 8.8
Literal Content
=== input
|
 
  
  literal
   
  
  text

 # Comment
...
%YAML 1.2
---
!!str "\n\nliteral\n \n\ntext\n"
=== expected
[
    qq(\n\nliteral\n \n\ntext\n),
    qq(\n\nliteral\n \n\ntext\n),
]

### Example 8.9
Folded Scalar
=== input
>
 folded
 text


...
%YAML 1.2
---
!!str "folded text\n"
=== expected
[
    qq(folded text\n),
    qq(folded text\n),
]

### Example 8.10
Folded Lines
=== input
>

 folded
 line

 next
 line
   * bullet

   * list
   * lines

 last
 line

# Comment
...
%YAML 1.2
---
!!str "\n\
      folded line\n\
      next line\n\
      \  * bullet\n\
      \n\
      \  * list\n\
      \  * lines\n\
      \n\
      last line\n"
=== expected
[
      qq(\n)
    . qq(folded line\n)
    . qq(next line\n)
    . qq(  * bullet\n)
    . qq(\n)
    . qq(  * list\n)
    . qq(  * lines\n)
    . qq(\n)
    . qq(last line\n),

      qq(\n)
    . qq(folded line\n)
    . qq(next line\n)
    . qq(  * bullet\n)
    . qq(\n)
    . qq(  * list\n)
    . qq(  * lines\n)
    . qq(\n)
    . qq(last line\n),
]

### Example 8.14
Block Sequence
=== input
block sequence:
  - one
  - two : three
...
%YAML 1.2
---
!!map {
  ? !!str "block sequence"
  : !!seq [
    !!str "one",
    !!map {
      ? !!str "two"
      : !!str "three"
    },
  ],
}
=== expected
[
    {
        'block sequence' => [
            'one',
            {'two' => 'three'},
        ]
    },
    {
        'block sequence' => [
            'one',
            {'two' => 'three'},
        ]
    },
]

### Example 8.15
Block Sequence Entry Types 
=== input
- # Empty
- |
 block node
- - one # Compact
  - two # sequence
- one: two # Compact mapping
...
%YAML 1.2
---
!!seq [
  !!null "",
  !!str "block node\n",
  !!seq [
    !!str "one",
    !!str "two",
  ],
  !!map {
    ? !!str "one"
    : !!str "two",
  },
]
=== expected
[
    [
        undef,
        qq(block node\n),
        [
            'one',
            'two',
        ],
        { 'one' => 'two'},
    ],
    [
        undef,
        qq(block node\n),
        [
            'one',
            'two',
        ],
        { 'one' => 'two'},
    ],
]

### Example 8.16
Block Mappings
=== input
block mapping:
 key: value
...
%YAML 1.2
---
!!map {
  ? !!str "block mapping"
  : !!map {
    ? !!str "key"
    : !!str "value",
  },
}
=== expected
[
    {
        'block mapping' => {
            'key' => 'value',
        },
    },
    {
        'block mapping' => {
            'key' => 'value',
        },
    },
]

### Example 8.17
Explicit Block Mapping Entries
=== input
? explicit key # Empty value
? |
  block key
: - one # Explicit compact
  - two # block value
...
%YAML 1.2
---
!!map {
  ? !!str "explicit key"
  : !!null "",
  ? !!str "block key\n"
  : !!seq [
    !!str "one",
    !!str "two",
  ],
}
=== expected
[
    {
        'explicit key' => undef,
        "block key\n" => [
            'one',
            'two',
        ],
    },
    {
        'explicit key' => undef,
        "block key\n" => [
            'one',
            'two',
        ],
    },
]

### Example 8.18
Implicit Block Mapping Entries
=== input
plain key: in-line value
: # Both empty
"quoted key":
- entry
...
%YAML 1.2
---
!!map {
  ? !!str "plain key"
  : !!str "in-line value",
  ? !!null ""
  : !!null "",
  ? !!str "quoted key"
  : !!seq [ !!str "entry" ],
}
=== expected
[
    {
        'plain key' => 'in-line value',
        q() => undef,
        'quoted key' => [
            'entry',
        ],
    },
    {
        'plain key' => 'in-line value',
        q() => undef,
        'quoted key' => [
            'entry',
        ],
    },
]

### Example 8.19
Compact Block Mappings
=== input skiptest
- sun: yellow
- ? earth: blue
  : moon: white
...
%YAML 1.2
---
!!seq [
  !!map {
     !!str "sun" : !!str "yellow",
  },
  !!map {
    ? !!map {
      ? !!str "earth"
      : !!str "blue"
    }
    : !!map {
      ? !!str "moon"
      : !!str "white"
    },
  }
]
=== expected skiptest
[
    [
        {'sun' => 'yellow'},
        {
            {'earth' => 'blue'} => {'moon' => 'white'},
        },
    ],
    [
        {'sun' => 'yellow'},
        {
            {'earth' => 'blue'} => {'moon' => 'white'},
        },
    ],
]

### Example 8.19 Modified
Compact Block Mappings
=== input
- sun: yellow
- ? 'earth: blue'
  : moon: white
...
%YAML 1.2
---
!!seq [
  !!map {
     !!str "sun" : !!str "yellow",
  },
  !!map {
    ? !!str "earth: blue"
    : !!map {
      ? !!str "moon"
      : !!str "white"
    },
  }
]
...
# There is no way override tags for compact mapping.
---
- sun: yellow
- !!perl/array
  ? earth: blue
  : moon: white
...
%YAML 1.2
---
!!seq [
  !!map {
     !!str "sun" : !!str "yellow",
  },
  !!perl/array {
    ? !!map {
      ? !!str "earth"
      : !!str "blue"
    }
    : !!map {
      ? !!str "moon"
      : !!str "white"
    },
  }
]
=== expected
[
    [
        {'sun' => 'yellow'},
        {'earth: blue' => {'moon' => 'white'}},
    ],
    [
        {'sun' => 'yellow'},
        {'earth: blue' => {'moon' => 'white'}},
    ],

    [
        {'sun' => 'yellow'},
        [
            {'earth' => 'blue'} => {'moon' => 'white'},
        ],
    ],
    [
        {'sun' => 'yellow'},
        [
            {'earth' => 'blue'} => {'moon' => 'white'},
        ],
    ],
]

### Example 8.20
Block Node Types
=== input
-
  "flow in block"
- >
 Block scalar
- !!map # Block collection
  foo : bar
...
%YAML 1.2
---
!!seq [
  !!str "flow in block",
  !!str "Block scalar\n",
  !!map {
    ? !!str "foo"
    : !!str "bar",
  },
]
=== expected
[
    [
        'flow in block',
        qq(Block scalar\n),
        {
            'foo' => 'bar',
        },
    ],
    [
        'flow in block',
        qq(Block scalar\n),
        {
            'foo' => 'bar',
        },
    ],
]

### Example 8.21
Block Scalar Nodes
=== input
literal: |2
  value
folded:
   !foo
  >1
 value
...
%YAML 1.2
---
!!map {
  ? !!str "literal"
  : !!str "value\n",
  ? !!str "folded"
  : !<!foo> "value\n",
}
=== expected
[
    {
        'literal' => qq(value\n),
        'folded' => qq(value\n),
    },
    {
        'literal' => qq(value\n),
        'folded' => qq(value\n),
    },
]

### Example 8.22
Block Collection Nodes
=== input
sequence: !!seq
- entry
- !!seq
 - nested
mapping: !!map
 foo: bar
...
%YAML 1.2
---
!!map {
  ? !!str "sequence"
  : !!seq [
    !!str "entry",
    !!seq [ !!str "nested" ],
  ],
  ? !!str "mapping"
  : !!map {
    ? !!str "foo" : !!str "bar",
  },
}
=== expected
[
    {
        'sequence' => [
            'entry',
            ['nested'],
        ],
        'mapping' => {
            'foo' => 'bar',
        },
    },
    {
        'sequence' => [
            'entry',
            ['nested'],
        ],
        'mapping' => {
            'foo' => 'bar',
        },
    },
]

### Example 9.1
Document Prefix
=== input
# Comment
# lines
Document
...
%YAML 1.2
---
!!str "Document"
=== expected
[
    'Document',

    'Document',
]

### Example 9.2
Document Markers
=== input
%YAML 1.2
---
Document
... # Suffix
...
%YAML 1.2
---
!!str "Document"
=== expected
[
    'Document',

    'Document',
]

### Example 9.3
Bare Documents
=== input
Bare
document
...
# No document
...
|
%!PS-Adobe-2.0 # Not the first line
...
%YAML 1.2
---
!!str "Bare document"
...
%YAML 1.2
---
!!str "%!PS-Adobe-2.0\n"
=== expected
[
    'Bare document',
    qq(%!PS-Adobe-2.0 # Not the first line\n),

    'Bare document',
    qq(%!PS-Adobe-2.0\n),
]

### Example 9.4
Explicit Documents
=== input
---
{ matches
% : 20 }
...
---
# Empty
...
...
%YAML 1.2
---
!!map {
  !!str "matches %": !!int "20"
}
...
%YAML 1.2
---
!!null ""
=== expected
[
    {'matches %' => 20},
    undef,

    {'matches %' => 20},
    undef,
]

### Example 9.5
Directives Documents
=== input
%YAML 1.2
--- |
%!PS-Adobe-2.0
...
%YAML1.2
---
# Empty
...
...
%YAML 1.2
---
!!str "%!PS-Adobe-2.0\n"
...
%YAML 1.2
---
!!null ""
=== expected
[
    "%!PS-Adobe-2.0\n",
    undef,

    "%!PS-Adobe-2.0\n",
    undef,
]

### Example 9.6
Stream
=== input
Document
---
# Empty
...
%YAML 1.2
---
matches %: 20
...
%YAML 1.2
---
!!str "Document"
...
%YAML 1.2
---
!!null ""
...
%YAML 1.2
---
!!map {
  !!str "matches %": !!int "20"
}
=== expected
[
    'Document',
    undef,
    {'matches %' => 20},

    'Document',
    undef,
    {'matches %' => 20},
]

### Example 10.1
!!map Examples
=== input
Block style: !!map
  Clark : Evans
  Ingy  : dot Net
  Oren  : Ben-Kiki

Flow style: !!map { Clark: Evans, Ingy: dot Net, Oren: Ben-Kiki }
=== expected
[
    {
        'Block style' => {
            'Clark' => 'Evans',
            'Ingy' => 'dot Net',
            'Oren' => 'Ben-Kiki',
        },
        'Flow style' => {
            'Clark' => 'Evans', 'Ingy' => 'dot Net', 'Oren' => 'Ben-Kiki',
        },
    },
]

### Example 10.2
!!seq Examples
=== input
Block style: !!seq
- Clark Evans
- Ingy dot Net
- Oren Ben-Kiki

Flow style: !!seq [ Clark Evans, Ingy dot Net, Oren Ben-Kiki ]
=== expected
[
    {
        'Block style' => [
            'Clark Evans',
            'Ingy dot Net',
            'Oren Ben-Kiki',
        ],
        'Flow style' => ['Clark Evans', 'Ingy dot Net', 'Oren Ben-Kiki'],
    },
]

### Example 10.2 Override
!!seq Examples
YAML::Loaf::Load allows you to override mapping.
=== input
Block style: !!perl/array
  Clark : Evans
  Ingy  : dot Net
  Oren  : Ben-Kiki

Flow style: !!perl/array { Clark: Evans, Ingy: dot Net, Oren: Ben-Kiki }
=== expected
[
    {
        'Block style' => [
            'Clark' => 'Evans',
            'Ingy' => 'dot Net',
            'Oren' => 'Ben-Kiki',
        ],
        'Flow style' => [
            'Clark' => 'Evans', 'Ingy' => 'dot Net', 'Oren' => 'Ben-Kiki',
        ],
    },
]

### Example 10.3
!!str Examples
=== input
Block style: !!str |-
  String: just a theory.

Flow style: !!str "String: just a theory."
=== expected
[
    {
        'Block style' => qq(String: just a theory.),
        'Flow style' => qq(String: just a theory.),
    },
]

### Example 10.4
!!null Examples
=== input
!!null null: value for null key
key with null value: !!null null
=== expected
[
    {
        q() => 'value for null key', # perl's key must be a string.
        'key with null value' => undef,
    },
]

### Example 10.5
!!bool Examples
=== input
YAML is a superset of JSON: !!bool true
Pluto is a planet: !!bool false
=== expected
[
    {
        'YAML is a superset of JSON' => 'true',
        'Pluto is a planet' => q(), # this is perl's false
    },
]

### Example 10.6
!!int Examples
=== input
negative: !!int -12
zero: !!int 0
positive: !!int 34
=== expected
[
    {
        'negative' => '-12',
        'zero' => '0',
        'positive' => '34',
    },
]

### Example 10.7
!!float Examples
=== input
negative: !!float -1
zero: !!float 0
positive: !!float 2.3e4
infinity: !!float .inf
not a number: !!float .nan
=== expected
[
    {
        'negative' => '-1',
        'zero' => '0',
        'positive' => '2.3e4',
        'infinity' => '.inf',
        'not a number' => '.nan',
    },
]

### Example 10.8
JSON Tag Resolution
(YAML::Loaf::Load cannot restrict into JSON Schema)
=== input
A null: null
Booleans: [ true, false ]
Integers: [ 0, -0, 3, -19 ]
Floats: [ 0., -0.0, 12e03, -2E+05 ]
Invalid: [ True, Null, 0o7, 0x3A, +12.3 ]
...
%YAML 1.2
---
!!map {
  !!str "A null" : !!null "null",
  !!str "Booleans": !!seq [
    !!bool "true", !!bool "false"
  ],
  !!str "Integers": !!seq [
    !!int "0", !!int "-0",
    !!int "3", !!int "-19"
  ],
  !!str "Floats": !!seq [
    !!float "0.", !!float "-0.0",
    !!float "12e03", !!float "-2E+05"
  ],
  !!str "Invalid": !!seq [
    # Rejected by the schema
    True, Null, 0o7, 0x3A, +12.3,
  ],
}
=== expected
[
    {
        'A null' => undef,
        'Booleans' => ['true', q()],
        'Integers' => ['0', '-0', '3', '-19'],
        'Floats' => ['0.', '-0.0', '12e03', '-2E+05'],
        'Invalid' => ['True', undef, 007, 0x3A, '+12.3'],
    },
    {
        'A null' => undef,
        'Booleans' => ['true', q()],
        'Integers' => ['0', '-0', '3', '-19'],
        'Floats' => ['0.', '-0.0', '12e03', '-2E+05'],
        'Invalid' => ['True', undef, 007, 0x3A, '+12.3'],
    },
]

### Example 10.9
Core Tag Resolution
=== input
A null: null
Also a null: # Empty
Not a null: ""
Booleans: [ true, True, false, FALSE ]
Integers: [ 0, 0o7, 0x3A, -19 ]
Floats: [ 0., -0.0, .5, +12e03, -2E+05 ]
Also floats: [ .inf, -.Inf, +.INF, .NAN ]
...
%YAML 1.2
---
!!map {
  !!str "A null" : !!null "null",
  !!str "Also a null" : !!null "",
  !!str "Not a null" : !!str "",
  !!str "Booleans": !!seq [
    !!bool "true", !!bool "True",
    !!bool "false", !!bool "FALSE",
  ],
  !!str "Integers": !!seq [
    !!int "0", !!int "0o7",
    !!int "0x3A", !!int "-19",
  ],
  !!str "Floats": !!seq [
    !!float "0.", !!float "-0.0", !!float ".5",
    !!float "+12e03", !!float "-2E+05"
  ],
  !!str "Also floats": !!seq [
    !!float ".inf", !!float "-.Inf",
    !!float "+.INF", !!float ".NAN",
  ],
}
=== expected
[
    {
        'A null' => undef,
        'Also a null' => undef,
        'Not a null' => q(),
        'Booleans' => ['true', 'True', q(), q()],
        'Integers' => ['0', 007, 0x3A, '-19'],
        'Floats' => ['0.', '-0.0', '.5', '+12e03', '-2E+05'],
        'Also floats' => ['.inf', '-.Inf', '+.INF', '.NAN'],
    },
    {
        'A null' => undef,
        'Also a null' => undef,
        'Not a null' => q(),
        'Booleans' => ['true', 'True', q(), q()],
        'Integers' => ['0', 007, 0x3A, '-19'],
        'Floats' => ['0.', '-0.0', '.5', '+12e03', '-2E+05'],
        'Also floats' => ['.inf', '-.Inf', '+.INF', '.NAN'],
    },
]

