package Oryx::Value::Boolean;
use base qw(Oryx::Value);

sub check_type {
    my ($self, $value) = @_;
    return 1 if ($value =~ /^[01]$/);
}

sub inflate {
    my ($self, $value) = @_;
    return +$value;
}

sub deflate {
    my ($self, $value) = @_;
    return +$value;
}

1;
