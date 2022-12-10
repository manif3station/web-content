use strict;
use Test::More;
use Web::Content;

subtest 'read and read again from cache' => sub {
    my $content = Web::Content->new(dir => "t/samples");
    my $path = 'foo1.bar.zxy.data.a.b.c';
    is_deeply $content->memory($path), {};
    is $content->get( $path ), 'good';
    is_deeply $content->memory($path), {found => 1, data => 'good'};
};

done_testing;
