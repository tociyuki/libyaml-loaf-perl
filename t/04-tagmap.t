use strict;
use warnings;
use Test::Base;
use YAML::Loaf;
use Data::Dumper ();

delimiters('###', '===');

plan tests => 1 * blocks;

filters {
    'tagmap' => [qw(eval)],
    'expected' => [qw(eval)],
};

run {
    my($block) = @_;
    my $input = $block->input;
    my $tagmap = $block->tagmap;
    my $expected = $block->expected;
    my $got = [YAML::Loaf::Load($input, 'tagmap' => $tagmap)];
    my $got_dump = Data::Dumper->new([$got])->Indent(1)->Dump;
    my $expected_dump = Data::Dumper->new([$expected])->Indent(1)->Dump;
    is $got_dump, $expected_dump, $block->name;    
};

__END__

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
=== tagmap
+{
    'tag:clarkevans.com,2002:shape'
        => 'tag:yaml.org,2002:perl/:Shape',
    'tag:clarkevans.com,2002:circle'
        => 'tag:yaml.org,2002:perl/:Shape::Circle',
    'tag:clarkevans.com,2002:line'
        => 'tag:yaml.org,2002:perl/:Shape::Line',
    'tag:clarkevans.com,2002:label'
        => 'tag:yaml.org,2002:perl/:Shape::Label',
}
=== expected
my $origin = {'x' => '73', 'y' => '129'};
[
    bless([
        bless({
            'center' => $origin,
            'radius' => '7',
        }, 'Shape::Circle'),
        bless({
            'start' => $origin,
            'finish' => {'x' => '89', 'y' => '102'},
        }, 'Shape::Line'),
        bless({
            'start' => $origin,
            'color' => 0xFFEEBB,
            'text' => 'Pretty vector drawing.',
        }, 'Shape::Label'),
    ], 'Shape'),
]

### Example 6.18
Primary Tag Handle
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
=== tagmap
+{
    '!foo'
        => 'tag:yaml.org,2002:perl/:Foo::Private',
    'tag:example.com,2000:app/foo'
        => 'tag:yaml.org,2002:perl/:Foo::Global',
}
=== expected
my $x1 = 'bar';
my $x2 = 'bar';
my $x3 = 'bar';
my $x4 = 'bar';
[
	bless(\$x1, 'Foo::Private'),
	bless(\$x2, 'Foo::Global'),
	bless(\$x3, 'Foo::Private'),
	bless(\$x4, 'Foo::Global'),
]

### Example 6.19
Secondary Tag Handle
=== input
%TAG !! tag:example.com,2000:app/
---
!!int 1 - 3 # Interval, not integer
...
%YAML 1.2
---
!<tag:example.com,2000:app/int> "1 - 3"
=== tagmap
+{
    'tag:example.com,2000:app/int'
        => 'tag:yaml.org,2002:perl/:App::Int',
}
=== expected
my $a = "1 - 3";
my $b = "1 - 3";
[
	bless(\$a, 'App::Int'),
	bless(\$b, 'App::Int'),
]

### Example 6.20
Tag Handles
=== input
%TAG !e! tag:example.com,2000:app/
---
!e!foo "bar"
...
%YAML 1.2
---
!<tag:example.com,2000:app/foo> "bar"
=== tagmap
+{
    'tag:example.com,2000:app/foo'
        => 'tag:yaml.org,2002:perl/:App::Foo',
}
=== expected
my $bar0 = "bar";
my $bar1 = "bar";
[
	bless(\$bar0, 'App::Foo'),
	bless(\$bar1, 'App::Foo'),
]

### Example 6.21
Local Tag Prefix
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
=== tagmap
+{
    '!my-light' => 'tag:yaml.org,2002:perl/:MyLight',
}
=== expected
my $fluorescent0 = "fluorescent";
my $green0 = "green";
my $fluorescent1 = "fluorescent";
my $green1 = "green";
[
	bless(\$fluorescent0, 'MyLight'),
	bless(\$green0, 'MyLight'),
	bless(\$fluorescent1, 'MyLight'),
	bless(\$green1, 'MyLight'),
]

### Example 6.22
Global Tag Prefix
=== input
%TAG !e! tag:example.com,2000:app/
---
- !e!foo "bar"
...
%YAML 1.2
---
- !<tag:example.com,2000:app/foo> "bar"
=== tagmap
+{
    'tag:example.com,2000:app/foo' => 'tag:yaml.org,2002:perl/:App::Foo',
}
=== expected
my $bar0 = 'bar';
my $bar1 = 'bar';
[
	[bless(\$bar0, 'App::Foo')],
	[bless(\$bar1, 'App::Foo')],
]

### Example 6.24
Verbatim Tags
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
=== tagmap
+{
    '!bar' => 'tag:yaml.org,2002:perl/:Bar',
}
=== expected
my $baz0 = 'baz';
my $baz1 = 'baz';
[
	{'foo' => (bless \$baz0, 'Bar')},
	{'foo' => (bless \$baz1, 'Bar')},
]

### Example 6.26
Tag Shorthands
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
=== tagmap
+{
    '!local' => 'tag:yaml.org,2002:perl/:ExamLocal',
    'tag:example.com,2000:app/tag!' => 'tag:yaml.org,2002:perl/:ExamTag',
}
=== expected
my $foo0 = 'foo';
my $baz0 = 'baz';
my $foo1 = 'foo';
my $baz1 = 'baz';
[
	[
	    bless(\$foo0, 'ExamLocal'),
	    'bar',
	    bless(\$baz0, 'ExamTag'),
    ],
	[
	    bless(\$foo1, 'ExamLocal'),
	    'bar',
	    bless(\$baz1, 'ExamTag'),
    ],
]

