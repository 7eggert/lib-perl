#!/usr/bin/perl -C255
use strict;
use warnings;
use File::stat;
use LWP::UserAgent ();
use HTML::TreeBuilder 5 -weak;
use utf8;

use Data::Dumper;

$::DEBUG = 0;
$::langfile = "List_of_ISO_639-2_codes.html";
$::langurl  = "https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes";
$::perldata = "../lib-perl/BE/ISO936.pm";

@::expected_headers = (qw(639-2[1] 639-3[2] 639-5[3] 639-1), "Language name(s) from ISO 639-2[1]", qw(Scope Type), "Native name(s)", "Other name(s)");
@::my_headers = (qw(ISO639_2 ISO639_2b ISO639_3 ISO639_5 ISO639_1 Names_eng Scope Type Names_Native Names_Other));
$::x639_2TB = "ISO639_2TB";

$::UA = LWP::UserAgent->new;
$::UA->show_progress( 1 );





sub main() {
	my $ret;
	my $oldstat = stat($::langfile);
	# skip spamming Wikipedia if DEBUG
	$ret = $::UA->mirror($::langurl, $::langfile) unless $::DEBUG && -e $::langfile;
	my $newstat = stat($::langfile);
	my $plfilestat;

	if (!defined $newstat) {
		print "$::langfile isn't there";
		return 1;
	}
	$plfilestat = stat($::perldata);
	if (defined $oldstat
	&&  $newstat->mtime == $oldstat->mtime) {
		if (!(defined $plfilestat)) {
			print "generating new file $::perldata from cached content in $::langfile\n";
		} elsif ($plfilestat->mtime < $newstat->mtime) {
			print "re-generating stale file $::perldata from cached content in $::langfile\n";
		} elsif ($::DEBUG) {
			$::perldata .= ".debug";
			print "Debugging, file is up to date, generating $::perldata instead\n";
			
		} else {
			print "$::perldata is up to date\n";
			return 0;
		}
	} else {
		if (!(defined $plfilestat)) {
			print "generating new file $::perldata from new content in $::langfile\n";
		} else {
			print "re-generating stale file $::perldata from new content in $::langfile\n";
		}
	}

	my $tree = HTML::TreeBuilder->new;
	$tree->p_strict(1);
	$tree->parse_file($::langfile);
	
	my @table = $tree->look_down(id => "iso-codes");
	if (1*@table != 1) {
		print("found " . (1*@table) . " #iso-codes tables, aborting\n");
		return(2);
	}
	my @rows = $tree->look_down("_tag" => "tr");
	{
		#Headers
		my @columns = $rows[0]->content_list;
		if (1*@columns != 1*@::expected_headers) {
			print("expected " . 1*@::expected_headers . " headers but found " . 1*@columns . "\n");
			return(2);
		}
		for (my $j=0; $j < @columns; ++$j) {
			my $t = $columns[$j]->as_text();
			$t =~ s/\s+$//;
			if ($t ne $::expected_headers[$j]) {
				print "column $j is labeled ".$columns[$j]->as_text().", but expected was ". $::expected_headers[$j] . "\n";
				return(2);
			}
		}
	}
	my @entries;
	my %strings;
	#for (my $i=1; $i < @rows; ++$i) {
	
	my $tmv = sub($$) {
		my ($i, $j) = @_;
		print "Row $i field $j (".$::expected_headers[$j].") contains more values than expected\n";
		return(2);
	};
	
	for (my $i=1; $i < @rows; ++$i) {
		my $x = {};
		my @columns = $rows[$i]->content_list;
		next if(@columns != 9); # skip technical rows

		my @codes;
		# 639-2[T] 639-2B
		@codes = $columns[0]->look_down("_tag" => "code");
		if (@codes) { $x->{$::my_headers[0]} = $codes[0]->as_text(); };
		if (@codes > 1) { $x->{$::my_headers[1]} = $codes[1]->as_text(); };
		if (@codes > 2) {
			return($tmv->($i,0));
		}
		# 639-3
		@codes = $columns[1]->look_down("_tag" => "code");
		if (@codes) { $x->{$::my_headers[2]} = $codes[0]->as_text(); };
		if (@codes > 1) {
			return($tmv->($i,1));
		}
		# 639-5
		@codes = $columns[2]->look_down("_tag" => "code");
		if (@codes) { $x->{$::my_headers[3]} = $codes[0]->as_text(); };
		if (@codes > 1) {
			return($tmv->($i,2));
		}
		# 639-1
		@codes = $columns[3]->look_down("_tag" => "code");
		if (@codes) { $x->{$::my_headers[4]} = $codes[0]->as_text(); };
		if (@codes > 1) {
			return($tmv->($i,3));
		}
		# Names_eng
		#$x->{$::my_headers[5]} = $columns[4]->as_text();
		$x->{$::my_headers[5]} = [ split(/[;]\s+/, $columns[4]->as_text())];
		# Scope
		my $t = $columns[5]->as_text();
		$strings{$t} = $t if !defined $strings{$t}; # deduplicate
		$x->{$::my_headers[6]} = $strings{$t};
		# Type
		$t = $columns[6]->as_text();
		$strings{$t} = $t if !defined $strings{$t}; # deduplicate
		$x->{$::my_headers[7]} = $strings{$t};
		# Names_Native
		$x->{$::my_headers[8]} = [ split(/[,;]\s+/, $columns[7]->as_text())];
		# Names_Other
		$x->{$::my_headers[9]} = [ split(/[,;]\s+/, $columns[8]->as_text())];

		push(@entries, $x);
	}
	
	my $lookups = {
		$::my_headers[0] => {},# 639-2[T]
		$::my_headers[1] => {},# 639-2B
		$::x639_2TB => {},     # combined
		$::my_headers[2] => {},# 639-3
		$::my_headers[3] => {},# 639-5
		$::my_headers[4] => {},# 639-1
		$::my_headers[5] => {},# Names_eng
		$::my_headers[8] => {},# Names_Native
		$::my_headers[9] => {},# Names_Other
		$::x639_2TB => {},
		
	};
	for (my $i = 0; $i < @entries; ++$i) {
		my $e = $entries[$i];
		if (defined $e->{$::my_headers[0]} ) {
			$lookups->{$::my_headers[0]}{ $e->{$::my_headers[0]} } = $e;
			$lookups->{$::x639_2TB     }{ $e->{$::my_headers[0]} } = $e;
		}
		if (defined $e->{$::my_headers[1]} ) {
			$lookups->{$::my_headers[1]}{ $e->{$::my_headers[1]} } = $e;
			$lookups->{$::x639_2TB     }{ $e->{$::my_headers[1]} } = $e;
		}
		for (my $j = 2; $j <= 4; ++$j) {
			$lookups->{$::my_headers[$j]}{ $e->{$::my_headers[$j]} } = $e
				if defined $e->{$::my_headers[$j]};
		}
		
		# Don't put in names for "special" languages
		next if $e->{Type} eq "Special";
		for my $j (5, 8, 9) {
			my $a = $e->{$::my_headers[$j]};
			for (my $k = 0;  $k < @$a; ++$k) {
				$lookups->{$::my_headers[$j]}{ $e->{$::my_headers[$j]}[$k] } = $e;
			}
		}
	}
	$lookups->{all_entries} = \@entries;
	my $fd;
	open($fd, '>', $::perldata.".new") || die "open($::perldata.new) $!";
	local $Data::Dumper::Purity = 1;
	print $fd $::Package_header,
		Data::Dumper->Dump([$lookups], ["lookup"]), "\n1;\n" || die  "$!";
	close($fd) || die;
	rename($::perldata.".new", $::perldata);
}

exit(main());


BEGIN {

$::Package_header = <<EOF
package BE::ISO936;
use warnings;
use strict;
use utf8;

BEGIN {
        use Exporter   ();
        our (\$VERSION, \@ISA, \@EXPORT, \@EXPORT_OK, \%EXPORT_TAGS);

        # set the version for version checking
        \$VERSION     = 0.02;

        \@ISA         = qw(Exporter);
        \@EXPORT      = qw(
                lookup
        );
        \%EXPORT_TAGS = qw(
        );;     # eg: TAG => [ qw!name1 name2! ],

        # your exported package globals go here,
        # as well as any optionally exported functions
        \@EXPORT_OK   = qw(
        ); #qw(&func3);
}
our \@EXPORT_OK;

# exported package globals go here
#our \%Hashit;

# non-exported package globals go here
our \@TLTLD;

# initialize package globals, first exported ones
#\$Var1   = '';
#\%Hashit = ();

# then the others (which are still accessible as \$Some::Module::stuff)
\@TLTLD=();

# file-private lexicals go here
#my \$priv_var    = '';
#my \%secret_hash = ();

our
EOF

} # BEGIN
