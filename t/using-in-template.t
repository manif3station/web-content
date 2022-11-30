use Test::More;
use Template;
use Web::Content;

my $content = Web::Content->new( dir => '/tmp' );

system qq(mkdir /tmp/pages; echo -n Foo Bar > /tmp/pages/title.txt);

my $template = Template->new;

$template->process(
    \"Test: [% content('pages.title') %]" => {
        content => sub { $content->get(@_) },
    } => \my $got
);

is $got, 'Test: Foo Bar';

done_testing;
