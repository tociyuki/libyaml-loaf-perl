package YAML::Loaf;
use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01'; # $Id$

my $FALSE = q();
my %YAML_CORE = (
    (map { $_ => undef   } qw(null Null NULL ~)),
    (map { $_ => $_      } qw(true True TRUE y Y Yes YES on On ON)),
    (map { $_ => $FALSE } qw(false False FALSE n N No NO off Off OFF)),
);
my $PKG = qr/[A-Za-z_][A-Za-z0-9_]*(?:[:][:][A-Za-z_][A-Za-z0-9_]*)*/msx;
my $PERLBASIC = qr/hash|array|scalar|code|io|glob|regexp|ref|object/msx;
my $S_B_COMMENT = qr/(?:[ \t]+(?:\#[^\n]*)?)?\n/msx;
my $L_COMMENT = qr/[ \t]*(?:\#[^\n]*)?\n/msx;
my $S_L_COMMENTS = qr/($S_B_COMMENT $L_COMMENT*)/msx;
my $URICHAR = qr{(?:%[[:xdigit:]]{2}|[0-9A-Za-z\-\#;/?:\@&=+\$,_.!~*'()\[\]])}msx;
my $TAGCHAR = qr{(?:%[[:xdigit:]]{2}|[0-9A-Za-z\-\#;/?:\@&=+\$_.~*'()])}msx;
my $TAG_PROPERTY =
    qr{([!](?:<$URICHAR+>|(?:[!]|[0-9A-Za-z-]+[!])?$TAGCHAR+)?)}msx;
my $ANCHOR_PROPERTY = qr/(&[^\P{Graph},\[\]\{\}]+)/msx;
my $BLOCK_SCALAR =
    qr/([|>])(?:([0-9])([+-]?)|([+-])([0-9])?)?$S_B_COMMENT/msx;
my $ALIAS_NODE = qr/[*]([^\P{Graph},\[\]\{\}]+)/msx;
my $PLAIN_WORD_OUT = qr{
    (?:[^\P{Graph}:\#]|[:](?=\p{Graph}))
    [^\P{Graph}:]*(?:[:]+[^\P{Graph}:]+)*
}msx;
my $PLAIN_WORD_IN = qr{
    (?:[^\P{Graph}:\#,\[\]\{\}]|[:](?=[^\P{Graph},\[\]\{\}]))
    [^\P{Graph}:,\[\]\{\}]*(?:[:]+[^\P{Graph}:,\[\]\{\}]+)*
}msx;
my $PLAIN_ONE_OUT = qr{
    (?!(?:^---|^[.][.][.]))
    (?:[^\P{Graph}?:\-,\[\]\{\}\#&*!|>'"%\@`]|[?:\-](?=\p{Graph}))
    [^\P{Graph}:]*(?:[:]+[^\P{Graph}:]+)*
    (?:[ \t]+$PLAIN_WORD_OUT)*
}msx;
my $PLAIN_ONE_IN = qr{
    (?!(?:^---|^[.][.][.]))
    (?:[^\P{Graph}?:\-,\[\]\{\}\#&*!|>'"%\@`]|[?:\-](?=[^\P{Graph},\[\]\{\}]))
    [^\P{Graph}:,\[\]\{\}]*(?:[:]+[^\P{Graph}:,\[\]\{\}]+)*
    (?:[ \t]+$PLAIN_WORD_IN)*
}msx;
my $SINGLE_QUOTED = qr/([^']*(?:''[^']*)*)/msx;
my $DOUBLE_QUOTED =
    qr{([^"\\]*(?:\\[0abt\t\nnvfre "/\\N_LPxuU][^"\\]*)*)}msx;
my %UNESCAPE = (
    '0' => "\x00", 'a' => "\x07", 'b' => "\x08", 't' => "\t", "\t" => "\t",
    'n' => "\n", 'v' => "\x0b", 'f' => "\f", 'r' => "\r", 'e' => "\e",
    q( ) => q( ), q(") => q("), q(/) => q(/), "\\" => "\\",
    'N' => "\x{0085}", '_' => "\x{00a0}", 'L' => "\x{2028}", 'P' => "\x{2029}",
);
my $DOC_PREFIX = qr{
    $L_COMMENT*
    (?:[.][.][.] $S_L_COMMENTS)+
    (?: (?:[%]\S+ (?:[ \t]+ [^\s\#]\S*)* $S_L_COMMENTS)+ (?=---) )?
}msx;

sub Load {
    my($string) = @_;
    $string =~ s/\r\n?|\n/\n/gmsx;
    chomp $string;
    $string = "...\n" . $string . "\n";
    my $derivs = [\$string, 0, {}];     # \source, location, stash
    my @doc;
    STREAM: while (my $d1 = _match($derivs, $DOC_PREFIX)) {
        $derivs = $d1;
        last if _end_of_file($derivs);
        if (! _match($derivs, '---')) {
            my $d2 = [@{$derivs}]; --$d2->[1]; # backward character
            if (my($d3, $node) = _block_node($d2, -1, 'block-in')) {
                push @doc, $node;
                %{$derivs->[2]} = ();   # clear stash
                return $doc[0] if ! wantarray;
                $derivs = $d3;
            }
        }
        while (my $d2 = _match($derivs, '---')) {
            $derivs = $d2;
            if (my($d3, $node) = _block_node($derivs, -1, 'block-in')) {
                push @doc, $node;
                %{$derivs->[2]} = ();   # clear stash
                return $doc[0] if ! wantarray;
                $derivs = $d3;
            }
            else {
                my $d3 = _match($derivs, $S_L_COMMENTS) or last STREAM;
                push @doc, undef;       # empty document
                $derivs = $d3;
            }
        }
    }
    _end_of_file($derivs) or croak 'SyntaxError: ' . _inspect($derivs);
    return wantarray ? @doc : $doc[0];
}

sub _anchor {
    my($node, $derivs, $anchor) = @_;
    return $node if ! $anchor;
    $derivs->[2]{$anchor} = $node;
    return $node;
}

sub _resolute {
    my($node, $tag) = @_;
    if (! $tag) {
    	$tag = ref $node eq 'ARRAY' ? '!!seq'
    		: ref $node eq 'HASH' ? '!!map'
    		: ! defined $node ? '!!null'
    		: '!!str';
    }
    $tag =~ s{\A!<tag:yaml.org,2002:(.*)>}{!!$1}omsx;
    if ($tag =~ m{\A
		!!perl/
		(?:	($PERLBASIC) (?:[:]($PKG))?
		|	[:]($PKG)
		|	(?!$PERLBASIC)($PKG) )    
    \z}omsx) {
    	my($type, $pkg) = ($1 || q(), $2 || $3 || $4 || q());
        return _resolute_perl($node, $type, $pkg);
	}
	if (! defined $node) {
	    return $tag eq '!!str' || $tag eq '!!binary' ? q()
	        : $tag eq '!!bool' ? $FALSE
	        : $tag eq '!!int' || $tag eq '!!float' ? 0
	        : $tag eq '!!seq' ? []
	        : $tag eq '!!map' ? {}
	        : undef;
	}
	return $node if ref $node;
    if ($tag eq '!!null' || $tag eq '!!bool') {
        return exists $YAML_CORE{$node} ? $YAML_CORE{$node}
            : $node ? $node
            : $tag eq '!!bool' ? $FALSE
            : undef;
    }
    if ($tag eq '!!int') {
    	return _resolute_int($node);
    }
	if ($tag eq '!!binary') {
        require MIME::Base64;
        return MIME::Base64::decode_base64($node);
	}
    return $node;
}

sub _resolute_perl {
    my($node, $type, $pkg) = @_;
	croak "YAML::Loaf::Load: !!perl/$type is not allowed."
		if $type eq 'code' || $type eq 'io' || $type eq 'glob';
	if ($type eq 'regexp') {
		$node = defined $node ? $node : q(.?);
		return $node if ref $node;
		return qr/$node/msx;
	}
	if ($type eq 'scalar') {
		$node = defined $node ? $node : q();
		return $node if ref $node;
		my $x = $node;
		return $pkg ? (bless \$x, $pkg) : \$x;
	}
	if ($type eq 'array') {
		$node = defined $node ? $node : [];
		if (ref $node eq 'HASH') {
			my $obj = [%{$node}];
			$node = $obj;
		}
	}
	if ($type eq 'hash') {
		$node = defined $node ? $node : {};
	}
	return $node if ! ref $node;
	$node = defined $node ? $node : {};
	return $pkg ? (bless $node, $pkg) : $node;
}

sub _resolute_plain {
    my($node, $tag) = @_;
    return $tag ? _resolute($node, $tag)
        : exists $YAML_CORE{$node} ? $YAML_CORE{$node}
        : _resolute_int($node);
}

sub _resolute_int {
    my($node) = @_;
    return $node =~ m/\A0o([0-7]+)\z/msx ? oct $1
        : $node =~ m/\A(?:0x[[:xdigit:]]+|0b[01]+)\z/msx ? oct $node
        : $node;
}

sub _properties {
    my($derivs, $n, $c) = @_;
    my($d1, $tag, $d2, $anchor);
    RULE: {
        ($d1, $tag) = _tag_property($derivs) or last;
        $d1 and $d2 = _separate($d1, $n, $c)
            and ($d2, $anchor) = _anchor_property($d2);
        return ($d2 || $d1, $tag, $anchor);
    }
    RULE: {
        ($d1, $anchor) = _anchor_property($derivs) or last;
        $d1 and $d2 = _separate($d1, $n, $c)
            and ($d2, $tag) = _tag_property($d2);
        return ($d2 || $d1, $tag, $anchor);
    }
    return;
}

sub _tag_property {
    my($derivs) = @_;
    return _memorize($derivs, 'tag-property', sub{
        my($d1, $tag) = _match($derivs, $TAG_PROPERTY) or return;
        return [$d1, $tag];
    });
}

sub _anchor_property {
    my($derivs) = @_;
    return _memorize($derivs, 'anchor-property', sub{
        my($d1, $anchor) = _match($derivs, $ANCHOR_PROPERTY) or return;
        return [$d1, $anchor];
    });
}

sub _block_node {
    my($derivs, $n, $c) = @_;
    RULE: {
        my $d1 = _separate($derivs, $n + 1, $c) or last;
        my($d2, $tag, $anchor) = _properties($d1, $n + 1, $c);
        my $d3 = $d2 && _separate($d2, $n + 1, $c) || $d1;
        my($d4, $node) = _block_scalar($d3, $n, $tag, $anchor) or last;
        return ($d4, $node);
    }
    RULE: {
        my($d1, $t, $tag, $a, $anchor, $d2, $node);
        $derivs
        and $d1 = _separate($derivs, $n + 1, $c)
        and ($d1, $t, $a) = _properties($d1, $n + 1, $c)
        and $d1 = _s_l_comments($d1)
        and ($tag, $anchor) = ($t, $a)
        or  $d1 = _s_l_comments($derivs) or last;
        my $n1 = $c eq 'block-out' ? $n - 1 : $n;
        $d1
        and (($d2, $node) = _block_sequence($d1, $n1, $tag, $anchor)
          or ($d2, $node) = _block_mapping($d1, $n, $tag, $anchor)
        ) or last;
        return ($d2, $node);
    }
    RULE: {
        my $d1 = _separate($derivs, $n + 1, 'flow-out') or last;
        my($d2, $node) = _flow_node($d1, $n + 1, 'flow-out') or last;
        my $d3 = _s_l_comments($d2) or last;
        return ($d3, $node);
    }
    return;
}

sub _block_scalar {
    my($derivs, $n, $tag, $anchor) = @_;
    my($d1, @capture) = _match($derivs, $BLOCK_SCALAR) or return;
    my $indentation = defined $capture[1] ? $capture[1] : $capture[4];
    my $chomp = $capture[2] || $capture[3] || q();
    if (! defined $indentation) {
        my(undef, $w) = _match($d1, qr/(?:[ \t]*\n)*([ ]*)[^ \n]/omsx);
        $w ||= q();
        $indentation = (length $w) - $n; 
    }
    my $n1 = $n + $indentation;
    my $lex = $n1 <= $n
    	? qr/((?:[ \t]*\n)*)/msx
    	: qr{(
    		(?:(?!(?:^---|^[.][.][.]))(?:[ ]{$n1}[\p{Graph} \t]+\n|[ ]*\n))*
		  )}msx;
    my($d2, $s) = _match($d1, $lex) or return;
	my $d3 = _s_l_comments($d2) || $d2;
    $n1 > 0 and $s =~ s/^[ ]{0,$n1}//gmsx;
    my $b_chomped_last = q();
    my $l_chomped_empty = $s =~ s/(\n+)\z//msx ? $1 : q();
    if (length $s > 0 && length $l_chomped_empty > 0) {
    	$b_chomped_last = $chomp eq q(-) ? q() : "\n";
    	chop $l_chomped_empty;
    }
    my $l_chomped =
          ! $chomp ? $b_chomped_last
        : $chomp eq q(+) ? $b_chomped_last . $l_chomped_empty
        : q();
    if ($capture[0] eq q(>)) {
        $s =~ s{^[ \t]*$}{}gmsx;
        $s =~ s{^([^ \t\n][^\n]*)\n(?=(\n*)[^ \t\n])}
               { $1 . ($2 ? q() : q( )) }egmsx;
    }
    return ($d3, _anchor(_resolute($s . $l_chomped, $tag), $d3, $anchor));
}

sub _block_sequence {
    my($derivs, $n, $tag, $anchor) = @_;
    my($d1, $w) = _match($derivs, qr/([ ]*)(?=[-][ \t\n])/omsx) or return;
    my $n1 = length $w;
    $n1 > $n or return;
    my $seq = _anchor(_resolute([], $tag), $derivs, $anchor);
    my($d2, $entries) = _block_seq_entries($derivs, $n1);
    return if ! @{$entries};
    @{$seq} = @{$entries};
    return ($d2, $seq);
}

sub _compact_sequence {
    my($derivs, $n) = @_;
    my $d1 = _match($derivs, qr/[-](?=[ \t\n])/omsx) or return;
    my($d2, $x2) = _block_indented($d1, $n, 'block-in') or return;
    my($d3, $entries) = _block_seq_entries($d2, $n);
    unshift @{$entries}, $x2;
    return ($d3, $entries);
}

sub _block_seq_entries {
    my($derivs, $n) = @_;
    my $lex = qr/[ ]{$n}-(?=[ \t\n])/msx;
    my @entries;
    while (my $d1 = _match($derivs, $lex)) {
        my($d2, $x) = _block_indented($d1, $n, 'block-in') or last;
        push @entries, $x;
        $derivs = $d2;
    }
    return ($derivs, \@entries);
}

sub _block_indented {
    my($derivs, $n, $c) = @_;
    RULE: {
        my($d1, $spaces) = _match($derivs, qr/([ ]+)/omsx) or last;
        my $m = length $spaces;
        my($d2, $x2) = _compact_sequence($d1, $n + 1 + $m);
        return ($d2, $x2) if $d2;
        my($d3, $x3) = _compact_mapping($d1, $n + 1 + $m);
        return ($d3, $x3) if $d3;
    }
    RULE: {
        my($d1, $x) = _block_node($derivs, $n, $c);
        return ($d1, $x) if $d1;
        my $d2 = _s_l_comments($derivs) or last;
        return ($d2, undef);
    }
    return;
}

sub _block_mapping {
    my($derivs, $n, $tag, $anchor) = @_;
    my($d1, $spaces) = _match($derivs, qr/([ ]*)/omsx) or return;
    my $n1 = length $spaces;
    $n1 > $n or return;
    my $map = _anchor(_resolute({}, $tag), $derivs, $anchor);
    my($d2, $entries) = _block_map_entries($derivs, $n1);
    return if ! @{$entries};
    if (0 <= index "$map", 'HASH(') {
    	%{$map} = @{$entries};
	}
	elsif (0 <= index "$map", 'ARRAY(') {
		@{$map} = @{$entries};
	}
    return ($d2, $map);
}

sub _compact_mapping {
    my($derivs, $n) = @_;
    my($d1, $k, $v) = _block_map_entry($derivs, $n) or return;
    my($d2, $entries) = _block_map_entries($d1, $n);
    return ($d2, {$k, $v, @{$entries}});
}

sub _block_map_entries {
    my($derivs, $n) = @_;
    my @entries;
    my $indent = q( ) x $n;
    while (my $d1 = _match($derivs, $indent)) {
        my($d2, $k, $v) = _block_map_entry($d1, $n) or last;
        push @entries, $k, $v;
        $derivs = $d2;
    }
    return ($derivs, \@entries);    
}

sub _block_map_entry {
    my($derivs, $n) = @_;
    RULE: {
        my $d1 = _match($derivs, '?') or last;
        my($d2, $k) = _block_indented($d1, $n, 'block-out') or last;
        $k = defined $k ? $k : q();
        my($d3, $v);
        $d2
        and $d3 = _match($d2, qr/^[ ]{$n}:/msx)
        and ($d3, $v) = _block_indented($d3, $n, 'block-out')
        and return ($d3, $k, $v);
        return ($d2, $k, undef);
    }
    RULE: {
        my($d1, $k) = _flow_node($derivs, 0, 'block-key');
        $k = defined $k ? $k : q();
        my $d2 = $d1 && _match($d1, qr/[ ]+/omsx) || $d1;
        my $d3 = _match($d2 || $derivs, ':') or last;
        my($d4, $v) = _block_node($d3, $n, 'block-out');
        return ($d4, $k, $v) if $d4;
        my $d5 = _s_l_comments($d3) or last;
        return ($d5, $k, undef);
    }
    return;
}

sub _flow_node {
    my($derivs, $n, $c) = @_;
    my $c1 = $c eq 'flow-in' || $c eq 'flow-key' ? 'flow-in' : 'flow-out';
    my $key = "ns-flow-node($n,$c1)";
    my($d4, $node4, $json4) = _memorize($derivs, $key, sub{
        my($d3, $node) = _alias_node($derivs);
        return [$d3, $node, q()] if $d3;
        my($d1, $tag, $anchor) = _properties($derivs, $n, $c1);
        my $d2 = $d1 ? _separate($d1, $n, $c1) : $derivs;
        my $json = q();
        not $d2
        or ($d3, $node, $json) = _plain($d2, $n, $c1, $tag, $anchor)
        or ($d3, $node, $json) = _flow_sequence($d2, $n, $c1, $tag, $anchor)
        or ($d3, $node, $json) = _flow_mapping($d2, $n, $c1, $tag, $anchor)
        or ($d3, $node, $json) = _single_quoted($d2, $n, $c1, $tag, $anchor)
        or ($d3, $node, $json) = _double_quoted($d2, $n, $c1, $tag, $anchor);
        return [$d3, $node, $json] if $d3;
        return [$d1, _anchor(_resolute(undef, $tag), $d1, $anchor), q()]
            if $d1;
        return;
    }) or return;
    if ($c eq 'block-key' || $c eq 'flow-key') {
        if (! $derivs->[2]{$derivs->[1]}{$key}[2]) {
            my $i = index ${$derivs->[0]}, "\n", $derivs->[1];
            $derivs->[2]{$derivs->[1]}{$key}[2] =
                $i >= 0 && $i < $d4->[1] ? 'n' : 'w';
        }
        return if $derivs->[2]{$derivs->[1]}{$key}[2] eq 'n';
    }
    return ($d4, $node4, $json4);
}

sub _alias_node {
    my($derivs) = @_;
    my($d1, $alias) = _match($derivs, $ALIAS_NODE) or return;
    my $anchor = q(&) . $alias;
    return ($d1, $d1->[2]{$anchor}) if exists $d1->[2]{$anchor};
    croak "AnchorNotFound: $anchor from alias.";
}

sub _plain {
    my($derivs, $n, $c, $tag, $anchor) = @_;
    $n >= 0 or Carp::confess("ns-plain(n,c): n >= 0, but $n.");
    my $lex = $c eq 'flow-in'
    ? qr{(
        $PLAIN_ONE_IN
        (?: [ \t]* \n (?:(?:[ ]{$n}[ \t]*|[ ]*)\n)*
            (?!(?:---|[.][.][.])) [ ]{$n}[ \t]*
            $PLAIN_WORD_IN(?:[ \t]+$PLAIN_WORD_IN)*)*
    )}msx
    : qr{(
        $PLAIN_ONE_OUT
        (?: [ \t]* \n (?:(?:[ ]{$n}[ \t]*|[ ]*)\n)*
            (?!(?:---|[.][.][.])) [ ]{$n}[ \t]*
            $PLAIN_WORD_OUT(?:[ \t]+$PLAIN_WORD_OUT)*)*
    )}msx;
    my($d1, $s) = _match($derivs, $lex) or return;
    $s =~ s{[ \t]* \n ((?:[ \t]*\n)*) [ \t]*}
           { ("\n" x ((my $x = $1) =~ tr/\n/\n/)) || q( ) }egmsx;
    return ($d1, _anchor(_resolute_plain($s, $tag), $d1, $anchor), q());
}

sub _flow_sequence {
    my($derivs, $n, $c, $tag, $anchor) = @_;
    my $c1 = 'flow-in';
    my $d1 = _match($derivs, '[') or return;
    $derivs = _separate($d1, $n, $c) || $d1;
    my $seq = _anchor(_resolute([], $tag), $derivs, $anchor);
    my @entries;
    while (my($d2, $x) = _flow_seq_entry($derivs, $n, $c1)) {
        push @entries, $x;
        $derivs = _separate($d2, $n, $c) || $d2;
        $d2 = _match($derivs, ',') or last;
        $derivs = _separate($d2, $n, $c) || $d2;
    }
    $derivs = _match($derivs, ']') or return;
    @{$seq} = @entries;
    return ($derivs, $seq, '!!seq');
}

sub _flow_seq_entry {
    my($derivs, $n, $c) = @_;
    my($d1, $k1, $v1) = _flow_map_explicit_entry($derivs, $n, $c);
    return ($d1, {$k1 => $v1}) if $d1;
    my($d2, $k2, $json) = _flow_node($derivs, 0, 'flow-key');
    my($d3, $v3) = _flow_map_value($d2 || $derivs, $n, $c, $json);
    if ($d3) {
        $k2 = defined $k2 ? $k2 : q();
        return ($d3, {$k2 => $v3});
    }
    return ($d2, $k2) if $json;
    return _flow_node($derivs, $n, $c);
}

sub _flow_mapping {
    my($derivs, $n, $c, $tag, $anchor) = @_;
    my $c1 = 'flow-in';
    my $d1 = _match($derivs, '{') or return;
    $derivs = _separate($d1, $n, $c) || $d1;
    my $map = _anchor(_resolute({}, $tag), $derivs, $anchor);
    my @entries;
    while (my($d2, $k, $v) = _flow_map_entry($derivs, $n, $c1)) {
        push @entries, $k, $v;
        $derivs = _separate($d2, $n, $c1) || $d2;
        $d2 = _match($derivs, ',') or last;
        $derivs = _separate($d2, $n, $c1) || $d2;
    }
    $derivs = _match($derivs, '}') or return;
    if (0 <= index "$map", 'HASH(') {
    	%{$map} = @entries;
	}
	elsif (0 <= index "$map", 'ARRAY(') {
		@{$map} = @entries;
	}
    return ($derivs, $map, '!!map');
}

sub _flow_map_entry {
    my($derivs, $n, $c) = @_;
    my($d1, $k, $v) = _flow_map_explicit_entry($derivs, $n, $c);
    return ($d1, $k, $v) if $d1;
    return _flow_map_implicit_entry($derivs, $n, $c);
}

sub _flow_map_explicit_entry {
    my($derivs, $n, $c) = @_;
    my $d1 = _match($derivs, '?') or return;
    my $d2 = _separate($d1, $n, $c) or return;
    my($d3, $k, $v) = _flow_map_implicit_entry($d2, $n, $c);
    $k = defined $k ? $k : q();
    return ($d3, $k, $v) if $d3;
    return ($d2, q(), undef);
}

sub _flow_map_implicit_entry {
    my($derivs, $n, $c) = @_;
    my($d1, $k, $json) = _flow_node($derivs, $n, $c);
    $k = defined $k ? $k : q();
    my($d2, $v) = _flow_map_value($d1 || $derivs, $n, $c, $json);
    return ($d2, $k, $v) if $d2;
    return ($d1, $k, undef) if $d1;
    return;
}

sub _flow_map_value {
    my($derivs, $n, $c, $adjacent) = @_;
    my $colon = $adjacent ? q(:)
        : $c ne 'flow-in' && $c ne 'flow-key' ? qr/[:](?=[ \t\r\n])/omsx
        : qr/[:](?=[ \t\r\n,\[\]\{\}])/omsx;
    my $d1 = _separate($derivs, $n, $c) || $derivs;
    my $d2 = _match($d1, $colon) or return;
    RULE: {
        my $d3 = _separate($d2, $n, $c) || ($adjacent ? $d2 : last);
        my($d4, $v) = _flow_node($d3, $n, $c) or last;
        return ($d4, $v);
    }
    return ($d2, undef);
}

sub _single_quoted {
    my($derivs, $n, $c, $tag, $anchor) = @_;
    my $d1 = _match($derivs, q(')) or return;
    my($d2, $s) = _match($d1, $SINGLE_QUOTED) or return;
    my $d3 = _match($d2, q(')) or return;
    $s =~ s{(?:('')|[ \t]*\n((?:[ \t]*\n)*)[  \t]*)}
           { $1 ? q(') : ("\n" x ((my $x = $2) =~ tr/\n/\n/)) || q( ) }egomsx;
    return ($d3, _anchor(_resolute($s, $tag), $d3, $anchor), '!!str');
}

sub _double_quoted {
    my($derivs, $n, $c, $tag, $anchor) = @_;
    my $d1 = _match($derivs, q(")) or return;
    my($d2, $s) = _match($d1, $DOUBLE_QUOTED) or return;
    my $d3 = _match($d2, q(")) or return;
    $s =~ s{
        ([ \t]*)
        (?: \\
            (?: ([0abt\tnvfre "/\\N_LP])
            |   x([[:xdigit:]]{2}) | u([[:xdigit:]]{4}) | U([[:xdigit:]]{8})
            |   \n((?:[ \t]*\n)*)[ \t]*
            |   (.) )
        |   \n ((?:[ \t]*\n)*)[ \t]* )
    }{
          defined $2 ? $1 . $UNESCAPE{$2}
        : defined $3 ? $1 . (chr hex $3)
        : defined $4 ? $1 . (chr hex $4)
        : defined $5 ? $1 . (chr hex $5)
        : defined $6 ? $1 . ("\n" x ((my $x = $6) =~ tr/\n/\n/))
        : defined $7 ? croak 'SyntaxError: invalid escape characters'
        : defined $8 ? ("\n" x ((my $y = $8) =~ tr/\n/\n/)) || q( )
        : $1
    }egomsx;
    return ($d3, _anchor(_resolute($s, $tag), $d3, $anchor), '!!str');
}

sub _separate {
    my($derivs, $n, $c) = @_;
    my($derivs3, $v3, $line3) = _memorize($derivs, "s-separate($n)", sub{
        my($derivs1, $slcomment, $line) = _s_l_comments($derivs);
        if ($derivs1) {
            my $derivs2 = _flow_line_prefix($derivs1, $n) or return;
            return [$derivs2, ['s-separate'], $line] if $derivs2;
        }
        my $derivs2 = _separate_in_line($derivs) or return;
        return [$derivs2, ['s-separate'], 'w'];
    }) or return;
    if ($c eq 'block-key' || $c eq 'flow-key') {
        return if $line3 eq 'n';
    }
    return wantarray ? ($derivs3, $v3) : $derivs3;
}

sub _s_l_comments {
    my($derivs) = @_;
    return _memorize($derivs, 's-l-comments', sub{
        my($derivs1, $s) = _match($derivs, $S_L_COMMENTS) or return;
        my $line = 0 <= (index $s, "\n") ? 'n' : 'w';
        return [$derivs1, ['s-l-comments'], $line];
    });
}

sub _flow_line_prefix {
    my($d0, $n) = @_;
    return _memorize($d0, 's-flow-line-prefix', sub{
        my $d1 = _match($d0, qr/[ ]{$n}[ \t]*/msx) or return;
        return [$d1, ['s-flow-line-prefix']];
    });
}

sub _separate_in_line {
    my($derivs) = @_;
    return _memorize($derivs, 's-separate-in-line', sub{
        my $derivs1 = _match($derivs, qr/[ \t]+|^/omsx) or return;
        return [$derivs1, ['s-separate-in-line']];
    });
}

sub _match {
    my($derivs, $phrase) = @_;
    ref $derivs eq 'ARRAY' or Carp::confess('ArgumentError: _match');
    my($r, $p, @v) = @{$derivs};
    if (! ref $phrase && defined $phrase) {
        my $n = length $phrase;
        return if $phrase ne substr ${$r}, $p, $n;
        my $derived = [$r, $p + $n, @v];
        return wantarray ? ($derived, $phrase) : $derived;
    }
    if (ref $phrase eq 'Regexp') {
        pos(${$r}) = $p;
        if (${$r} =~ m/\G$phrase/gcmsx) {
            my @c = map {
                (defined $-[$_] && defined $+[$_])
                ? (substr ${$r}, $-[$_], $+[$_] - $-[$_]) : undef;
            } 1 .. $#-;
            my $derived = [$r, pos ${$r}, @v];
            return wantarray ? ($derived, @c) : $derived;
        }
        return;
    }
    Carp::confess('ArgumentError: _match');
}

sub _end_of_file { return $_[0][1] >= length ${$_[0][0]} }

sub _memorize {
    my($derivs, $key, $yield) = @_;
    if (! exists $derivs->[2]{$derivs->[1]}{$key}) {
        $derivs->[2]{$derivs->[1]}{$key} = $yield->() || undef;
    }
    my $parsed = $derivs->[2]{$derivs->[1]}{$key} or return;
    return wantarray ? @{$parsed} : $parsed->[0];
}

sub _inspect {
    my($derivs) = @_;
    my($r, $p) = @{$derivs};
    my $left = substr ${$r}, $p < 24 ? 0 : $p - 24, $p < 24 ? $p : 24;
    my $right = substr ${$r}, $p, 24;
    my %c = (q( ) => q( ), q(") => q(\\"), "\t" => "\\t", "\n" => "\\n");
    for ($left, $right) {
        s{([\P{Graph}"])}{ $c{$1} || (sprintf "\\x{%02x}", ord $1) }egmsx;
    }
    return qq("$left" . "$right");
}

1;

__END__

=pod

=head1 NAME

YAML::Loaf - YAML Loader almost Full-set on YAML 1.2 Specification.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use YAML::Loaf;

    my $obj = YAML::Loaf::Load(<<'EOS');
    ---
    - - a
      - b
    - c : d
      e : f
    EOS

=head1 DESCRIPTION

YAML::Loaf is one of the pure perl implementations of loader
for YAML 1.2 data serialization language without recognitions
on directives. This processor can resolute YAML Core global tags
and several part of proposed Perl tag schema.

=head1 METHODS

=over

=item C<< Load($string) >>

Decode a YAML 1.2 stream of the given string.
In the scalar context, returns only first document.
In the array context, returns all documents in the stream.

=back

=head1 SEE ALSO

L<YAML>, L<YAML::XS>, L<YAML::Syck>, L<YAML::Old>, L<YAML::Tiny>

L<http://www.yaml.org/spec/1.2/spec.html>
L<http://pdos.csail.mit.edu/~baford/packrat/icfp02/>

=head1 AUTHOR

MIZUTANI Tociyuki, C<< <tociyuki at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 MIZUTANI Tociyuki.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

