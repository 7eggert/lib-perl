package BE::Dir;
use warnings;
use strict;
use Data::Dumper;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 0.01;

	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		new
		dirname
		get_direntries
		get_direntries_raw
	);
	%EXPORT_TAGS = qw(
	);;     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = (); #qw(&func3);
}
our @EXPORT_OK;

sub dirname($) {
	my $f = $_[0];
	return $1 if $f =~ m,^(.*/),;
	return '.';
}

my %dircache;

sub get_direntries_raw($) {
	my $d = $_[0];
	opendir(my $dh, $d);
	my $direntries;
	if (defined $dh) {
		$direntries = [ (readdir($dh)) ];
		closedir($dh);
	} else {
		print STDERR "Can't open $d: $!\n";
		$direntries = [];
	}
	$dircache{$d} = $direntries;
	return $direntries;
	
}

sub get_direntries($) {
	my $d = $_[0];
	my $cached = $dircache{$d};
	return $cached if $cached;
	return get_direntries_raw($d);
}

1;
