package BE::GenRE;
use strict;
use utf8;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 0.01;

	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		ListToRE
	);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = (); #qw(&func3);
}
our @EXPORT_OK;

sub ListToRE_recursive($@){
	my $quote=shift;
	if(!@_){return "(?!x)x";}
	my @A=@_;
	my $re="";
	my $hasempty=0;
	
	if(grep($_ eq '',@A)){
		if(@A==2){
			my $s="$A[0]$A[1]";
			if(length($s)==1){return "\Q$s\E?"}
			else{return "(?:\Q$s\E)?"}
		}
		@A=grep($_ ne '',@A);
		$hasempty=1;
	}
	
	my $atom=1;
	if((my @B=grep(/^.$/,@A))>1){
		my $s=join('',@B);
		$s=~s/(.)\1+/$1/g;
		$s=~s/(\W)/"\\x".unpack('H2',$1)/ge;
		$re.="|[$s]";
		if($hasempty){$re.="?"}
		@A=grep(!/^.$/,@A);
		if(!@A){return substr($re,1)}
		$atom=0;
	}elsif($hasempty){
		$re="|";
		$atom=0;
	}
	
	while(@A){
#		print "<",join(',',@A),"> ($re)\n";
		my $s=$A[0];
		if(@A==1){
			$re.="|\Q$s\E";
			last;
		}
		
		my $l=1;
		my $c=substr($s,0,1);
		my @n=grep(/^\Q$c\E/,@A);
		if(@n>1){
			for(my $i=2;$i<length($s);$i++){
				my $cc=substr($s,0,$i);
				my @nn=grep(/^\Q$cc\E/,@A);
				if(scalar @nn<scalar @n){last}
				$c=$cc;$l=$i;
			}
			@A=grep(!/^\Q$c\E/,@A);
			map(s/^\Q$c\E//,@n);
			$re.="|\Q$c\E".ListToRE_recursive($quote+1,@n);
			if(@A){$re.="\n".(" " x $quote)}
#			print "$l#".join(',',@n)."#$c\n";
		}else{ #$n=1
			$re.="|\Q$s\E\n".(' ' x $quote);
			shift(@A);
		}
		if(@A){$atom=0}
	}
	if($re eq ""){return "#err#"}
	if($quote && !$atom){return "(?:".substr($re,1).")"}
	return substr($re,1);
}

sub ListToRE(@) {
	my $s = "(?x:".ListToRE_recursive(0, @_).")";
	return qr/$s/;
}

1;
