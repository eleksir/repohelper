use strict;
use warnings "all";

# my plugins
use lib qw(./lib ./vendor_perl ./vendor_perl/lib/perl5);
use conf;
use upload;

my $CONF = loadConf();

my $app = sub {
	my $env = shift;

	if ($env->{REQUEST_METHOD} ne 'PUT') {
		my $msg = "Method Not Allowed.";

		return [
			'405',
			[ 'Content-Type' => 'text/plain', 'Content-Length' => length($msg) ],
			[ $msg ],
		];
	}

	my $msg = "Your Opinion is very important for us, please stand by.\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} =~ /\/upload\/(.+)/) {
		my $upload = $1;
		($status, $content, $msg) = ('400', $content, "Bad Request?\n");

		if (($upload !~ /\.\./) and ($upload =~ /^[A-Z|a-z|0-9|_|\-|\+|\/|\.]+\.rpm$/)) {
			if (defined($env->{CONTENT_LENGTH}) && ($env->{CONTENT_LENGTH} > 0)) {
				($status, $content, $msg) = upload($env->{'psgi.input'}, $env->{CONTENT_LENGTH}, $upload);
			} else {
				$msg = "Bad Request. No Content-Length set.\n";
			}
		} else {
			$msg = "Something wrong with upload path.\n";
		}
	}

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length($msg) ],
		[ $msg ],
	];
};

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
