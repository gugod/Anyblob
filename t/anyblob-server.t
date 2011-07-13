#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Plack::Test;
use Test::More;

use HTTP::Request;
use Anyblob::Server;
use Digest::SHA1 qw(sha1_hex);
use IO::All;

my $server = Anyblob::Server->new(datastore => "/tmp/test-anyblob-server-$$");

test_psgi
    app => $server->app,
    client => sub {
        my $cb = shift;

        subtest "Storing the blob" => sub {
            my $blob = "OHAI\n";
            my $ref  = "sha1-" . sha1_hex($blob);

            my $request = HTTP::Request->new(PUT => "http://localhost/blobs/$ref", [], $blob);
            my $response = $cb->($request);

            ok $response->is_success;
            is $response->code, 200;

            ok -f "/tmp/test-anyblob-server-$$/refs/$ref";
            done_testing;
        };
    };

io("/tmp/test-anyblob-server-$$")->rmtree;

done_testing;
