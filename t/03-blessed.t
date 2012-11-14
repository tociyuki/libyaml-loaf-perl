use strict;
use warnings;
use Test::Base;
use YAML::Loaf;
use Data::Dumper ();

delimiters('###', '===');

plan tests => 12;

filters {
    'yaml' => [qw(chomp yaml_stream)],
    'perl' => [qw(eval)],
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

# from YAML-LibYAML-0.38/t/blessed.t

{
    my $test = $get_block->('Blessed Hashes and Arrays');

    my $yaml = $test->yaml;
    my $perl = $test->perl;
    my $yaml_dump = Data::Dumper->new([$yaml])->Dump;
    my $perl_dump = Data::Dumper->new([$perl])->Dump;
    is $yaml_dump, $perl_dump, 'blessed hashes and arrays';
    like "$yaml->{'foo'}", qr/\AFoo::Bar=HASH[(]/msx, q(foo is bless {}, 'Foo::Bar');
    like "$yaml->{'bar'}", qr/\AFoo::Bar=HASH[(]/msx, q(bar is bless {}, 'Foo::Bar');
    like "$yaml->{'one'}", qr/\ABigList=ARRAY[(]/msx, q(one is bless [], 'BigList');
    like "$yaml->{'two'}", qr/\ABigList=ARRAY[(]/msx, q(two is bless [], 'BigList');
    ok $yaml->{'foo'}->isa('Foo::Bar'), q(foo isa Foo::Bar);
    ok $yaml->{'bar'}->isa('Foo::Bar'), q(bar isa Foo::Bar);
    ok $yaml->{'one'}->isa('BigList'), q(one isa BigList);
    ok $yaml->{'two'}->isa('BigList'), q(two isa BigList);
}

{
    my $test = $get_block->('Blessed Scalar Ref');

    my $yaml = $test->yaml;
    my $perl = $test->perl;
    my $yaml_dump = Data::Dumper->new([$yaml])->Dump;
    my $perl_dump = Data::Dumper->new([$perl])->Dump;
    is $yaml_dump, $perl_dump, 'blessed scalar ref';    
    like "$yaml->[0]", qr/\ABlessed=SCALAR[(]/msx, q(it is scalar ref 'Foo::Bar');
    ok $yaml->[0]->isa('Blessed'), q(it isa Blessed);
}

__END__

### Blessed Hashes and Arrays
=== yaml
foo: !!perl/hash:Foo::Bar {}
bar: !!perl/hash:Foo::Bar
  bass: bawl
one: !!perl/array:BigList []
two: !!perl/array:BigList
- lola
- alol
=== perl
+{
    foo => (bless {}, "Foo::Bar"),
    bar => (bless {bass => 'bawl'}, "Foo::Bar"),
    one => (bless [], "BigList"),
    two => (bless [lola => 'alol'], "BigList"),
};

### Blessed Scalar Ref
=== yaml
---
- !!perl/scalar:Blessed hey hey
=== perl
my $x = 'hey hey';
[bless \$x, 'Blessed'];

