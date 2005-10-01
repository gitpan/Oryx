package Oryx::DBI::Util;
use Carp qw(carp croak);

sub _carp {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$class] $_[1]");
}

sub _croak {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$class] $_[1]");
}

1;
