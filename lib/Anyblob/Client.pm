package Anyblob::Client;
use 5.012;
use Moose;

has server => (
    is => "ro",
    isa => "Str",
    required => 1
);

use Anyblob::Helpers;
use LWP::UserAgent;
use HTTP::Request;

sub check {
    my ($self, $ref) = @_;
}

sub store {
    my ($self, $blob) = @_;
    my $ref = blobref($blob);
    return 1 if ($self->check($ref));
    my $ua = LWP::UserAgent->new;
    my $response = $ua->request(HTTP::Request->new(PUT => $self->server . "/blobs/$ref", [], $blob));
    return ($response->is_success);
}

sub retrieve {
    my ($self, $ref) = @_;
}

sub list {
    my ($self) = @_;
}

sub upload {
    my ($self, $file) = @_;
}

sub download {
    my ($self, $filename, $refs) = @_;
}


1;
