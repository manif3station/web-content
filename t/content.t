use strict;
use warnings;

use File::Path 'mkpath';
use Test::More;
use Web::Content;

my $dir = 't/samples/foo/bar/zxy';

mkpath $dir;

my $content = Web::Content->new( dir => 't/samples' );

subtest "get from json file" => sub {
    open my $fh, '>', "$dir/data1.json";
    print $fh '{"a": {"b": {"c": "here"}}}';
    close $fh;
    my $path = 'foo.bar.zxy.data1.a.b.c';
    is $content->get($path), 'here';
};

subtest "get from yaml file" => sub {
    open my $fh, '>', "$dir/data2.yml";
    print $fh <<'HEREDOC';
a:
    b:
        c: there
HEREDOC
    close $fh;
    my $path = 'foo.bar.zxy.data2.a.b.c';
    is $content->get($path), 'there';
};

subtest "get from text file" => sub {
    open my $fh, '>', "$dir/data3.txt";
    print $fh 'here and there';
    close $fh;
    my $path = 'foo.bar.zxy.data3.a.b.c';
    is $content->get($path), 'here and there';
};

subtest 'get from json again' => sub {
    open my $fh, '>', "t/samples/foo1.json";
    print $fh '{"bar":{"zxy":{"data":{"a":{"b":{"c":"good"}}}}}}';
    close $fh;
    my $path = 'foo1.bar.zxy.data.a.b.c';
    is $content->get($path), 'good';
};

subtest 'get from json again' => sub {
    open my $fh, '>', "t/samples/foo2.yml";
    print $fh <<'HEREDOC';
bar:
    zxy:
        data:
            a:
                b:
                    c: bad
HEREDOC
    close $fh;
    my $path = 'foo2.bar.zxy.data.a.b.c';
    is $content->get($path), 'bad';
};

subtest 'array list of a directory' => sub {
    mkpath 't/samples/foo/d1';
    mkpath 't/samples/foo/d2';
    mkpath 't/samples/foo/d3';
    is_deeply $content->get('foo'), [qw(bar d1 d2 d3)]
};

subtest 'array list of a directory' => sub {
    is_deeply $content->get, [qw(foo foo1 foo2)]
};

subtest "not found" => sub {
    is $content->get('foo.bar.somewhere'), undef;
};

done_testing;
