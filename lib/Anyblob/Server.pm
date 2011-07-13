package Anyblob::Server;
use 5.012;
use Mouse;
use Plack::Request;
use Plack::Response;
use Digest::SHA1;
use IO::All;

my $BLOBREF_RE = qr{sha1-[0-9a-f]{40}};

has datastore => (
    is => "rw",
    isa => "Str",
    required => 1
);

## Helpers

sub blobref {
    return "sha1-" . Digest::SHA1::sha1_hex($_[0])
}

## Actions

sub check {
}

sub store {
    my ($self, $ref, $blob) = @_;

    my $response = Plack::Response->new(200);

    if ($ref ne blobref($blob)) {
        $response->status(400);
        return $response;
    }

    io->catfile($self->datastore, "refs", $ref)->assert->binary->print($blob);

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

## The app for the server instace

sub app {
    my ($self) = @_;

    return sub {
        my ($env) = @_;
        my $request = Plack::Request->new($env);
        my $response;

        given([$request->method, $request->path]) {
            when(['HEAD', qr{^/blobs/(${BLOBREF_RE})$}]) {
                # Check
            }
            when(['GET', qr{^/blobs/(${BLOBREF_RE})$}]) {
                $response = $self->retrieve($1);
            }
            when(['PUT', qr{^/blobs/(${BLOBREF_RE})$}]) {
                $response = $self->store($1, $request->raw_body);
            }
        }

        return $response->finalize;
    }
}

1;
