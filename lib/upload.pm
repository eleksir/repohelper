package upload;

our $VERSION = "1.0";
use vars qw/$VERSION @EXPORT @ISA/;
require Exporter;
@EXPORT = qw (upload);
@ISA = "Exporter";

use strict;
use warnings "all";
use File::Basename;
use Fcntl;
use conf;

my $c = loadConf();

sub upload {
	my $input = shift;        # file descriptor with data being uploaded
	my $len = shift;          # expected data length (from client)
	my $name = shift;         # upload "dir" and filename
	my ($status, $content, $msg) = ('400', 'text/plain', "Bad Request?\n");
	my $d;
	($name, $d) = fileparse ('/' . $name);
	$d = substr ($d, 1);
	my $match;

	foreach (keys (%{$c->{dir}})) {
		warn "comparing $d and $_\n";
		if ($d eq $_) {
			$match = 1;
			last;
		}
	}

	return ($status, $content, "Incorrect destination dir.\n") unless ($match); # incorrect destination in url

	$name = sprintf ("%s/%s", $c->{dir}->{$d}->{path}, $name);

	if ($len > 0) {
		if (sysopen (F, $name, O_CREAT|O_TRUNC|O_WRONLY)) {
			my $buf;
			my $readlen = 0;
			my $totalread = 0;
			my $buflen = 524288; # 512 kbytes, looks sane enough

			if ($len < $buflen) {
				$buflen = $len;
			}

			do {
				$readlen = $input->read ($buf, $buflen);

				my $written = syswrite F, $buf, $readlen;

				unless (defined ($written)) { # out of space?
					close F;
					unlink $name;
					warn "[FATA] Unable to write to $name: $!";
					return ('500', $content, "An error has occured during upload: $!\n");
				}

				if ($readlen != $written) {
					close F;
					unlink $name;
					warn "[FATA] Must write $readlen bytes, but actualy wrote $written bytes to $name";
					return ('500', $content, "An error has occured during upload: $!\n");
				}

				$totalread += $readlen;
			} while ($readlen == $buflen);

			close F;

			if ($totalread != $len) {
				($status, $content, $msg) = ('400', $content, "Content-Length does not match amount of recieved bytes.\n");
			} else {
				if (defined ($c->{dir}->{$d}->{hook})) {
					my (undef, $dir) = fileparse ($name);

					if (chdir $dir) {
						system ($c->{dir}->{$d}->{hook}, '.');

						if ($? == 0) {
							($status, $content, $msg) = ('201', $content, "Uploaded and rehashed.\n");
						} else {
							warn "[ERROR] Uploaded but rehash hook failed.";
							($status, $content, $msg) = ('201', $content, "Uploaded but rehash hook failed.\n");
						}
					} else {
						warn "[ERROR] Uploaded but unable to chdir to $dir, rehash failed.";
						($status, $content, $msg) = ('201', $content, "Uploaded but unable to chdir to $dir, rehash failed.\n");
					}
				} else {
					($status, $content, $msg) = ('201', $content, "Uploaded.\n");
				}
			}
		} else {
			warn "[FATA] Unable to open file $name: $!";
			($status, $content, $msg) = ('500', $content, "Unable to write: $!\n");
		}
	} else {
		$msg = "Incorrect Content-Length\n";
	}

	return ($status, $content, $msg);
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4 :
