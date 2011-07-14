package Anyblob::Server;
use 5.012;
use Moose;
use Plack::Request;
use Plack::Response;
use Digest::SHA1;
use IO::All;
use JSON qw(to_json);
use Anyblob::Helpers;

my $BLOBREF_RE = qr{sha1-[0-9a-f]{40}};

has datastore => (
    is => "ro",
    isa => "Str",
    required => 1,
    trigger => sub {
        my ($self, $datastore) = @_;
        unless (-d $datastore) {
            io($datastore)->mkpath;
            io->catdir($datastore, "refs")->mkpath;
        }
    }
);

## Actions

sub check {
    my ($self, $ref) = @_;
    my $blob_file = io->catfile($self->datastore, "refs", $ref);

    return Plack::Response->new( $blob_file->exists ? 200 : 404 );
}

sub store {
    my ($self, $ref, $blob) = @_;

    my $response = Plack::Response->new(200);

    if ($ref ne blobref($blob)) {
        $response->status(400);
        return $response;
    }

    my $ref_io = io->catfile($self->datastore, "refs", $ref);

    unless ($ref_io->exists) {
        $ref_io->assert->binary->print($blob);
    }

    return $response;
}

sub retrieve {
    my ($self, $ref) = @_;
    my $response = Plack::Response->new(200);
    my $blob_file = io->catfile($self->datastore, "refs", $ref);

    unless($blob_file->exists) {
        $response->status(404);
        return $response;
    }

    $response->body($blob_file);
    return $response;
}

sub list {
    my ($self) = @_;
    my $response = Plack::Response->new(200);
    my @files = sort { $a cmp $b } io->catdir($self->datastore, "refs")->readdir;
    $response->body(to_json(\@files));
    return $response;
}

## The app for the server instace

sub app {
    my ($self) = @_;

    return sub {
        my ($env) = @_;
        my $request = Plack::Request->new($env);
        my $response;

        given([$request->method, $request->path]) {
            when(['HEAD', qr{^/blobs/(${BLOBREF_RE})$}]) {
                $response = $self->check($1);
            }
            when(['GET', qr{^/blobs/(${BLOBREF_RE})$}]) {
                $response = $self->retrieve($1);
            }
            when(['PUT', qr{^/blobs/(${BLOBREF_RE})$}]) {
                $response = $self->store($1, $request->raw_body);
            }
            when(['GET', qr{^/blobs.json$}]) {
                $response = $self->list;
            }
        }

        return $response->finalize;
    }
}

1;
