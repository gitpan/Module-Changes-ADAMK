package Module::Changes::ADAMK::Release;

use 5.005;
use strict;
use Carp                        ();
use DateTime                    ();
use DateTime::Format::DateParse (); 

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

use Module::Changes::ADAMK::Change ();

use Object::Tiny qw{
	string
	version
	date
	datetime
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { string => shift }, $class;

	# Get the paragraph strings
	my @lines  = split /\n/, $self->{string};

	# Find the header substrings
	my $header = shift @lines;
	unless ( $header =~ /^([\d_\.]+)(?:\s+(.+?\d{4}))?/ ) {
		Carp::croak('Failed to find version for release');
	}
	$self->{version} = $1;
	$self->{date}    = $2;

	# Inflate the DateTime
	if ( $self->{date} ) {
		$self->{datetime} = DateTime::Format::DateParse->parse_datetime($self->{date});
		$self->{datetime}->truncate( to => 'day' );
		$self->{datetime}->set_time_zone('floating');
		$self->{datetime}->set_locale('C');
	}

	# Split up the changes
	my @current = ();
	my @changes = ();
	while ( @lines ) {
		my $line = shift @lines;
		if ( $line =~ /^\s*-/ and @current ) {
			push @changes, [ @current ];
			@current = ();
		}
		push @current, $line;
	}
	push @changes, [ @current ] if @current;

	# Convert to change objects
	$self->{changes} = [ ];
	foreach my $change ( @changes ) {
		my $string = join "\n", @$change;
		my $object = Module::Changes::ADAMK::Change->new($string);
		push @{$self->{changes}}, $object;
	}

	return $self;
}

sub changes {
	@{$_[0]->{changes}};
}

1;
