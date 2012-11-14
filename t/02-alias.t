use strict;
use warnings;
use Test::Base;
use YAML::Loaf;

delimiters('###', '===');

plan tests => 9;

filters {
    'input' => [qw(chomp yaml_stream)],
};

sub yaml_stream {
    my($input) = @_;
    # YAML::Loaf::Load returns all documents on array contexts.
    return YAML::Loaf::Load($input);
}

my $get_block = sub {
    my %dic = map { $_->name => $_ } blocks();
    return sub{
        my($name) = @_;
        return $dic{$name};
    };
}->();

# from YAML-LibYAML-0.38/t/alias.t

{
    my $x = $get_block->('Non-Cyclic Reference')->input;

    is "$x->[0]", "$x->[1]{'foo'}", 'not cyclic reference';
    push @{$x->[0]}, 'd';
    is_deeply $x->[1]{'foo'}, [qw(a b c d)], 'shared same arrayref object';
}

{
    my $x = $get_block->('Cyclic Reference')->input;

    is "$x->{'foo'}", "$x->{'foo'}[0]", 'cyclic parent and child';
    is "$x", "$x->{'foo'}[1]", 'cyclic root and leaf';

    @{$x->{'foo'}} = ();
}

{
    my $x = $get_block->('Scalar Duplication')->input;

    is $x->{'bar'}, $x->{'foo'}, 'dup scalar';
    $x->{'foo'} .= "foo();\n";
    isnt $x->{'bar'}, $x->{'foo'}, 'they own other PV';
}

{
    my $x = $get_block->('Regexp Reference')->input;

    is $x->{'bar'}, $x->{'foo'}, 'refer regexp';
    is ref $x->{'bar'}, 'Regexp', 'alias is also regexp reference';
    like 'falala', $x->{'bar'}, 'aliased regexp works';
}

__END__

### Non-Cyclic Reference
=== input
---
- &one [a, b, c]
- foo: *one

### Cyclic Reference
=== input
--- &1
foo: &2 [*2, *1]

### Scalar Duplication
=== input
---
foo: &text |
  sub foo {
      say 'hello';
  }
bar: *text

### Regexp Reference
=== input
---
foo: &rx !!perl/regexp (?-xsim:lala)
bar: *rx

