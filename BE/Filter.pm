package BE::Filter;
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
		list_filter_re
		list_filter_re_arr
	);
	%EXPORT_TAGS = qw(
	);;     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = (); #qw(&func3);
}
our @EXPORT_OK;

sub list_filter_re_arr(\@%) {
	my $a = shift; #Array
	my %f = @_;    #Filter
	my @r = keys %f;
	#print "".join("\n\n", @r),"\n";
	for my $x (@$a) {
		for my $r (@r) {
			if ($x =~ $r) {
				my $to = $f{$r};
				my $ref = ref $to;
				if ($ref eq "ARRAY") {
					push(@$to, [ $x, @{^CAPTURE} ]);
				} elsif ($ref eq "CODE") {
					$to->($x, $r);
				}
			}
		}
	}
}

sub list_filter_re(\@%) {
	my $a = shift; #Array
	my %f = @_;    #Filter
	my @r = keys %f;
	#print "".join("\n\n", @r),"\n";
	for my $x (@$a) {
		for my $r (@r) {
			if ($x =~ $r) {
				my $to = $f{$r};
				my $ref = ref $to;
				if ($ref eq "ARRAY") {
					push(@$to, $x);
				} elsif ($ref eq "CODE") {
					$to->($x, $r);
				}
			}
		}
	}
}

1;