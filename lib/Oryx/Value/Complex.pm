package Oryx::Value::Complex;

use YAML;

use base qw(Oryx::Value);

sub inflate {
    my ($self, $value) = @_;
    if (defined $value) {
	return YAML::Load($value);
    }
}

sub deflate {
    my ($self, $value) = @_;
    return YAML::Dump($value);
}

sub check_type {
    my ($self, $value) = @_;
    return 1;
}

1;
