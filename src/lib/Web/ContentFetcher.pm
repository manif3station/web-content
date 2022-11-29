package Web::ContentFetcher;

use Dancer2 appname => 'Web';
use Web::Content;

my $content = Web::Content->new;

hook before_template_render => sub {
    my ($stash) = @_;
    $stash->{content} = sub {$content->get(@_)};
};

1;
