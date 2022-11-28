package Web::Content;

use Moo;
use JSON::XS ();
use YAML::XS ();
use Template;

if (!$ENV{WEB_CONTENT_BASE_DIR}) {
    warn ">> You can set where the content base dir is 'WEB_CONTENT_BASE_DIR'";
}

has dir => ( is => 'ro', lazy => 1, builder => 1 );

sub _build_dir { $ENV{WEB_CONTENT_BASE_DIR} // "/app/src/content" }

has json => ( is => 'ro', lazy => 1, builder => 1 );

sub _build_json { JSON::XS->new->canonical->pretty->allow_nonref->utf8 }

sub _content {
    my ( $self, $file, $encoding ) = @_;
    $encoding //= 'utf8';
    open my $fh, '<' . $encoding, $file;
    local $/;
    <$fh>;
}

sub get {
    my ( $self, $path ) = @_;

    $path = [ split /\./, $path // '.'];

    my $data = $self->get_data_from_file( $path, $self->dir );

    return $data if !@$path || !$data || !ref $data;

    my $remain_path = join '.', @$path;

    Template->new->process(
        \"[%store(data.$remain_path)%]" => {
            data  => $data,
            store => sub { ($data) = @_; undef },
        },
        \my $undef,
    );

    return $data;
}

sub get_data_from_file {
    my ( $self, $path, $location ) = @_;

    while ( my $item = shift @$path ) {
        $location .= "/$item";

        if ( -d $location ) {
            next;
        }
        elsif ( -f "$location.json" ) {
            return $self->json->decode( $self->_content("$location.json") );
        }
        elsif ( -f "$location.yml" ) {
            return YAML::XS::Load( $self->_content("$location.yml") );
        }
        elsif ( -f "$location.yaml" ) {
            return YAML::XS::Load( $self->_content("$location.yaml") );
        }
        elsif ( -f "$location.txt" ) {
            return $self->_content("$location.txt");
        }
        elsif ( -f $location ) {
            return $self->_content( $location, 'raw' );
        }
        else {
            return undef;
        }
    }

    if (-d $location) {
        opendir(my $dh, $location);

        my @data;

        while (my $item = readdir($dh)) {
            next if $item =~ m/^\.{1,2}$/;

            if (-d "$location/$item") {
                if ($item !~/\./) {
                    push @data, $item;
                }
            }
            elsif ($item =~ m/^([^\.]+)\.(json|yaml|yml|txt)$/) {
                push @data, $1;
            }
        }

        return [sort @data];
    }

    return undef;
}

1;
