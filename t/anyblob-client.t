#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Test::Spec;
use HTTP::Request;
use HTTP::Response;
use Anyblob::Client;
use Digest::SHA1 qw(sha1_hex);
use IO::All;
use JSON qw(from_json);
use LWP::UserAgent;

my $client;

describe "Anyblob::Client" => sub {
    before each => sub {
        $client = Anyblob::Client->new( server => "http://example.com" );
    };

    it "can do store, retrieve, check and list, for blobs", sub {
        ok $client->can("store");
        ok $client->can("retrieve");
        ok $client->can("check");
        ok $client->can("list");
    };

    it "can do upload and download for files", sub {
        ok $client->can("upload");
        ok $client->can("download");
    };

    describe "->store" => sub {
        it "should avoid uploading the blob which is already on the server", sub {
            $client->expects("check")->returns(1);
            $client->store("BLOB");
        };

        it "should request the server to store", sub {
            $client->expects("check")->returns(0);
            my $ua = LWP::UserAgent->new;
            LWP::UserAgent->expects("new")->returns($ua);
            $ua->expects("request")->returns(
                sub {
                    my ($ua, $request) = @_;
                    is $request->method, "PUT";
                    is $request->uri, $client->server . "/blobs/sha1-" . sha1_hex("BLOB");
                    is $request->content, "BLOB";

                    return HTTP::Response->new(200);
                }
            );

            $client->store("BLOB");
        };
    };

    describe "->retrieve" => sub {
        it "needs a filename, and a list of refs";
    };

    describe "#check" => sub {
    };

    describe "#list" => sub {
    };
};

runtests unless caller;


