#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Plack::Test;
use Test::Spec;

use HTTP::Request;
use Anyblob::Server;
use Digest::SHA1 qw(sha1_hex);
use IO::All;

describe "Anyblob::Server" => sub {
    my $store = "/tmp/test-anyblob-server-$$";
    my $server = Anyblob::Server->new(datastore => $store);

    it "Can store a blob" => sub {
        test_psgi(
            app => $server->app,
            client => sub {
                my $cb = shift;

                my $blob = "OHAI\n";
                my $ref  = "sha1-" . sha1_hex($blob);

                my $request = HTTP::Request->new(PUT => "http://localhost/blobs/$ref", [], $blob);
                my $response = $cb->($request);

                ok $response->is_success;
                is $response->code, 200;

                ok -f "$store/refs/$ref";
            }
        );

        io($store)->rmtree;
    };
};

runtests unless caller;;
