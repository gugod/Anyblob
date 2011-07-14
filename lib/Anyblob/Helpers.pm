package Anyblob::Helpers;
use strict;
use Exporter::Lite;
use Digest::SHA1;

our @EXPORT = qw(blobref);

sub blobref {
    return "sha1-" . Digest::SHA1::sha1_hex($_[0])
}

1;
