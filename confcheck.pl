#!/usr/bin/perl

use strict;
use warnings "all";

use JSON::PP;

my $conf = "data/config.json";
my $jstr = "";
my $len = (stat ($conf))[7];
open (C, $conf) || die "No such file $conf\n";
my $rlen = read (C, $jstr, $len) || die "Unable to read $conf\n";
close C;
die "We read $rlen bytes, but stat() says it should be $len bytes\n." unless ($rlen == $len);
my $c = JSON::PP->new->decode($jstr);
my $j = JSON::PP->new->pretty->canonical->indent_length(4);
print $j->encode($c);

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
