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
    my $server;

    before each => sub {
        $server = Anyblob::Server->new(datastore => "/tmp/test-anyblob-server-$$-" . time);
    };

    after each => sub {
        io($server->datastore)->rmtree;
    };

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

                ok -f $server->datastore . "/refs/$ref";
            }
        );
    };

    it "can retrieve an existing blob" => sub {
        test_psgi(
            app => $server->app,
            client => sub {
                my $cb = shift;
                my $blob = "OHAI\n$$\n";
                my $ref  = "sha1-" . sha1_hex($blob);
                # store the blob and assume success.
                $cb->(HTTP::Request->new(PUT => "http://localhost/blobs/$ref", [], $blob));

                my $response = $cb->(HTTP::Request->new(GET => "http://localhost/blobs/$ref"));
                is $response->code, 200;
                is $response->content, $blob;
            }
        );
    };
};

runtests unless caller;
