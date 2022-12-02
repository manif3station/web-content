package Web::Content;

use Moo;
use JSON::XS ();
use YAML::XS ();
use Template;
use File::Path 'mkpath';

has dir => ( is => 'ro', lazy => 1, builder => 1 );

sub _build_dir { $ENV{WEB_CONTENT_DIR} // "/data/content" }

has json => ( is => 'ro', lazy => 1, builder => 1 );

sub _build_json { JSON::XS->new->canonical->pretty->allow_nonref->utf8 }

has cache => ( is => 'ro', default => sub { {} } );

has memory_lifetime => ( is => 'ro', lazy => 1, builder => 1 );

sub _build_memory_lifetime { $ENV{WEB_CONTENT_CACHE_LIFETIME} // 60 * 10 }

sub _content {
    my ( $self, $file, $encoding ) = @_;
    $encoding //= 'utf8';
    open my $fh, '<' . $encoding, $file;
    local $/;
    <$fh>;
}

sub get {
    my ( $self, @paths ) = @_;

    if ( @paths <= 1 ) {
        return $self->get_data_from_path(@paths);
    }
    elsif (wantarray) {
        return map { $self->get_data_from_path($_) } @paths;
    }
    else {
        return [ map { $self->get_data_from_path($_) } @paths ];
    }
}

sub memory {
    my ( $self, $path ) = @_;

    my $cache = $self->cache->{$path}
        or return {};

    my $memory_lifetime = $self->memory_lifetime;

    my $life_spent = time - $cache->{created};

    return {} if $life_spent >= $memory_lifetime;

    return $cache;
}

sub remember {
    $_[0]->cache->{ $_[1] } = {
        created => time,
        data    => $_[2],
    };
}

sub get_data_from_path {
    my ( $self, $path ) = @_;

    my $val = $self->memory($path);

    return $val->{data} if $val->{found};

    $path = [ split /\./, $path // '.' ];

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

    return $self->remember($path => $data)->{data};
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
            chomp( my $txt = $self->_content("$location.txt") );
            return $txt;
        }
        elsif ( -f "$location.html" ) {
            chomp( my $html = $self->_content("$location.html") );
            return $html;
        }
        elsif ( -f $location ) {
            return $self->_content( $location, 'raw' );
        }
        else {
            return undef;
        }
    }

    if ( -d $location ) {
        opendir( my $dh, $location );

        my @data;

        while ( my $item = readdir($dh) ) {
            next if $item =~ m/^\.{1,2}$/;

            if ( -d "$location/$item" ) {
                if ( $item !~ /\./ ) {
                    push @data, $item;
                }
            }
            elsif ( $item =~ m/^([^\.]+)\.(json|yaml|yml|txt)$/ ) {
                push @data, $1;
            }
        }

        return [ sort @data ];
    }

    return undef;
}

1;
