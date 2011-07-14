package Anyblob::Client;
use 5.012;
use Moose;

has blob_size => (
    is => "ro",
    isa => "Int",
    default => 1024 * 1024
);

has server => (
    is => "ro",
    isa => "Str",
    required => 1
);

has ua => (
    is => "ro",
    isa => "LWP::UserAgent",
    lazy_build => 1,
);

sub _build_ua {
    return LWP::UserAgent->new;
}

use Anyblob::Helpers;
use LWP::UserAgent;
use HTTP::Request;

sub check {
    my ($self, $ref) = @_;
    my $response = $self->ua->request(HTTP::Request->new(HEAD => $self->server . "/blobs/$ref"));
    return $response->is_success;

}

sub store {
    my ($self, $blob) = @_;
    my $ref = blobref($blob);
    return 1 if ($self->check($ref));
    my $response = $self->ua->request(HTTP::Request->new(PUT => $self->server . "/blobs/$ref", [], $blob));
    return ($response->is_success);
}

sub retrieve {
    my ($self, $ref) = @_;
    my $response = $self->ua->request(HTTP::Request->new(GET => $self->server . "/blobs/$ref"));
    return undef unless $response->is_success;
    return $response->content;
}

sub list {
    my ($self) = @_;
}

sub upload {
    my ($self, $file) = @_;

    my @refs;

    my $blob;
    open my $fh, "<:bytes", $file;

    while (read($fh, $blob, $self->blob_size)) {
        my $ref = blobref($blob);

        unless($self->store($blob)) {
            warn "ERROR storing $ref\n";
            return undef;
        }

        push @refs, $ref;
    }

    close($fh);

    return wantarray ? @refs : \@refs;
}


sub download {
    my ($self, $file, $refs) = @_;

    open my $fh, ">:bytes", $file;

    for my $ref (@$refs) {
        my $request = HTTP::Request->new(GET => $self->server . "/blobs/$ref");
        my $response = $self->ua->request($request);

        unless ($response->is_success) {
            close($fh);
            unlink $file;
            warn "Failed to retrieve blob $ref\n";
            return 0;
        }

        print $fh $response->content;
    }
    close($fh);

    return 1;
}


1;
