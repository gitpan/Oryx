package Oryx::Value::DateTime;

use base qw(Oryx::Value);
use Class::Date qw(:errors date);

sub check_type {
    my ($self, $value) = @_;
    my $date = date($value);
    if ($date->error == E_INVALID) {
	return 0;
    }
    return 1;
}

sub inflate {
    my ($self, $value) = @_;
    return date($value);
}

sub deflate {
    my ($self, $value) = @_;
    return date($value)->string;
}

1;
