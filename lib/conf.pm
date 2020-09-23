package conf;

use 5.018;
use strict;
use warnings "all";
use utf8;
use open qw(:std :utf8);

use vars qw/$VERSION/;
use JSON::XS;

use Exporter qw(import);
our @EXPORT = qw(loadConf);

$VERSION = "1.0";

sub loadConf () {
	my $c = "data/config.json";
	open (C, "<", $c) or die "[FATA] No conf at $c: $!\n";
	my $len = (stat ($c)) [7];
	my $json;
	my $readlen = read (C, $json, $len);

	unless ($readlen) {
		close C;
		die "[FATA] Unable to read $c: $!\n";
	}

	if ($readlen != $len) {
		close C;
		die "[FATA] File $c is $len bytes on disk, but we read only $readlen bytes\n";
	}

	close C;
	my $j = JSON::XS->new->utf8->relaxed;
	return $j->decode ($json);
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
